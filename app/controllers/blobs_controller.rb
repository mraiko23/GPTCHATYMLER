class BlobsController < ApplicationController
  skip_before_action :authenticate, only: [:show]
  
  def show
    key = params[:key]
    filename = params[:filename]
    
    blob_data = JsonDatabase.find_by('active_storage_blobs', { 'key' => key })
    
    if blob_data
      file_path = Rails.root.join('storage', key)
      
      if File.exist?(file_path)
        send_file file_path,
                  filename: blob_data['filename'],
                  type: blob_data['content_type'] || 'application/octet-stream',
                  disposition: 'inline'
      else
        head :not_found
      end
    else
      head :not_found
    end
  end
end
