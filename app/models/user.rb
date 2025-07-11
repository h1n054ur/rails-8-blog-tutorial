# USER MODEL - Represents user accounts in our Rails 8 tutorial blog application
#
# RAILS CONCEPT: Models represent data and business logic in the MVC pattern.
# They inherit from ApplicationRecord (which inherits from ActiveRecord::Base)
# and provide an object-oriented interface to database tables.
#
# ACTIVERECORD ORM: This model corresponds to the 'users' database table.
# Rails automatically maps between the User class and users table using
# naming conventions (User → users, singular → plural).

class User < ApplicationRecord
  # SECURE PASSWORD HANDLING - Rails built-in authentication feature
  #
  # WHAT has_secure_password DOES:
  # 1. Adds password and password_confirmation attributes (virtual, not stored)
  # 2. Validates password presence and confirmation match
  # 3. Adds authenticate(password) method for login verification
  # 4. Automatically encrypts passwords using bcrypt before storing in password_digest
  #
  # SECURITY BENEFIT: Passwords are never stored in plain text
  # RAILS MAGIC: Requires 'password_digest' column in database (which we have)
  #
  # BEGINNER NOTE: This is why our migration has 'password_digest', not 'password'
  has_secure_password
  
  # MODEL VALIDATIONS - Data integrity rules enforced by Rails
  #
  # These validations run before saving to database and ensure data quality.
  # They complement database constraints but provide better error messages.
  
  # EMAIL VALIDATION: Ensures valid email format and uniqueness
  #
  # VALIDATION RULES:
  # - presence: true: Email cannot be blank
  # - uniqueness: true: No duplicate emails allowed (one account per email)
  # - format: EMAIL_REGEXP: Must match valid email pattern
  #
  # WHY EMAIL VALIDATION: Email is our login identifier and must be valid
  # UNIQUENESS NOTE: Also enforced at database level for data integrity
  validates :email, presence: true, 
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP, 
                             message: "must be a valid email address" }
  
  # PASSWORD VALIDATION: Ensures strong passwords
  #
  # VALIDATION RULES:
  # - length: minimum 6 characters (has_secure_password adds presence validation)
  #
  # SECURITY CONSIDERATION: Minimum length prevents weak passwords
  # NOTE: has_secure_password already validates presence, so we only add length
  validates :password, length: { minimum: 6 }, if: :password_digest_changed?
  
  # EMAIL NORMALIZATION - Ensure consistent email storage
  #
  # CALLBACK: before_save runs automatically before saving to database
  # PURPOSE: Convert emails to consistent format (lowercase, trimmed)
  # BENEFIT: Prevents duplicate accounts with different email casing
  before_save :normalize_email
  
  # SCOPES - Convenient query methods for common user searches
  #
  # Scopes provide reusable query logic that can be chained with other queries
  
  # ADMIN SCOPE: Find all admin users
  # USAGE: User.admin or User.admin.recent
  scope :admin, -> { where(admin: true) }
  
  # RECENT SCOPE: Order users by creation date (newest first)
  # USAGE: User.recent or User.admin.recent
  scope :recent, -> { order(created_at: :desc) }
  
  # INSTANCE METHODS - Behavior specific to individual user objects
  
  # ADMIN CHECK: Convenient method to check admin status
  #
  # USAGE: user.admin? returns true/false
  # RAILS CONVENTION: Boolean attributes automatically get ? methods
  # This method is actually provided by Rails automatically, but documenting for clarity
  # def admin?
  #   admin
  # end
  
  # DISPLAY NAME: Human-readable identifier for the user
  #
  # PURPOSE: Provides a consistent way to display user identity
  # FALLBACK: Uses email if no other name fields exist
  # FUTURE ENHANCEMENT: Could add first_name/last_name fields later
  def display_name
    # For now, use email as display name
    # In future phases, could add name fields and use those instead
    email.split('@').first.capitalize
  end
  
  # CLASS METHODS - Behavior that operates on the User class as a whole
  
  # AUTHENTICATION FINDER: Secure user lookup for login
  #
  # PURPOSE: Find user by email for authentication attempts
  # SECURITY: Uses case-insensitive lookup to match our normalization
  # USAGE: User.find_by_email('admin@example.com')
  def self.find_by_email(email)
    find_by(email: email.downcase.strip)
  end
  
  private
  
  # EMAIL NORMALIZATION CALLBACK - Ensure consistent email storage
  #
  # PRIVATE METHOD: Only used internally by the model
  # PURPOSE: Convert emails to lowercase and remove whitespace
  # TIMING: Runs before every save operation
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end

# WHAT THIS MODEL ACCOMPLISHES:
#
# 1. AUTHENTICATION: Secure password handling with bcrypt encryption
# 2. VALIDATION: Ensures data integrity with presence and format checks
# 3. AUTHORIZATION: Admin flag for role-based access control
# 4. DATA CONSISTENCY: Email normalization for reliable lookups
# 5. CONVENIENCE: Scopes and methods for common operations
#
# WHY THIS DESIGN:
#
# - SECURITY FIRST: Uses Rails best practices for password handling
# - SIMPLICITY: Minimal fields needed for tutorial authentication
# - EXTENSIBILITY: Easy to add more fields and validations later
# - CONVENTIONS: Follows Rails naming and structure patterns
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - ActiveRecord model inheritance and conventions
# - has_secure_password for authentication
# - Model validations for data integrity
# - Callbacks for automatic data processing
# - Scopes for reusable query logic
# - Instance and class method definitions
#
# BEGINNER LEARNING POINTS:
#
# - Models handle business logic and data validation
# - Rails provides powerful authentication features out of the box
# - Validations ensure data quality before database storage
# - Callbacks allow automatic processing during record lifecycle
# - Scopes make complex queries reusable and chainable
# - Security considerations are built into model design
#
# AUTHENTICATION FLOW ENABLED:
#
# 1. User enters email/password in login form
# 2. Controller finds user with User.find_by_email(email)
# 3. Controller calls user.authenticate(password)
# 4. has_secure_password compares with stored password_digest
# 5. Authentication succeeds/fails based on password match
