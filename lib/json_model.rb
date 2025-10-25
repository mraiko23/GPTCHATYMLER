require_relative 'json_database'

# Custom exceptions for JsonModel
class JsonModelError < StandardError; end
class RecordNotFound < JsonModelError; end
class RecordInvalid < JsonModelError
  attr_reader :record
  
  def initialize(record = nil)
    @record = record
    super()
  end
end

class JsonModel
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations
  include ActiveModel::Callbacks
  
  define_model_callbacks :save, :create, :update, :destroy, :validation
  
  attr_accessor :id, :created_at, :updated_at
  
  class_attribute :table_name_value
  class_attribute :has_many_relations, default: {}
  class_attribute :belongs_to_relations, default: {}
  class_attribute :has_many_attached_files, default: []
  
  def initialize(attributes = {})
    attributes = attributes.stringify_keys
    @id = attributes['id']
    @created_at = parse_time(attributes['created_at'])
    @updated_at = parse_time(attributes['updated_at'])
    @new_record = attributes['id'].nil?
    @destroyed = false
    
    super(attributes.except('id', 'created_at', 'updated_at'))
  end
  
  def new_record?
    @new_record
  end
  
  def persisted?
    !new_record? && !destroyed?
  end
  
  def destroyed?
    @destroyed
  end
  
  # Class methods
  class << self
    def table_name(name = nil)
      if name
        self.table_name_value = name.to_s
      else
        self.table_name_value || self.name.underscore.pluralize
      end
    end
    
    def all
      records = JsonDatabase.all(table_name)
      records.map { |r| new(r) }
    end
    
    def count
      JsonDatabase.count(table_name)
    end
    
    def find(id)
      record = JsonDatabase.find(table_name, id)
      raise RecordNotFound, "Couldn't find #{name} with 'id'=#{id}" unless record
      new(record)
    end
    
    def find_by(conditions)
      record = JsonDatabase.find_by(table_name, conditions)
      record ? new(record) : nil
    end
    
    def where(conditions)
      records = JsonDatabase.where(table_name, conditions)
      records.map { |r| new(r) }
    end
    
    def create(attributes = {})
      record = new(attributes)
      record.save
      record
    end
    
    def create!(attributes = {})
      record = new(attributes)
      record.save!
      record
    end
    
    def destroy_all
      JsonDatabase.delete_all(table_name)
    end
    
    # Define associations
    def has_many(name, options = {})
      self.has_many_relations = has_many_relations.merge(name.to_s => options)
      
      define_method(name) do
        foreign_key = options[:foreign_key] || "#{self.class.name.underscore}_id"
        class_name = options[:class_name] || name.to_s.classify
        klass = class_name.constantize
        
        klass.where(foreign_key => id)
      end
    end
    
    def belongs_to(name, options = {})
      foreign_key = options[:foreign_key] || "#{name}_id"
      self.belongs_to_relations = belongs_to_relations.merge(name.to_s => options)
      
      attribute foreign_key.to_sym
      
      define_method(name) do
        class_name = options[:class_name] || name.to_s.classify
        klass = class_name.constantize
        foreign_id = send(foreign_key)
        
        klass.find_by(id: foreign_id) if foreign_id
      end
      
      define_method("#{name}=") do |associated_object|
        if associated_object
          send("#{foreign_key}=", associated_object.id)
        else
          send("#{foreign_key}=", nil)
        end
      end
    end
    
    def has_many_attached(name)
      self.has_many_attached_files = has_many_attached_files + [name.to_s]
      
      define_method(name) do
        JsonAttachmentProxy.new(self, name.to_s)
      end
    end
    
    # Scopes
    def scope(name, body)
      define_singleton_method(name) do |*args|
        all.select { |record| body.call(record, *args) }
      end
    end
  end
  
  # Instance methods
  def save
    return false unless valid?
    
    run_callbacks :save do
      if new_record?
        run_callbacks :create do
          perform_create
        end
      else
        run_callbacks :update do
          perform_update
        end
      end
    end
    
    true
  rescue => e
    Rails.logger.error "Save failed: #{e.message}"
    false
  end
  
  def save!
    unless save
      error_msg = errors.full_messages.join(', ')
      raise RecordInvalid.new(self), "Validation failed: #{error_msg}"
    end
    self
  end
  
  def update(attributes)
    assign_attributes(attributes)
    save
  end
  
  def update!(attributes)
    assign_attributes(attributes)
    save!
  end
  
  def destroy
    return false if destroyed?
    
    run_callbacks :destroy do
      # Delete associated has_many records with dependent: :destroy
      self.class.has_many_relations.each do |name, options|
        next unless options[:dependent] == :destroy
        
        send(name).each(&:destroy)
      end
      
      # Delete attachments
      self.class.has_many_attached_files.each do |name|
        send(name).purge_all
      end
      
      JsonDatabase.delete(self.class.table_name, id)
      @destroyed = true
    end
    
    self
  end
  
  def reload
    raise RecordNotFound if destroyed?
    
    record = JsonDatabase.find(self.class.table_name, id)
    raise RecordNotFound unless record
    
    initialize(record)
    self
  end
  
  def attributes
    result = {}
    self.class.attribute_names.each do |attr|
      result[attr] = send(attr)
    end
    result.merge('id' => id, 'created_at' => created_at, 'updated_at' => updated_at)
  end
  
  def as_json(options = {})
    attributes
  end
  
  private
  
  def perform_create
    attrs = attributes.except('id', 'created_at', 'updated_at')
    record = JsonDatabase.create(self.class.table_name, attrs)
    
    @id = record['id']
    @created_at = parse_time(record['created_at'])
    @updated_at = parse_time(record['updated_at'])
    @new_record = false
  end
  
  def perform_update
    attrs = attributes.except('id', 'created_at', 'updated_at')
    record = JsonDatabase.update(self.class.table_name, id, attrs)
    
    @updated_at = parse_time(record['updated_at'])
  end
  
  def parse_time(value)
    case value
    when String
      Time.parse(value)
    when Time, DateTime, ActiveSupport::TimeWithZone
      value
    else
      value
    end
  end
end

# Proxy class for file attachments
class JsonAttachmentProxy
  def initialize(record, name)
    @record = record
    @name = name
  end
  
  def attached?
    attachments.any?
  end
  
  def attach(file)
    return unless file
    
    blob = create_blob(file)
    create_attachment(blob)
  end
  
  def attachments
    JsonDatabase.where('active_storage_attachments', {
      'record_type' => @record.class.name,
      'record_id' => @record.id,
      'name' => @name
    })
  end
  
  def blobs
    attachments.map do |attachment|
      JsonDatabase.find('active_storage_blobs', attachment['blob_id'])
    end.compact
  end
  
  def purge_all
    attachments.each do |attachment|
      # Delete blob file
      blob = JsonDatabase.find('active_storage_blobs', attachment['blob_id'])
      if blob && blob['key']
        file_path = Rails.root.join('storage', blob['key'])
        File.delete(file_path) if File.exist?(file_path)
      end
      
      # Delete from database
      JsonDatabase.delete('active_storage_blobs', attachment['blob_id'])
      JsonDatabase.delete('active_storage_attachments', attachment['id'])
    end
  end
  
  def each(&block)
    blobs.each(&block)
  end
  
  def map(&block)
    blobs.map(&block)
  end
  
  private
  
  def create_blob(file)
    key = SecureRandom.uuid
    
    # Save file to storage
    storage_path = Rails.root.join('storage', key)
    FileUtils.mkdir_p(File.dirname(storage_path))
    
    if file.respond_to?(:tempfile)
      FileUtils.cp(file.tempfile.path, storage_path)
      filename = file.original_filename
      content_type = file.content_type
      byte_size = file.tempfile.size
    else
      File.open(storage_path, 'wb') { |f| f.write(file.read) }
      filename = file.respond_to?(:original_filename) ? file.original_filename : 'file'
      content_type = file.respond_to?(:content_type) ? file.content_type : 'application/octet-stream'
      byte_size = File.size(storage_path)
    end
    
    JsonDatabase.create('active_storage_blobs', {
      'key' => key,
      'filename' => filename,
      'content_type' => content_type,
      'metadata' => {},
      'service_name' => 'local',
      'byte_size' => byte_size,
      'checksum' => Digest::MD5.file(storage_path).base64digest
    })
  end
  
  def create_attachment(blob)
    JsonDatabase.create('active_storage_attachments', {
      'name' => @name,
      'record_type' => @record.class.name,
      'record_id' => @record.id,
      'blob_id' => blob['id']
    })
  end
end
