# Security (CSRF, CORS, Encryption)

## Overview

Rails provides comprehensive security features out of the box, including CSRF protection, SQL injection prevention, XSS protection, and secure encryption. Understanding and properly configuring these features is essential for building secure applications.

## CSRF Protection

### Cross-Site Request Forgery (CSRF) Basics
CSRF attacks trick users into performing unintended actions on applications where they're authenticated. Rails protects against this by requiring authenticity tokens.

### Enabling CSRF Protection
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # CSRF protection (enabled by default)
  protect_from_forgery with: :exception
  
  # Alternative strategies
  # protect_from_forgery with: :null_session  # Set session to nil on invalid token
  # protect_from_forgery with: :reset_session  # Reset entire session on invalid token
end
```

### CSRF Tokens in Forms
```erb
<!-- Rails automatically includes CSRF tokens in forms -->
<%= form_with model: @post do |form| %>
  <!-- This automatically includes: -->
  <!-- <input type="hidden" name="authenticity_token" value="..." /> -->
  <%= form.text_field :title %>
  <%= form.submit %>
<% end %>

<!-- Manual token inclusion -->
<form action="/posts" method="post">
  <%= csrf_meta_tags %>
  <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
  <!-- form fields -->
</form>

<!-- In layouts for AJAX requests -->
<head>
  <%= csrf_meta_tags %>
</head>
```

### CSRF for AJAX Requests
```javascript
// app/javascript/csrf.js
// Rails UJS automatically handles CSRF for AJAX requests
import Rails from "@rails/ujs"

// Manual CSRF token handling
function getCSRFToken() {
  return document.querySelector("meta[name='csrf-token']").getAttribute("content")
}

// Fetch API with CSRF token
fetch('/api/posts', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': getCSRFToken()
  },
  body: JSON.stringify({ post: { title: 'New Post' } })
})

// Axios configuration
axios.defaults.headers.common['X-CSRF-Token'] = getCSRFToken()
```

### API Endpoints and CSRF
```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ApplicationController
  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token
  
  # Use alternative authentication (tokens, API keys)
  before_action :authenticate_api_token
  
  private
  
  def authenticate_api_token
    api_key = request.headers['X-API-Key']
    @current_user = User.find_by(api_key: api_key)
    
    head :unauthorized unless @current_user
  end
end

# app/controllers/api/v1/posts_controller.rb
class Api::V1::PostsController < Api::BaseController
  def create
    @post = @current_user.posts.build(post_params)
    
    if @post.save
      render json: @post, status: :created
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end
  
  private
  
  def post_params
    params.require(:post).permit(:title, :content)
  end
end
```

## CORS (Cross-Origin Resource Sharing)

### CORS Configuration
```ruby
# Gemfile
gem 'rack-cors'

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow all origins in development
    origins Rails.env.development? ? '*' : ['https://myapp.com', 'https://admin.myapp.com']
    
    # Specify allowed resources
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 86400  # 24 hours
  end
  
  # Different rules for different resources
  allow do
    origins 'https://trusted-partner.com'
    resource '/webhooks/*',
      headers: :any,
      methods: [:post],
      credentials: false
  end
end
```

### Manual CORS Headers
```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ApplicationController
  before_action :set_cors_headers
  
  private
  
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = allowed_origins
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Max-Age'] = '86400'
  end
  
  def allowed_origins
    case Rails.env
    when 'development'
      '*'
    when 'production'
      request.headers['Origin'] if ['https://myapp.com', 'https://admin.myapp.com'].include?(request.headers['Origin'])
    else
      'https://staging.myapp.com'
    end
  end
  
  # Handle preflight requests
  def options
    head :ok
  end
end
```

## Data Encryption

### Rails Encryption (Rails 7+)
```ruby
# Generate master key (done automatically)
rails new myapp --main-branch=main

# app/models/user.rb
class User < ApplicationRecord
  # Encrypt sensitive data
  encrypts :social_security_number
  encrypts :credit_card_number, deterministic: true  # For searching
  encrypts :personal_notes, ignore_case: true        # Case-insensitive
  
  # Blind index for searchable encrypted data
  blind_index :email, key: :email_bidx_key
  
  # Custom encryption key
  encrypts :secret_data, key: :secret_data_key
  
  private
  
  def secret_data_key
    # Derive key from user-specific data
    Rails.application.key_generator.generate_key("secret_data_#{id}")
  end
end
```

### ActiveSupport::MessageEncryptor
```ruby
# Custom encryption service
class EncryptionService
  def self.encrypt(data, purpose: 'general')
    encryptor(purpose).encrypt_and_sign(data)
  end
  
  def self.decrypt(encrypted_data, purpose: 'general')
    encryptor(purpose).decrypt_and_verify(encrypted_data)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end
  
  private
  
  def self.encryptor(purpose)
    key = Rails.application.key_generator.generate_key("encryption_#{purpose}")
    ActiveSupport::MessageEncryptor.new(key)
  end
end

# Usage
encrypted_token = EncryptionService.encrypt("sensitive_data", purpose: 'tokens')
decrypted_data = EncryptionService.decrypt(encrypted_token, purpose: 'tokens')
```

### Database Encryption
```ruby
# Migration for encrypted columns
class AddEncryptedFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :encrypted_social_security_number, :string
    add_column :users, :encrypted_social_security_number_iv, :string
    
    add_index :users, :encrypted_social_security_number_iv, unique: true
  end
end

# Model with custom encryption
class User < ApplicationRecord
  attr_encrypted :social_security_number, 
                 key: Rails.application.credentials.encryption_key,
                 algorithm: 'aes-256-gcm'
  
  # Searchable encryption with blind indexing
  blind_index :email, 
              key: Rails.application.credentials.blind_index_key,
              algorithm: :argon2id
              
  def self.find_by_encrypted_email(email)
    find_by_email_bidx(BlindIndex.generate_bidx(email, key: blind_index_key))
  end
end
```

## Authentication Security

### Secure Session Configuration
```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_myapp_session',
  httponly: true,              # Prevent XSS attacks
  secure: Rails.env.production?,  # HTTPS only in production
  same_site: :lax,            # CSRF protection
  expire_after: 24.hours      # Session timeout

# config/application.rb
class Application < Rails::Application
  # Force SSL in production
  config.force_ssl = true if Rails.env.production?
  
  # Secure cookies
  config.ssl_options = {
    secure_cookies: true,
    hsts: {
      expires: 1.year,
      subdomains: true,
      preload: true
    }
  }
end
```

### Password Security
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  
  # Password validations
  validates :password, length: { minimum: 12 }, 
                      format: { with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/ },
                      if: :password_required?
  
  # Account lockout after failed attempts
  before_validation :check_failed_attempts
  after_validation :increment_failed_attempts, if: -> { errors[:password].any? }
  
  def account_locked?
    failed_attempts >= 5 && last_failed_attempt > 15.minutes.ago
  end
  
  def reset_failed_attempts!
    update_columns(failed_attempts: 0, last_failed_attempt: nil)
  end
  
  private
  
  def check_failed_attempts
    if account_locked?
      errors.add(:base, "Account locked due to too many failed attempts. Try again in 15 minutes.")
    end
  end
  
  def increment_failed_attempts
    increment!(:failed_attempts)
    touch(:last_failed_attempt)
  end
  
  def password_required?
    new_record? || password.present?
  end
end
```

### Two-Factor Authentication
```ruby
# Gemfile
gem 'rotp'  # Time-based OTP
gem 'rqrcode'  # QR code generation

# app/models/user.rb
class User < ApplicationRecord
  encrypts :otp_secret_key
  
  def generate_otp_secret!
    self.otp_secret_key = ROTP::Base32.random
    save!
  end
  
  def otp_provisioning_uri(issuer:)
    ROTP::TOTP.new(otp_secret_key, issuer: issuer).provisioning_uri(email)
  end
  
  def verify_otp(token)
    return false unless otp_secret_key
    
    totp = ROTP::TOTP.new(otp_secret_key)
    totp.verify(token, drift_behind: 30, drift_ahead: 30)
  end
  
  def backup_codes
    @backup_codes ||= encrypted_backup_codes&.split(',') || []
  end
  
  def generate_backup_codes!
    codes = 10.times.map { SecureRandom.hex(4) }
    self.encrypted_backup_codes = codes.join(',')
    save!
    codes
  end
  
  def use_backup_code!(code)
    codes = backup_codes
    return false unless codes.include?(code)
    
    codes.delete(code)
    self.encrypted_backup_codes = codes.join(',')
    save!
    true
  end
end

# app/controllers/two_factor_controller.rb
class TwoFactorController < ApplicationController
  before_action :authenticate_user!
  
  def setup
    current_user.generate_otp_secret!
    @qr_code = generate_qr_code
  end
  
  def verify
    if current_user.verify_otp(params[:token])
      current_user.update!(two_factor_enabled: true)
      @backup_codes = current_user.generate_backup_codes!
      redirect_to profile_path, notice: 'Two-factor authentication enabled'
    else
      flash.now[:alert] = 'Invalid verification code'
      render :setup
    end
  end
  
  private
  
  def generate_qr_code
    uri = current_user.otp_provisioning_uri(issuer: 'MyApp')
    RQRCode::QRCode.new(uri).as_svg(module_size: 4)
  end
end
```

## Authorization and Access Control

### Role-Based Access Control
```ruby
# app/models/user.rb
class User < ApplicationRecord
  enum role: { user: 0, moderator: 1, admin: 2 }
  
  def can?(action, resource)
    case role
    when 'admin'
      true
    when 'moderator'
      moderator_permissions(action, resource)
    when 'user'
      user_permissions(action, resource)
    end
  end
  
  private
  
  def moderator_permissions(action, resource)
    case resource.class.name
    when 'Post'
      [:read, :update, :delete].include?(action)
    when 'User'
      [:read].include?(action)
    else
      false
    end
  end
  
  def user_permissions(action, resource)
    case resource.class.name
    when 'Post'
      action == :read || ([:update, :delete].include?(action) && resource.user == self)
    else
      false
    end
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  rescue_from NotAuthorizedError, with: :access_denied
  
  def authorize!(action, resource)
    raise NotAuthorizedError unless current_user&.can?(action, resource)
  end
  
  private
  
  def access_denied
    redirect_to root_path, alert: 'Access denied'
  end
end
```

### Pundit Authorization
```ruby
# Gemfile
gem 'pundit'

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  rescue_from Pundit::NotAuthorizedError, with: :access_denied
  
  private
  
  def access_denied
    redirect_to root_path, alert: 'Access denied'
  end
end

# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def show?
    record.published? || owner? || admin?
  end
  
  def create?
    user.present?
  end
  
  def update?
    owner? || admin?
  end
  
  def destroy?
    owner? || admin?
  end
  
  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.published
      end
    end
  end
  
  private
  
  def owner?
    user == record.user
  end
  
  def admin?
    user&.admin?
  end
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    authorize @post
  end
  
  def index
    @posts = policy_scope(Post)
  end
  
  def update
    @post = Post.find(params[:id])
    authorize @post
    
    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end
end
```

## Input Validation and Sanitization

### SQL Injection Prevention
```ruby
# GOOD: Use parameterized queries
User.where("name = ?", params[:name])
User.where(name: params[:name])
User.find_by(email: params[:email])

# BAD: String interpolation (vulnerable to SQL injection)
# User.where("name = '#{params[:name]}'")  # DON'T DO THIS

# Raw SQL with parameters
User.where("created_at > ? AND status = ?", 1.week.ago, 'active')

# Named parameters
User.where(
  "created_at > :date AND status = :status", 
  date: 1.week.ago, 
  status: 'active'
)
```

### XSS Prevention
```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def safe_html(content)
    # Sanitize HTML content
    sanitize(content, tags: %w[p br strong em ul ol li a], 
                     attributes: %w[href target])
  end
  
  def truncated_content(content, length: 100)
    # Always escape user content
    truncate(html_escape(content), length: length)
  end
end

# In views
# GOOD: HTML is automatically escaped
<%= @post.title %>

# GOOD: Explicitly mark safe content
<%== sanitize(@post.content) %>

# BAD: Raw HTML (vulnerable to XSS)
# <%== @post.content %>  # DON'T DO THIS unless content is trusted
```

### File Upload Security
```ruby
# app/models/document.rb
class Document < ApplicationRecord
  has_one_attached :file
  
  validate :acceptable_file
  
  private
  
  def acceptable_file
    return unless file.attached?
    
    # Check file type
    unless file.blob.content_type.in?(%w[image/jpeg image/png application/pdf])
      errors.add(:file, 'must be a JPEG, PNG, or PDF')
    end
    
    # Check file size (5MB limit)
    if file.blob.byte_size > 5.megabytes
      errors.add(:file, 'must be less than 5MB')
    end
    
    # Check file extension
    extension = File.extname(file.blob.filename.to_s).downcase
    unless %w[.jpg .jpeg .png .pdf].include?(extension)
      errors.add(:file, 'must have a valid extension')
    end
  end
end

# config/environments/production.rb
Rails.application.configure do
  # Scan uploads with antivirus
  config.active_storage.virus_scanner = :clamav
  
  # Store uploads outside web root
  config.active_storage.variant_processor = :mini_magick
end
```

## Security Headers

### Security Header Configuration
```ruby
# config/application.rb
class Application < Rails::Application
  # Security headers middleware
  config.force_ssl = true
  
  config.ssl_options = {
    hsts: {
      expires: 1.year,
      subdomains: true,
      preload: true
    }
  }
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_security_headers
  
  private
  
  def set_security_headers
    # Content Security Policy
    response.headers['Content-Security-Policy'] = [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' https://fonts.gstatic.com",
      "img-src 'self' data: https:",
      "connect-src 'self'"
    ].join('; ')
    
    # X-Frame-Options
    response.headers['X-Frame-Options'] = 'DENY'
    
    # X-Content-Type-Options
    response.headers['X-Content-Type-Options'] = 'nosniff'
    
    # X-XSS-Protection
    response.headers['X-XSS-Protection'] = '1; mode=block'
    
    # Referrer Policy
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    
    # Feature Policy
    response.headers['Permissions-Policy'] = [
      'geolocation=()',
      'microphone=()',
      'camera=()'
    ].join(', ')
  end
end
```

### Secure Headers Gem
```ruby
# Gemfile
gem 'secure_headers'

# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.csp = {
    default_src: %w['self'],
    script_src: %w['self' 'unsafe-inline' https://cdn.jsdelivr.net],
    style_src: %w['self' 'unsafe-inline' https://fonts.googleapis.com],
    font_src: %w['self' https://fonts.gstatic.com],
    img_src: %w['self' data: https:],
    connect_src: %w['self'],
    frame_ancestors: %w['none'],
    form_action: %w['self'],
    upgrade_insecure_requests: true
  }
  
  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains; preload"
  config.x_frame_options = 'DENY'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.referrer_policy = 'strict-origin-when-cross-origin'
end
```

## Security Testing

### Security Tests
```ruby
# test/controllers/security_test.rb
require 'test_helper'

class SecurityTest < ActionDispatch::IntegrationTest
  test "CSRF protection is enabled" do
    post posts_path, params: { post: { title: 'Test' } }
    assert_response :forbidden
  end
  
  test "SQL injection protection" do
    malicious_input = "'; DROP TABLE users; --"
    get posts_path, params: { search: malicious_input }
    assert_response :success
    assert User.count > 0  # Table should still exist
  end
  
  test "XSS protection in output" do
    post = posts(:one)
    post.update!(title: "<script>alert('xss')</script>")
    
    get post_path(post)
    assert_response :success
    assert_not_includes response.body, "<script>alert('xss')</script>"
    assert_includes response.body, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
  end
  
  test "security headers are present" do
    get root_path
    assert_response :success
    
    assert_includes response.headers['Content-Security-Policy'], "default-src 'self'"
    assert_equal 'DENY', response.headers['X-Frame-Options']
    assert_equal 'nosniff', response.headers['X-Content-Type-Options']
  end
end
```

## Security Monitoring

### Security Event Logging
```ruby
# app/services/security_logger.rb
class SecurityLogger
  def self.log_failed_login(email, ip_address)
    Rails.logger.warn "Failed login attempt for #{email} from #{ip_address}"
    
    # Send to security monitoring service
    SecurityMonitor.alert(
      event: 'failed_login',
      email: email,
      ip_address: ip_address,
      timestamp: Time.current
    )
  end
  
  def self.log_suspicious_activity(user, activity, details = {})
    Rails.logger.warn "Suspicious activity: #{activity} by user #{user.id}"
    
    SecurityMonitor.alert(
      event: 'suspicious_activity',
      user_id: user.id,
      activity: activity,
      details: details,
      timestamp: Time.current
    )
  end
end

# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path
    else
      SecurityLogger.log_failed_login(params[:email], request.remote_ip)
      flash.now[:alert] = 'Invalid credentials'
      render :new
    end
  end
end
```

## References

- [Securing Rails Applications](https://guides.rubyonrails.org/security.html)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Credentials](https://guides.rubyonrails.org/security.html#environmental-security)