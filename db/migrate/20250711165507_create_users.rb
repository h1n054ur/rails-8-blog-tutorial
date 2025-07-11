# USER TABLE MIGRATION - Creates the users table for authentication system
#
# RAILS CONCEPT: Migrations are version-controlled database schema changes.
# They allow teams to modify database structure incrementally and safely.
#
# NAMING CONVENTION: Rails automatically generates migration names based on:
# - Timestamp prefix (20250711165507) ensures chronological ordering
# - Descriptive name (CreateUsers) explains what the migration does
#
# ACTIVERECORD MIGRATION: Inherits from ActiveRecord::Migration[8.0]
# The version number (8.0) ensures compatibility with Rails 8 migration features

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    # CREATE_TABLE: Defines a new database table structure
    # 
    # DESIGN DECISIONS for users table:
    # - Simple authentication system for tutorial purposes
    # - Email-based login (no separate username field)
    # - Admin boolean for role-based access control
    # - Rails timestamp columns for audit trail
    create_table :users do |t|
      # EMAIL FIELD: Primary identifier for user login
      # 
      # FIELD DESIGN:
      # - string type: Variable length text (up to 255 characters by default)
      # - null: false: Database constraint prevents empty emails
      # - index: { unique: true }: Ensures no duplicate emails + fast lookups
      #
      # WHY NOT NULL: Email is required for login, so it must always exist
      # WHY UNIQUE: Only one account per email address (standard practice)
      # WHY INDEX: Email lookups during login need to be fast
      t.string :email, null: false, index: { unique: true }
      
      # PASSWORD_DIGEST FIELD: Encrypted password storage
      #
      # SECURITY EXPLANATION:
      # - We NEVER store plain text passwords in the database
      # - password_digest stores the hashed/encrypted version
      # - Rails has_secure_password uses bcrypt for secure hashing
      # - null: false: Every user must have a password
      #
      # NAMING CONVENTION: Rails expects 'password_digest' for has_secure_password
      t.string :password_digest, null: false
      
      # ADMIN FIELD: Simple role-based access control
      #
      # DESIGN CHOICE:
      # - boolean type: true/false for admin status
      # - default: false: New users are not admins by default
      # - This is simpler than complex role systems for tutorial purposes
      #
      # FUTURE ENHANCEMENT: Could be expanded to enum or separate roles table
      t.boolean :admin, default: false, null: false
      
      # TIMESTAMPS: Rails convention for tracking record lifecycle
      #
      # AUTOMATIC FIELDS: Rails creates these columns automatically:
      # - created_at: When the record was first saved
      # - updated_at: When the record was last modified
      #
      # RAILS MAGIC: ActiveRecord automatically manages these timestamps
      # WHY IMPORTANT: Audit trail, debugging, and application logic often need these
      t.timestamps
    end
    
    # PERFORMANCE OPTIMIZATION: Additional indexes for common queries
    #
    # EMAIL INDEX: Already created above with unique constraint
    # We could add more indexes here for other common query patterns:
    # add_index :users, :admin  # If we often query for admin users
    # add_index :users, :created_at  # If we often sort by creation date
  end
  
  # MIGRATION REVERSIBILITY:
  # 
  # Rails can automatically reverse this migration because:
  # - create_table can be reversed with drop_table
  # - All operations here are automatically reversible
  #
  # IF WE NEEDED CUSTOM REVERSIBILITY:
  # def up
  #   create_table :users do |t|
  #     # table definition
  #   end
  # end
  #
  # def down
  #   drop_table :users
  # end
end

# WHAT THIS MIGRATION ACCOMPLISHES:
#
# 1. DATABASE TABLE: Creates 'users' table with proper constraints
# 2. SECURITY FOUNDATION: Sets up secure password storage
# 3. ACCESS CONTROL: Provides admin role management
# 4. PERFORMANCE: Includes indexes for efficient queries
# 5. AUDIT TRAIL: Timestamps for tracking user lifecycle
#
# WHY THIS DESIGN:
#
# - SIMPLICITY: Easy to understand for Rails beginners
# - SECURITY: Follows Rails authentication best practices
# - SCALABILITY: Can be extended with additional fields later
# - STANDARDS: Uses Rails conventions for predictable behavior
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - Migration file structure and naming
# - Database constraint definition (null: false)
# - Index creation for performance and uniqueness
# - Default values for database fields
# - Rails timestamp automation
# - Migration reversibility patterns
#
# BEGINNER LEARNING POINTS:
#
# - Migrations change database structure incrementally
# - Constraints enforce data integrity at database level
# - Indexes improve query performance significantly
# - Rails conventions reduce configuration complexity
# - Security considerations start at database design level
