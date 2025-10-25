require 'json'
require 'fileutils'

class JsonDatabase
  class << self
    attr_accessor :db_path
    
    def initialize!
      self.db_path = Rails.root.join('db', 'db.json')
      ensure_db_exists
    end
    
    def ensure_db_exists
      return if File.exist?(db_path)
      
      FileUtils.mkdir_p(File.dirname(db_path))
      write_data(default_structure)
    end
    
    def default_structure
      {
        'users' => [],
        'sessions' => [],
        'chats' => [],
        'messages' => [],
        'administrators' => [],
        'admin_oplogs' => [],
        'active_storage_blobs' => [],
        'active_storage_attachments' => [],
        'counters' => {
          'users' => 0,
          'sessions' => 0,
          'chats' => 0,
          'messages' => 0,
          'administrators' => 0,
          'admin_oplogs' => 0,
          'active_storage_blobs' => 0,
          'active_storage_attachments' => 0
        }
      }
    end
    
    def read_data
      return default_structure unless File.exist?(db_path)
      
      begin
        JSON.parse(File.read(db_path))
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parse error in db.json: #{e.message}"
        default_structure
      end
    end
    
    def write_data(data)
      File.open(db_path, 'w') do |f|
        f.write(JSON.pretty_generate(data))
      end
    end
    
    # Thread-safe operations with file locking
    def transaction
      File.open(db_path, File::RDWR | File::CREAT, 0644) do |file|
        file.flock(File::LOCK_EX)
        
        data = begin
          JSON.parse(file.read)
        rescue JSON::ParserError
          default_structure
        end
        
        result = yield(data)
        
        file.rewind
        file.truncate(0)
        file.write(JSON.pretty_generate(data))
        
        result
      end
    end
    
    # Get all records from a table
    def all(table_name)
      data = read_data
      data[table_name.to_s] || []
    end
    
    # Find record by id
    def find(table_name, id)
      all(table_name).find { |record| record['id'] == id.to_i }
    end
    
    # Find record by condition
    def find_by(table_name, conditions = {})
      all(table_name).find do |record|
        conditions.all? { |key, value| record[key.to_s] == value }
      end
    end
    
    # Find all records by condition
    def where(table_name, conditions = {})
      all(table_name).select do |record|
        conditions.all? { |key, value| record[key.to_s] == value }
      end
    end
    
    # Create a new record
    def create(table_name, attributes)
      transaction do |data|
        data[table_name.to_s] ||= []
        data['counters'] ||= {}
        data['counters'][table_name.to_s] ||= 0
        
        # Increment counter and assign id
        data['counters'][table_name.to_s] += 1
        new_id = data['counters'][table_name.to_s]
        
        record = attributes.merge('id' => new_id)
        
        # Add timestamps
        now = Time.current.iso8601
        record['created_at'] ||= now
        record['updated_at'] ||= now
        
        data[table_name.to_s] << record
        record
      end
    end
    
    # Update a record
    def update(table_name, id, attributes)
      transaction do |data|
        records = data[table_name.to_s] || []
        index = records.find_index { |r| r['id'] == id.to_i }
        
        return nil unless index
        
        # Update attributes and timestamp
        records[index].merge!(attributes.stringify_keys)
        records[index]['updated_at'] = Time.current.iso8601
        
        records[index]
      end
    end
    
    # Delete a record
    def delete(table_name, id)
      transaction do |data|
        records = data[table_name.to_s] || []
        deleted = records.reject! { |r| r['id'] == id.to_i }
        !deleted.nil?
      end
    end
    
    # Delete all records matching condition
    def delete_all(table_name, conditions = {})
      transaction do |data|
        records = data[table_name.to_s] || []
        
        if conditions.empty?
          count = records.size
          data[table_name.to_s] = []
          count
        else
          initial_count = records.size
          records.reject! do |record|
            conditions.all? { |key, value| record[key.to_s] == value }
          end
          initial_count - records.size
        end
      end
    end
    
    # Count records
    def count(table_name, conditions = {})
      if conditions.empty?
        all(table_name).size
      else
        where(table_name, conditions).size
      end
    end
    
    # Check if record exists
    def exists?(table_name, conditions = {})
      !find_by(table_name, conditions).nil?
    end
    
    # Reset database to default structure
    def reset!
      write_data(default_structure)
    end
  end
end
