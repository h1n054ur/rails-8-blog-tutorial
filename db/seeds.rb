# RAILS 8 TUTORIAL BLOG - DATABASE SEEDS
#
# PURPOSE: This file creates essential data needed for the application to function.
# Seeds ensure the application has required records in every environment.
#
# IDEMPOTENT DESIGN: This code can be run multiple times safely without creating
# duplicate records. Uses find_or_create_by for safe record creation.
#
# USAGE: Run with `rails db:seed` or automatically with `rails db:setup`
#
# RAILS CONCEPT: Seeding populates the database with initial data that the
# application needs to function properly.

puts "🌱 Seeding Rails 8 Tutorial Blog database..."

# ADMIN USER CREATION - Essential for accessing admin panel
#
# DEVELOPMENT NOTE: In production, you would create admin users through
# a secure process, not with hardcoded credentials in seeds.
#
# SECURITY CONSIDERATION: Using simple credentials for tutorial purposes.
# In production, use strong passwords and environment variables.

admin_user = User.find_or_create_by(email: 'admin@example.com') do |user|
  # TUTORIAL CREDENTIALS: Simple for educational purposes
  # PRODUCTION WARNING: Never use these credentials in real applications
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.admin = true
  
  puts "  📧 Creating admin user with email: #{user.email}"
end

# SEED RESULT FEEDBACK
if admin_user.persisted?
  puts "  ✅ Admin user ready: #{admin_user.email}"
  puts "  🔑 Password: password123 (for tutorial purposes)"
  puts "  🛡️  Admin status: #{admin_user.admin?}"
else
  puts "  ❌ Failed to create admin user:"
  admin_user.errors.full_messages.each do |error|
    puts "     - #{error}"
  end
end

# FUTURE SEEDS: Additional data for the tutorial blog
#
# As we develop the application, we might add:
# - Sample blog posts for demonstration
# - Categories or tags for organizing content
# - Sample comments for testing
#
# Example for future phases:
# if admin_user.persisted?
#   sample_post = Post.find_or_create_by(title: 'Welcome to Rails 8') do |post|
#     post.content = 'This is a sample blog post...'
#     post.user = admin_user
#     post.published = true
#   end
# end

puts "🚀 Database seeding completed!"

# WHAT THIS SEEDS FILE ACCOMPLISHES:
#
# 1. ADMIN ACCESS: Creates the admin user needed for accessing admin panel
# 2. DEVELOPMENT CONVENIENCE: Provides known credentials for testing
# 3. IDEMPOTENT OPERATION: Can be run multiple times safely
# 4. ERROR REPORTING: Shows clear feedback about seed operation results
# 5. FUTURE PREPARATION: Structure ready for additional seed data
#
# WHY THIS APPROACH:
#
# - FIND_OR_CREATE_BY: Prevents duplicate records on multiple runs
# - BLOCK SYNTAX: Only sets attributes if record is being created
# - ERROR HANDLING: Provides feedback if seeding fails
# - DOCUMENTATION: Clear explanation of purpose and security considerations
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - Database seeding best practices
# - Idempotent data operations
# - User model instantiation and validation
# - Error handling and user feedback
# - Development vs production security considerations
#
# BEGINNER LEARNING POINTS:
#
# - Seeds provide essential application data
# - find_or_create_by prevents duplicate records
# - Development credentials should never be used in production
# - Seed files should include clear documentation and error handling
# - Rails applications need initial data to be fully functional
