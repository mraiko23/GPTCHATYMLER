namespace :db do
  desc "Cleanup orphaned attachments without record_id"
  task cleanup_attachments: :environment do
    puts "Starting cleanup of orphaned attachments..."
    
    # Get all attachments without record_id
    orphaned_attachments = JsonDatabase.where('active_storage_attachments', { 'record_id' => nil })
    
    puts "Found #{orphaned_attachments.count} orphaned attachments"
    
    orphaned_attachments.each do |attachment|
      # Get blob
      blob = JsonDatabase.find('active_storage_blobs', attachment['blob_id'])
      
      if blob
        # Delete physical file
        file_path = Rails.root.join('storage', blob['key'])
        if File.exist?(file_path)
          File.delete(file_path)
          puts "Deleted file: #{blob['filename']}"
        end
        
        # Delete blob from database
        JsonDatabase.delete('active_storage_blobs', blob['id'])
      end
      
      # Delete attachment from database
      JsonDatabase.delete('active_storage_attachments', attachment['id'])
    end
    
    puts "Cleanup completed!"
  end
end
