require 'fileutils'
require 'digest'
require 'base64'

# Simple file storage implementation for JSON database
class JsonActiveStorage
  class Blob
    attr_reader :id, :key, :filename, :content_type, :byte_size, :checksum, :created_at
    
    def initialize(attributes)
      attributes = attributes.stringify_keys
      @id = attributes['id']
      @key = attributes['key']
      @filename = attributes['filename']
      @content_type = attributes['content_type']
      @byte_size = attributes['byte_size']
      @checksum = attributes['checksum']
      @created_at = attributes['created_at']
    end
    
    def self.create_and_upload!(io:, filename:, content_type: nil)
      key = SecureRandom.uuid
      storage_path = Rails.root.join('storage', key)
      FileUtils.mkdir_p(File.dirname(storage_path))
      
      # Write file
      File.open(storage_path, 'wb') do |f|
        if io.respond_to?(:read)
          f.write(io.read)
        else
          f.write(io)
        end
      end
      
      byte_size = File.size(storage_path)
      checksum = Digest::MD5.file(storage_path).base64digest
      
      blob_data = JsonDatabase.create('active_storage_blobs', {
        'key' => key,
        'filename' => filename.to_s,
        'content_type' => content_type || 'application/octet-stream',
        'metadata' => {},
        'service_name' => 'local',
        'byte_size' => byte_size,
        'checksum' => checksum
      })
      
      new(blob_data)
    end
    
    def url
      "/rails/active_storage/blobs/#{key}/#{filename}"
    end
    
    def download
      File.read(storage_path)
    end
    
    def storage_path
      Rails.root.join('storage', key)
    end
    
    def image?
      content_type.to_s.start_with?('image/')
    end
    
    def text?
      content_type.to_s.start_with?('text/')
    end
  end
  
  class Attachment
    attr_reader :id, :name, :record_type, :record_id, :blob_id, :created_at
    
    def initialize(attributes)
      attributes = attributes.stringify_keys
      @id = attributes['id']
      @name = attributes['name']
      @record_type = attributes['record_type']
      @record_id = attributes['record_id']
      @blob_id = attributes['blob_id']
      @created_at = attributes['created_at']
    end
    
    def blob
      blob_data = JsonDatabase.find('active_storage_blobs', blob_id)
      blob_data ? Blob.new(blob_data) : nil
    end
    
    def purge
      blob_obj = blob
      if blob_obj
        # Delete file
        File.delete(blob_obj.storage_path) if File.exist?(blob_obj.storage_path)
        # Delete blob record
        JsonDatabase.delete('active_storage_blobs', blob_id)
      end
      # Delete attachment record
      JsonDatabase.delete('active_storage_attachments', id)
    end
  end
  
  # Controller for serving files
  class BlobsController < ApplicationController
    def show
      key = params[:key]
      filename = params[:filename]
      
      blob_data = JsonDatabase.find_by('active_storage_blobs', { 'key' => key })
      
      if blob_data
        blob = Blob.new(blob_data)
        file_path = blob.storage_path
        
        if File.exist?(file_path)
          send_file file_path,
                    filename: blob.filename,
                    type: blob.content_type,
                    disposition: 'inline'
        else
          head :not_found
        end
      else
        head :not_found
      end
    end
  end
end
