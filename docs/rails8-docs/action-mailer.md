# ActionMailer & Email Delivery

## Overview

ActionMailer provides a framework for sending emails from Rails applications. It integrates with ActiveJob for background delivery and supports multiple delivery methods including SMTP, sendmail, and third-party services.

## Basic Mailer Structure

### Generating Mailers
```bash
# Generate a mailer
rails generate mailer UserMailer

# Generate with specific methods
rails generate mailer UserMailer welcome password_reset confirmation
```

### Mailer Class Structure
```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  # Default sender and layout
  default from: 'noreply@example.com'
  layout 'mailer'
  
  def welcome(user)
    @user = user
    @login_url = login_url
    
    mail(
      to: @user.email,
      subject: 'Welcome to MyApp!'
    )
  end
  
  def password_reset(user, token)
    @user = user
    @token = token
    @reset_url = edit_password_reset_url(@token)
    
    mail(
      to: @user.email,
      subject: 'Reset your password',
      template_path: 'user_mailer',
      template_name: 'password_reset'
    )
  end
  
  def notification(user, subject, message)
    @user = user
    @message = message
    
    mail(
      to: @user.email,
      subject: subject,
      priority: 'high'
    )
  end
  
  # Mailer with attachments
  def report(user, report_data)
    @user = user
    
    # Attach file from path
    attachments['report.pdf'] = File.read(Rails.root.join('tmp', 'report.pdf'))
    
    # Attach from blob
    if report_data.is_a?(ActiveStorage::Blob)
      attachments[report_data.filename.to_s] = report_data.download
    end
    
    # Inline attachments
    attachments.inline['logo.png'] = File.read(Rails.root.join('app', 'assets', 'images', 'logo.png'))
    
    mail(
      to: @user.email,
      subject: 'Your Monthly Report'
    )
  end
end
```

### Application Mailer
```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('DEFAULT_EMAIL_FROM', 'noreply@example.com')
  layout 'mailer'
  
  # Global before actions
  before_action :set_user_time_zone
  before_action :add_inline_logo
  
  private
  
  def set_user_time_zone
    if params[:user].present?
      Time.zone = params[:user].time_zone || 'UTC'
    end
  end
  
  def add_inline_logo
    attachments.inline['logo.png'] = Rails.root.join('app', 'assets', 'images', 'email-logo.png').read
  end
end
```

## Email Templates

### HTML Templates
```erb
<!-- app/views/user_mailer/welcome.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Welcome to MyApp</title>
    <style>
      .container { max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif; }
      .header { background-color: #3b82f6; color: white; padding: 20px; text-align: center; }
      .content { padding: 20px; }
      .button { 
        display: inline-block; 
        padding: 12px 24px; 
        background-color: #3b82f6; 
        color: white; 
        text-decoration: none; 
        border-radius: 4px; 
      }
      .footer { background-color: #f3f4f6; padding: 20px; text-align: center; font-size: 12px; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <%= image_tag attachments['logo.png'].url, alt: 'MyApp Logo', style: 'height: 40px;' %>
        <h1>Welcome to MyApp!</h1>
      </div>
      
      <div class="content">
        <h2>Hi <%= @user.name %>,</h2>
        
        <p>We're excited to have you join our community! Your account has been successfully created.</p>
        
        <p>Here are some things you can do to get started:</p>
        <ul>
          <li>Complete your profile</li>
          <li>Explore our features</li>
          <li>Connect with other users</li>
        </ul>
        
        <p style="text-align: center; margin: 30px 0;">
          <%= link_to 'Get Started', @login_url, class: 'button' %>
        </p>
        
        <p>If you have any questions, feel free to reach out to our support team.</p>
        
        <p>Best regards,<br>The MyApp Team</p>
      </div>
      
      <div class="footer">
        <p>© <%= Date.current.year %> MyApp. All rights reserved.</p>
        <p>
          <%= link_to 'Unsubscribe', unsubscribe_url(@user.unsubscribe_token) %> | 
          <%= link_to 'Update Preferences', preferences_url %>
        </p>
      </div>
    </div>
  </body>
</html>
```

### Text Templates
```erb
<!-- app/views/user_mailer/welcome.text.erb -->
Welcome to MyApp!

Hi <%= @user.name %>,

We're excited to have you join our community! Your account has been successfully created.

Here are some things you can do to get started:
- Complete your profile
- Explore our features  
- Connect with other users

Get started: <%= @login_url %>

If you have any questions, feel free to reach out to our support team.

Best regards,
The MyApp Team

---
© <%= Date.current.year %> MyApp. All rights reserved.
Unsubscribe: <%= unsubscribe_url(@user.unsubscribe_token) %>
Update Preferences: <%= preferences_url %>
```

### Mailer Layouts
```erb
<!-- app/views/layouts/mailer.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      /* Reset styles */
      body, table, td, p, a, li, blockquote {
        -webkit-text-size-adjust: 100%;
        -ms-text-size-adjust: 100%;
      }
      table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
      
      /* Base styles */
      body {
        margin: 0;
        padding: 0;
        font-family: Arial, sans-serif;
        line-height: 1.6;
        color: #333;
      }
      
      .email-container {
        max-width: 600px;
        margin: 0 auto;
        background-color: #ffffff;
      }
      
      /* Responsive */
      @media only screen and (max-width: 600px) {
        .email-container { width: 100% !important; }
        .content { padding: 10px !important; }
      }
    </style>
  </head>
  <body>
    <div class="email-container">
      <%= yield %>
    </div>
  </body>
</html>

<!-- app/views/layouts/mailer.text.erb -->
<%= yield %>
```

## Email Configuration

### Development Configuration
```ruby
# config/environments/development.rb
Rails.application.configure do
  # Email delivery method
  config.action_mailer.delivery_method = :letter_opener
  # config.action_mailer.delivery_method = :smtp
  
  # SMTP settings for development
  config.action_mailer.smtp_settings = {
    address: 'localhost',
    port: 1025,  # Mailcatcher port
    domain: 'localhost'
  }
  
  # URL options
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  
  # Don't raise errors for missing translations
  config.action_mailer.raise_delivery_errors = true
  
  # Cache mailer views
  config.action_mailer.perform_caching = false
end
```

### Production Configuration
```ruby
# config/environments/production.rb
Rails.application.configure do
  # Use SMTP in production
  config.action_mailer.delivery_method = :smtp
  
  # SMTP settings
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_HOST'],
    port: ENV['SMTP_PORT'] || 587,
    domain: ENV['SMTP_DOMAIN'],
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: :plain,
    enable_starttls_auto: true,
    open_timeout: 10,
    read_timeout: 10
  }
  
  # URL options
  config.action_mailer.default_url_options = { 
    host: ENV['APPLICATION_HOST'],
    protocol: 'https'
  }
  
  # Error handling
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = true
  
  # Asset host for images
  config.action_mailer.asset_host = ENV['CDN_HOST']
end
```

### Third-Party Services
```ruby
# Sendgrid configuration
# config/initializers/sendgrid.rb
if Rails.env.production?
  ActionMailer::Base.smtp_settings = {
    user_name: 'apikey',
    password: ENV['SENDGRID_API_KEY'],
    domain: ENV['SENDGRID_DOMAIN'],
    address: 'smtp.sendgrid.net',
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }
end

# Mailgun configuration
# Gemfile
gem 'mailgun-ruby'

# config/initializers/mailgun.rb
if Rails.env.production?
  ActionMailer::Base.delivery_method = :mailgun
  ActionMailer::Base.mailgun_settings = {
    api_key: ENV['MAILGUN_API_KEY'],
    domain: ENV['MAILGUN_DOMAIN'],
    api_host: 'api.eu.mailgun.net'  # EU region
  }
end
```

## Sending Emails

### Immediate Delivery
```ruby
# Send email immediately (synchronous)
UserMailer.welcome(user).deliver_now
UserMailer.password_reset(user, token).deliver_now

# With error handling
begin
  UserMailer.welcome(user).deliver_now
rescue StandardError => e
  Rails.logger.error "Failed to send welcome email: #{e.message}"
  ErrorTracker.notify(e, user_id: user.id)
end
```

### Background Delivery
```ruby
# Send email in background (asynchronous)
UserMailer.welcome(user).deliver_later

# Schedule for later
UserMailer.welcome(user).deliver_later(wait: 1.hour)
UserMailer.welcome(user).deliver_later(wait_until: Date.tomorrow.noon)

# With priority
UserMailer.welcome(user).deliver_later(priority: 10)

# With custom queue
UserMailer.welcome(user).deliver_later(queue: 'emails')
```

### Bulk Email Sending
```ruby
# app/jobs/bulk_email_job.rb
class BulkEmailJob < ApplicationJob
  queue_as :bulk_emails
  
  def perform(user_ids, email_type, **options)
    User.where(id: user_ids).find_each do |user|
      next unless user.email_subscribed?
      
      case email_type
      when 'newsletter'
        NewsletterMailer.weekly(user).deliver_now
      when 'promotion'
        PromotionMailer.special_offer(user, options[:offer_id]).deliver_now
      end
      
      # Rate limiting
      sleep(0.1)
    rescue StandardError => e
      Rails.logger.error "Failed to send #{email_type} to user #{user.id}: #{e.message}"
    end
  end
end

# Usage
user_ids = User.subscribed.pluck(:id)
BulkEmailJob.perform_later(user_ids, 'newsletter')
```

## Advanced Email Features

### Parameterized Mailers
```ruby
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def notification
    @user = params[:user]
    @message = params[:message]
    @urgency = params[:urgency] || 'normal'
    
    mail(
      to: @user.email,
      subject: notification_subject,
      priority: @urgency == 'high' ? 'high' : 'normal'
    )
  end
  
  private
  
  def notification_subject
    case @urgency
    when 'high'
      "[URGENT] #{params[:subject]}"
    when 'low'
      "[INFO] #{params[:subject]}"
    else
      params[:subject]
    end
  end
end

# Usage
UserMailer.with(
  user: current_user,
  message: "Your order has shipped",
  subject: "Order Update",
  urgency: 'high'
).notification.deliver_later
```

### Email Previews
```ruby
# test/mailers/previews/user_mailer_preview.rb
class UserMailerPreview < ActionMailer::Preview
  def welcome
    user = User.first || User.new(
      name: "John Doe",
      email: "john@example.com"
    )
    UserMailer.welcome(user)
  end
  
  def password_reset
    user = User.first
    token = SecureRandom.hex(20)
    UserMailer.password_reset(user, token)
  end
  
  def notification
    UserMailer.with(
      user: User.first,
      message: "This is a sample notification message",
      subject: "Sample Notification"
    ).notification
  end
end

# Access previews at: http://localhost:3000/rails/mailers
```

### Multipart Emails
```ruby
# app/mailers/newsletter_mailer.rb
class NewsletterMailer < ApplicationMailer
  def weekly(user)
    @user = user
    @articles = Article.published.recent.limit(5)
    
    # Automatically includes both HTML and text versions
    # if both templates exist
    mail(
      to: @user.email,
      subject: "Weekly Newsletter - #{Date.current.strftime('%B %d, %Y')}"
    )
  end
  
  # Manual multipart
  def custom_multipart(user)
    @user = user
    
    mail(to: @user.email, subject: "Custom Email") do |format|
      format.html { render 'custom_html' }
      format.text { render 'custom_text' }
    end
  end
end
```

### Email Interceptors and Observers
```ruby
# app/mailers/interceptors/development_interceptor.rb
class DevelopmentInterceptor
  def self.delivering_email(message)
    # Redirect all emails to developer in development
    if Rails.env.development?
      message.to = ['developer@example.com']
      message.subject = "[DEV] #{message.subject}"
    end
  end
end

# app/mailers/observers/email_logger.rb
class EmailLogger
  def self.delivered_email(message)
    Rails.logger.info "Email sent to #{message.to.join(', ')} with subject: #{message.subject}"
    
    # Log to database
    EmailLog.create!(
      to: message.to.join(', '),
      subject: message.subject,
      sent_at: Time.current
    )
  end
end

# config/initializers/mail.rb
if Rails.env.development?
  ActionMailer::Base.register_interceptor(DevelopmentInterceptor)
end

ActionMailer::Base.register_observer(EmailLogger)
```

## Email Security and Best Practices

### Security Considerations
```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  # Prevent email header injection
  before_action :sanitize_email_headers
  
  private
  
  def sanitize_email_headers
    # Remove newlines from subject and other headers
    if @_mail_was_called
      mail.subject = mail.subject.to_s.gsub(/\r?\n/, '')
      mail.from = Array(mail.from).map { |addr| addr.gsub(/\r?\n/, '') }
      mail.to = Array(mail.to).map { |addr| addr.gsub(/\r?\n/, '') }
    end
  end
end

# Rate limiting
class UserMailer < ApplicationMailer
  before_action :check_rate_limit
  
  private
  
  def check_rate_limit
    user = params[:user]
    cache_key = "email_rate_limit:#{user.id}"
    
    sent_count = Rails.cache.read(cache_key) || 0
    if sent_count >= 10  # Max 10 emails per hour
      raise "Email rate limit exceeded for user #{user.id}"
    end
    
    Rails.cache.write(cache_key, sent_count + 1, expires_in: 1.hour)
  end
end
```

### Unsubscribe Handling
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_token :unsubscribe_token
  
  def unsubscribe!
    update!(email_subscribed: false, unsubscribed_at: Time.current)
  end
  
  def resubscribe!
    update!(email_subscribed: true, unsubscribed_at: nil)
  end
end

# app/controllers/unsubscribes_controller.rb
class UnsubscribesController < ApplicationController
  def show
    @user = User.find_by!(unsubscribe_token: params[:token])
  end
  
  def create
    @user = User.find_by!(unsubscribe_token: params[:token])
    @user.unsubscribe!
    
    redirect_to unsubscribe_path(@user.unsubscribe_token), 
                notice: 'You have been unsubscribed from all emails.'
  end
end

# Include in email templates
<%# In email template %>
<p>
  Don't want to receive these emails? 
  <%= link_to 'Unsubscribe', unsubscribe_url(@user.unsubscribe_token) %>
</p>
```

## Testing Emails

### Mailer Tests
```ruby
# test/mailers/user_mailer_test.rb
require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "welcome email" do
    user = users(:one)
    email = UserMailer.welcome(user)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ['noreply@example.com'], email.from
    assert_equal [user.email], email.to
    assert_equal 'Welcome to MyApp!', email.subject
    assert_match user.name, email.body.to_s
  end
  
  test "password reset email contains reset link" do
    user = users(:one)
    token = 'reset_token_123'
    email = UserMailer.password_reset(user, token)
    
    assert_match edit_password_reset_url(token), email.body.to_s
  end
  
  test "notification email with high priority" do
    email = UserMailer.with(
      user: users(:one),
      message: "Test message",
      subject: "Test",
      urgency: 'high'
    ).notification
    
    assert_equal 'high', email.priority
    assert_equal '[URGENT] Test', email.subject
  end
end
```

### Integration Tests
```ruby
# test/integration/email_flows_test.rb
require 'test_helper'

class EmailFlowsTest < ActionDispatch::IntegrationTest
  test "user signup sends welcome email" do
    assert_emails 1 do
      post users_path, params: {
        user: {
          name: 'New User',
          email: 'new@example.com',
          password: 'password'
        }
      }
    end
    
    welcome_email = ActionMailer::Base.deliveries.last
    assert_equal ['new@example.com'], welcome_email.to
    assert_equal 'Welcome to MyApp!', welcome_email.subject
  end
  
  test "password reset flow" do
    user = users(:one)
    
    assert_emails 1 do
      post password_resets_path, params: { email: user.email }
    end
    
    reset_email = ActionMailer::Base.deliveries.last
    reset_url = extract_reset_url(reset_email.body.to_s)
    
    # Follow the reset link
    get reset_url
    assert_response :success
  end
  
  private
  
  def extract_reset_url(email_body)
    email_body.match(/http.*?password_resets.*?edit/)[0]
  end
end
```

## Monitoring and Analytics

### Email Delivery Monitoring
```ruby
# app/models/email_log.rb
class EmailLog < ApplicationRecord
  validates :to, :subject, presence: true
  
  scope :delivered, -> { where.not(delivered_at: nil) }
  scope :failed, -> { where.not(failed_at: nil) }
  scope :recent, -> { where(created_at: 1.week.ago..) }
  
  def self.delivery_rate
    return 0 if count.zero?
    
    delivered.count.to_f / count * 100
  end
end

# app/mailers/observers/delivery_tracker.rb
class DeliveryTracker
  def self.delivered_email(message)
    EmailLog.find_by(message_id: message.message_id)&.update!(delivered_at: Time.current)
  end
end

# Webhook handling for services like SendGrid
# app/controllers/webhooks/sendgrid_controller.rb
class Webhooks::SendgridController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def events
    events = JSON.parse(request.body.read)
    
    events.each do |event|
      case event['event']
      when 'delivered'
        EmailLog.find_by(message_id: event['smtp-id'])&.update!(delivered_at: Time.at(event['timestamp']))
      when 'bounce', 'dropped'
        EmailLog.find_by(message_id: event['smtp-id'])&.update!(failed_at: Time.at(event['timestamp']))
      end
    end
    
    head :ok
  end
end
```

## References

- [Action Mailer Basics](https://guides.rubyonrails.org/action_mailer_basics.html)
- [Active Job Integration](https://guides.rubyonrails.org/active_job_basics.html)
- [Email Testing](https://guides.rubyonrails.org/testing.html#testing-your-mailers)
- [ActionMailer API](https://api.rubyonrails.org/classes/ActionMailer/Base.html)