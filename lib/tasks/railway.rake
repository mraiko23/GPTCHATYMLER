namespace :railway do
  desc "Initialize database on first Railway deployment"
  task initialize: :environment do
    db_file = Rails.root.join('db', 'db.json')
    
    if File.exist?(db_file)
      puts "Database already exists at #{db_file}"
      puts "Checking database integrity..."
      
      begin
        data = JSON.parse(File.read(db_file))
        puts "✓ Database file is valid JSON"
        puts "  - Users: #{data['users']&.count || 0}"
        puts "  - Chats: #{data['chats']&.count || 0}"
        puts "  - Messages: #{data['messages']&.count || 0}"
      rescue JSON::ParserError => e
        puts "✗ Database file is corrupted: #{e.message}"
        puts "Creating backup and reinitializing..."
        FileUtils.cp(db_file, "#{db_file}.backup.#{Time.now.to_i}")
        Rake::Task['db:seed'].invoke
      end
    else
      puts "Database not found. Initializing..."
      Rake::Task['db:seed'].invoke
      puts "✓ Database initialized successfully"
    end
    
    # Ensure storage directory exists
    storage_dir = Rails.root.join('storage')
    FileUtils.mkdir_p(storage_dir) unless Dir.exist?(storage_dir)
    puts "✓ Storage directory ready at #{storage_dir}"
    
    # Create .keep file to preserve directory in git
    keep_file = storage_dir.join('.keep')
    FileUtils.touch(keep_file) unless File.exist?(keep_file)
    
    puts "\n✓ Railway initialization complete!"
  end
  
  desc "Health check for Railway"
  task health: :environment do
    begin
      # Check database
      db_file = Rails.root.join('db', 'db.json')
      raise "Database file not found" unless File.exist?(db_file)
      
      # Check if we can read it
      JSON.parse(File.read(db_file))
      
      # Check if we can query it
      User.all
      
      puts "✓ Health check passed"
      exit 0
    rescue => e
      puts "✗ Health check failed: #{e.message}"
      exit 1
    end
  end
end
