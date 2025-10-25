# This file should contain all the record creation needed to seed the JSON database with its default values.
# The data can then be loaded with the bin/rails db:seed command

puts "Initializing JSON database..."

# Initialize the database structure
JsonDatabase.initialize!

puts "Database initialized with default structure"

# Create default administrator if none exists
if Administrator.count == 0
  puts "Creating default administrator..."
  
  admin = Administrator.create!(
    name: 'admin',
    password: 'admin123',
    password_confirmation: 'admin123',
    role: 'super_admin',
    first_login: true
  )
  
  puts "✓ Created super admin: #{admin.name} (password: admin123)"
  puts "  Please change this password after first login!"
else
  puts "Administrator already exists, skipping..."
end

puts "\n✓ Seeding completed!"
puts "\nDatabase location: #{JsonDatabase.db_path}"
puts "\nYou can now:"
puts "  1. Start the application: bin/dev"
puts "  2. Login to admin panel: /admin (username: admin, password: admin)"
puts "  3. Login with Telegram for user access"
