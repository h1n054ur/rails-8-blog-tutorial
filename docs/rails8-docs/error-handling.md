# Error Handling & Custom Exceptions

## Overview

Rails provides robust error handling mechanisms to gracefully manage exceptions, display user-friendly error pages, and maintain application stability. This includes built-in rescue mechanisms, custom exception classes, and error reporting.

## Basic Error Handling

### Controller Exception Handling
```ruby
class ApplicationController < ActionController::Base
  # Global exception handling
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request
  rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized
  
  private
  
  def handle_standard_error(exception)
    Rails.logger.error "Unhandled exception: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    respond_to do |format|
      format.html { render 'errors/500', status: :internal_server_error }
      format.json { render json: { error: 'Internal server error' }, status: :internal_server_error }
    end
  end
  
  def handle_not_found(exception)
    respond_to do |format|
      format.html { render 'errors/404', status: :not_found }
      format.json { render json: { error: 'Resource not found' }, status: :not_found }
    end
  end
  
  def handle_bad_request(exception)
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Invalid request' }
      format.json { render json: { error: exception.message }, status: :bad_request }
    end
  end
  
  def handle_unauthorized(exception)
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Access denied' }
      format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
    end
  end
end
```

### Specific Controller Error Handling
```ruby
class PostsController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  
  def show
    # @post is set by before_action
  end
  
  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      redirect_to @post, notice: 'Post created successfully'
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    handle_validation_error(e)
  end
  
  private
  
  def set_post
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: 'Post not found'
  end
  
  def handle_validation_error(exception)
    @post = exception.record
    
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { 
        render json: { 
          error: 'Validation failed', 
          details: @post.errors.full_messages 
        }, status: :unprocessable_entity 
      }
    end
  end
end
```

## Custom Exception Classes

### Application-Specific Exceptions
```ruby
# app/exceptions/application_error.rb
class ApplicationError < StandardError
  attr_reader :message, :status, :code
  
  def initialize(message: nil, status: :internal_server_error, code: nil)
    @message = message || self.class.name.humanize
    @status = status
    @code = code
    super(@message)
  end
  
  def to_h
    {
      error: {
        message: @message,
        code: @code,
        status: Rack::Utils::SYMBOL_TO_STATUS_CODE[@status]
      }
    }
  end
end

# Specific exception classes
class ValidationError < ApplicationError
  def initialize(errors)
    @errors = errors
    super(message: 'Validation failed', status: :unprocessable_entity, code: 'VALIDATION_ERROR')
  end
  
  def to_h
    super.merge(details: @errors)
  end
end

class AuthenticationError < ApplicationError
  def initialize(message = 'Authentication required')
    super(message: message, status: :unauthorized, code: 'AUTHENTICATION_REQUIRED')
  end
end

class AuthorizationError < ApplicationError
  def initialize(message = 'Access denied')
    super(message: message, status: :forbidden, code: 'ACCESS_DENIED')
  end
end

class ResourceNotFoundError < ApplicationError
  def initialize(resource = 'Resource')
    super(message: "#{resource} not found", status: :not_found, code: 'RESOURCE_NOT_FOUND')
  end
end

class ExternalServiceError < ApplicationError
  attr_reader :service_name, :original_error
  
  def initialize(service_name, original_error = nil)
    @service_name = service_name
    @original_error = original_error
    
    message = "#{service_name} service unavailable"
    message += ": #{original_error.message}" if original_error
    
    super(message: message, status: :service_unavailable, code: 'EXTERNAL_SERVICE_ERROR')
  end
end
```

### Business Logic Exceptions
```ruby
# app/exceptions/business_errors.rb
class PaymentError < ApplicationError
  def initialize(message = 'Payment processing failed')
    super(message: message, status: :payment_required, code: 'PAYMENT_ERROR')
  end
end

class InsufficientFundsError < PaymentError
  def initialize
    super('Insufficient funds')
    @code = 'INSUFFICIENT_FUNDS'
  end
end

class ExpiredCardError < PaymentError
  def initialize
    super('Credit card has expired')
    @code = 'EXPIRED_CARD'
  end
end

class InventoryError < ApplicationError
  def initialize(product_name)
    super(
      message: "#{product_name} is out of stock",
      status: :conflict,
      code: 'OUT_OF_STOCK'
    )
  end
end

class RateLimitError < ApplicationError
  def initialize(retry_after = nil)
    @retry_after = retry_after
    super(
      message: 'Rate limit exceeded',
      status: :too_many_requests,
      code: 'RATE_LIMIT_EXCEEDED'
    )
  end
  
  def to_h
    result = super
    result[:retry_after] = @retry_after if @retry_after
    result
  end
end
```

### Using Custom Exceptions
```ruby
class PaymentService
  def process_payment(order, payment_method)
    validate_payment_method!(payment_method)
    
    begin
      result = payment_gateway.charge(
        amount: order.total,
        source: payment_method.token
      )
      
      handle_payment_result(result, order)
    rescue PaymentGateway::Error => e
      handle_gateway_error(e)
    rescue => e
      Rails.logger.error "Unexpected payment error: #{e.message}"
      raise ExternalServiceError.new('Payment Gateway', e)
    end
  end
  
  private
  
  def validate_payment_method!(payment_method)
    raise ExpiredCardError if payment_method.expired?
    raise PaymentError.new('Invalid payment method') unless payment_method.valid?
  end
  
  def handle_payment_result(result, order)
    case result.status
    when 'succeeded'
      order.mark_as_paid!
      result
    when 'insufficient_funds'
      raise InsufficientFundsError
    when 'card_declined'
      raise PaymentError.new('Card declined')
    else
      raise PaymentError.new("Payment failed: #{result.failure_reason}")
    end
  end
  
  def handle_gateway_error(error)
    case error.code
    when 'card_expired'
      raise ExpiredCardError
    when 'insufficient_funds'
      raise InsufficientFundsError
    else
      raise PaymentError.new(error.message)
    end
  end
end

# Controller usage
class OrdersController < ApplicationController
  rescue_from PaymentError, with: :handle_payment_error
  rescue_from InventoryError, with: :handle_inventory_error
  
  def checkout
    begin
      PaymentService.new.process_payment(@order, @payment_method)
      redirect_to @order, notice: 'Payment processed successfully'
    rescue InsufficientFundsError
      redirect_to edit_order_path(@order), alert: 'Insufficient funds. Please try a different payment method.'
    end
  end
  
  private
  
  def handle_payment_error(exception)
    redirect_to edit_order_path(@order), alert: exception.message
  end
  
  def handle_inventory_error(exception)
    redirect_to @order, alert: exception.message
  end
end
```

## Error Pages

### Custom Error Pages
```erb
<!-- app/views/errors/404.html.erb -->
<div class="error-page">
  <div class="error-content">
    <h1>Page Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>
    <p>You may have mistyped the address or the page may have moved.</p>
    
    <div class="error-actions">
      <%= link_to 'Go Home', root_path, class: 'btn btn-primary' %>
      <%= link_to 'Contact Support', contact_path, class: 'btn btn-secondary' %>
    </div>
  </div>
</div>

<!-- app/views/errors/500.html.erb -->
<div class="error-page">
  <div class="error-content">
    <h1>Something Went Wrong</h1>
    <p>We're sorry, but something went wrong on our end.</p>
    <p>Our team has been notified and is working to fix the issue.</p>
    
    <div class="error-actions">
      <%= link_to 'Try Again', request.referer || root_path, class: 'btn btn-primary' %>
      <%= link_to 'Go Home', root_path, class: 'btn btn-secondary' %>
    </div>
  </div>
</div>

<!-- app/views/errors/422.html.erb -->
<div class="error-page">
  <div class="error-content">
    <h1>Unprocessable Entity</h1>
    <p>The change you wanted was rejected.</p>
    <p>Maybe you tried to change something you didn't have access to.</p>
    
    <div class="error-actions">
      <%= link_to 'Go Back', 'javascript:history.back()', class: 'btn btn-primary' %>
      <%= link_to 'Go Home', root_path, class: 'btn btn-secondary' %>
    </div>
  </div>
</div>
```

### Dynamic Error Pages
```ruby
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  
  def show
    @status_code = params[:status_code] || 500
    @exception = request.env['action_dispatch.exception']
    
    respond_to do |format|
      format.html { render template: "errors/#{@status_code}", status: @status_code }
      format.json { render json: error_json, status: @status_code }
    end
  end
  
  private
  
  def error_json
    {
      error: {
        status: @status_code,
        message: error_message,
        timestamp: Time.current.iso8601
      }
    }
  end
  
  def error_message
    case @status_code.to_i
    when 404
      'The requested resource was not found'
    when 422
      'The request was well-formed but contains invalid data'
    when 500
      'An internal server error occurred'
    else
      'An error occurred'
    end
  end
end

# config/routes.rb
Rails.application.routes.draw do
  # Dynamic error handling
  get '/errors/:status_code', to: 'errors#show', as: :error
end

# config/application.rb
config.exceptions_app = self.routes
```

## Error Reporting and Tracking

### Error Notifier Service
```ruby
# app/services/error_notifier.rb
class ErrorNotifier
  def self.notify(exception, context = {})
    error_data = {
      exception_class: exception.class.name,
      message: exception.message,
      backtrace: exception.backtrace,
      context: context,
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }
    
    # Log locally
    Rails.logger.error "Error notification: #{error_data.to_json}"
    
    # Send to external services
    send_to_sentry(exception, context) if Rails.env.production?
    send_to_slack(error_data) if critical_error?(exception)
    store_in_database(error_data)
  end
  
  private
  
  def self.send_to_sentry(exception, context)
    Sentry.capture_exception(exception, extra: context)
  end
  
  def self.send_to_slack(error_data)
    SlackNotifier.notify(
      channel: '#alerts',
      message: "🚨 Critical error in #{Rails.env}: #{error_data[:message]}",
      attachments: [{
        color: 'danger',
        fields: [
          { title: 'Exception', value: error_data[:exception_class], short: true },
          { title: 'Environment', value: error_data[:environment], short: true },
          { title: 'Time', value: error_data[:timestamp], short: true }
        ]
      }]
    )
  end
  
  def self.store_in_database(error_data)
    ErrorLog.create!(
      exception_class: error_data[:exception_class],
      message: error_data[:message],
      backtrace: error_data[:backtrace]&.join("\n"),
      context: error_data[:context],
      environment: error_data[:environment]
    )
  rescue => e
    Rails.logger.error "Failed to store error in database: #{e.message}"
  end
  
  def self.critical_error?(exception)
    critical_classes = [
      PaymentError,
      ExternalServiceError,
      SecurityError
    ]
    
    critical_classes.any? { |klass| exception.is_a?(klass) }
  end
end
```

### Error Log Model
```ruby
# app/models/error_log.rb
class ErrorLog < ApplicationRecord
  validates :exception_class, :message, presence: true
  
  scope :recent, -> { where(created_at: 24.hours.ago..) }
  scope :critical, -> { where(exception_class: ['PaymentError', 'SecurityError']) }
  scope :by_class, ->(class_name) { where(exception_class: class_name) }
  
  def self.error_summary(period = 24.hours)
    where(created_at: period.ago..)
      .group(:exception_class)
      .count
      .sort_by { |_, count| -count }
  end
  
  def self.error_rate(period = 1.hour)
    count = where(created_at: period.ago..).count
    count.to_f / period.in_minutes
  end
end

# Migration
class CreateErrorLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :error_logs do |t|
      t.string :exception_class, null: false
      t.text :message, null: false
      t.text :backtrace
      t.json :context
      t.string :environment
      t.string :user_id
      t.string :request_id
      
      t.timestamps
    end
    
    add_index :error_logs, :exception_class
    add_index :error_logs, :created_at
    add_index :error_logs, [:environment, :created_at]
  end
end
```

## API Error Handling

### Consistent API Error Responses
```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ApplicationController
  rescue_from ApplicationError, with: :handle_application_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  
  private
  
  def handle_application_error(exception)
    render json: exception.to_h, status: exception.status
  end
  
  def handle_not_found(exception)
    error = ResourceNotFoundError.new
    render json: error.to_h, status: error.status
  end
  
  def handle_parameter_missing(exception)
    render json: {
      error: {
        message: 'Missing required parameter',
        code: 'PARAMETER_MISSING',
        details: exception.message,
        status: 400
      }
    }, status: :bad_request
  end
end

# Usage in API controllers
class Api::V1::PostsController < Api::BaseController
  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      render json: @post, status: :created
    else
      raise ValidationError.new(@post.errors.full_messages)
    end
  end
  
  def show
    @post = Post.find(params[:id])
    
    raise AuthorizationError unless can?(:read, @post)
    
    render json: @post
  end
end
```

## Error Monitoring and Alerting

### Monitoring Service
```ruby
# app/services/error_monitoring_service.rb
class ErrorMonitoringService
  ALERT_THRESHOLDS = {
    error_rate: 10,      # errors per minute
    critical_errors: 1,  # any critical error
    database_errors: 5   # database errors per minute
  }.freeze
  
  def self.check_error_rates
    current_rate = ErrorLog.error_rate(1.minute)
    
    if current_rate > ALERT_THRESHOLDS[:error_rate]
      send_alert(
        type: 'high_error_rate',
        message: "Error rate is #{current_rate.round(2)} errors/minute",
        severity: 'warning'
      )
    end
    
    critical_count = ErrorLog.critical.where(created_at: 1.minute.ago..).count
    
    if critical_count > ALERT_THRESHOLDS[:critical_errors]
      send_alert(
        type: 'critical_errors',
        message: "#{critical_count} critical errors in the last minute",
        severity: 'critical'
      )
    end
  end
  
  def self.send_alert(type:, message:, severity:)
    AlertService.send(
      channel: severity == 'critical' ? '#critical-alerts' : '#monitoring',
      message: "🚨 #{severity.upcase}: #{message}",
      type: type
    )
  end
end

# Schedule monitoring checks
# config/schedule.rb (with whenever gem)
every 1.minute do
  runner "ErrorMonitoringService.check_error_rates"
end
```

## Testing Error Handling

### Error Handling Tests
```ruby
# test/controllers/posts_controller_test.rb
class PostsControllerTest < ActionDispatch::IntegrationTest
  test "handles not found errors gracefully" do
    get post_path(99999)
    
    assert_response :not_found
    assert_select 'h1', 'Page Not Found'
  end
  
  test "handles validation errors" do
    sign_in users(:one)
    
    post posts_path, params: { post: { title: '', content: '' } }
    
    assert_response :unprocessable_entity
    assert_select '.error', /can't be blank/
  end
  
  test "handles authorization errors" do
    other_users_post = posts(:other_user_post)
    
    get edit_post_path(other_users_post)
    
    assert_redirected_to root_path
    assert_equal 'Access denied', flash[:alert]
  end
end

# test/exceptions/custom_exceptions_test.rb
class CustomExceptionsTest < ActiveSupport::TestCase
  test "PaymentError includes proper error data" do
    error = PaymentError.new('Card declined')
    
    assert_equal 'Card declined', error.message
    assert_equal :payment_required, error.status
    assert_equal 'PAYMENT_ERROR', error.code
  end
  
  test "ApplicationError converts to hash properly" do
    error = ApplicationError.new(message: 'Test error', status: :bad_request, code: 'TEST_ERROR')
    
    expected_hash = {
      error: {
        message: 'Test error',
        code: 'TEST_ERROR',
        status: 400
      }
    }
    
    assert_equal expected_hash, error.to_h
  end
end
```

## References

- [Rails Error Handling](https://guides.rubyonrails.org/action_controller_overview.html#rescue)
- [Exception Handling in Ruby](https://ruby-doc.org/core/Exception.html)
- [Custom Error Pages](https://guides.rubyonrails.org/configuring.html#configuring-action-dispatch)
- [Sentry Rails Guide](https://docs.sentry.io/platforms/ruby/guides/rails/)