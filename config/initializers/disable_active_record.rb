# Disable ActiveRecord since we're using JSON storage
module ActiveRecord
  class Base
    # Stub to prevent errors
  end
  
  class RecordNotFound < StandardError; end
  class RecordInvalid < StandardError
    attr_reader :record
    
    def initialize(record = nil)
      @record = record
      super(record ? "Validation failed: #{record.errors.full_messages.join(', ')}" : "Record invalid")
    end
  end
end unless defined?(ActiveRecord::Base)
