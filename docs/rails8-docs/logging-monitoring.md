# Logging & Monitoring

## Overview

Rails provides comprehensive logging and monitoring capabilities to track application performance, debug issues, and maintain system health. This includes built-in logging, custom loggers, and integration with monitoring services.

## Rails Logging

### Log Levels
```ruby
# Available log levels (in order of severity)
Rails.logger.debug "Debug information"
Rails.logger.info "General information"
Rails.logger.warn "Warning message"
Rails.logger.error "Error occurred"
Rails.logger.fatal "Fatal error"

# Check current log level
Rails.logger.level # => 0 (debug), 1 (info), 2 (warn), 3 (error), 4 (fatal)

# Set log level
Rails.logger.level = :warn
```

### Environment Configuration
```ruby
# config/environments/development.rb
Rails.application.configure do
  config.log_level = :debug
  config.log_formatter = ::Logger::Formatter.new
  config.colorize_logging = true
end

# config/environments/production.rb
Rails.application.configure do
  config.log_level = :info
  config.log_formatter = JSONLogFormatter.new
  config.logger = ActiveSupport::Logger.new(STDOUT)
end

# config/environments/test.rb
Rails.application.configure do
  config.log_level = :warn
  config.logger = Logger.new(nil) # Silent logging
end
```

### Custom Log Formatters
```ruby
# lib/json_log_formatter.rb
class JSONLogFormatter < Logger::Formatter
  def call(severity, timestamp, progname, msg)
    {
      timestamp: timestamp.iso8601,
      level: severity,
      message: msg,
      progname: progname,
      pid: Process.pid,
      thread: Thread.current.object_id
    }.to_json + "\n"
  end
end

# lib/structured_log_formatter.rb
class StructuredLogFormatter < Logger::Formatter
  def call(severity, timestamp, progname, msg)
    "[#{timestamp}] #{severity} #{progname}: #{msg}\n"
  end
end
```

## Application Logging

### Controller Logging
```ruby
class ApplicationController < ActionController::Base
  before_action :log_request_info
  after_action :log_response_info
  
  private
  
  def log_request_info
    Rails.logger.info {
      {
        event: 'request_started',
        method: request.method,
        path: request.path,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        user_id: current_user&.id,
        session_id: session.id
      }.to_json
    }
  end
  
  def log_response_info
    Rails.logger.info {
      {
        event: 'request_completed',
        status: response.status,
        duration: request_duration,
        allocations: object_allocations
      }.to_json
    }
  end
  
  def request_duration
    Time.current - @request_start_time if @request_start_time
  end
end

class PostsController < ApplicationController
  def create
    Rails.logger.info "Creating post for user #{current_user.id}"
    
    @post = current_user.posts.build(post_params)
    
    if @post.save
      Rails.logger.info "Post #{@post.id} created successfully"
      redirect_to @post
    else
      Rails.logger.warn "Post creation failed: #{@post.errors.full_messages}"
      render :new
    end
  rescue => e
    Rails.logger.error "Post creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
```

### Model Logging
```ruby
class User < ApplicationRecord
  after_create :log_user_creation
  after_update :log_important_changes
  
  private
  
  def log_user_creation
    Rails.logger.info {
      {
        event: 'user_created',
        user_id: id,
        email: email,
        created_at: created_at
      }.to_json
    }
  end
  
  def log_important_changes
    if saved_change_to_email?
      Rails.logger.warn {
        {
          event: 'user_email_changed',
          user_id: id,
          old_email: email_before_last_save,
          new_email: email
        }.to_json
      }
    end
  end
end
```

### Service Logging
```ruby
class PaymentService
  include ActiveSupport::Configurable
  
  def initialize
    @logger = Rails.logger
  end
  
  def process_payment(order)
    @logger.info "Processing payment for order #{order.id}"
    
    begin
      result = payment_gateway.charge(
        amount: order.total,
        source: order.payment_token
      )
      
      if result.success?
        @logger.info "Payment successful for order #{order.id}"
        order.mark_as_paid!
      else
        @logger.error "Payment failed for order #{order.id}: #{result.error}"
        order.mark_as_failed!(result.error)
      end
      
      result
    rescue => e
      @logger.error "Payment processing exception for order #{order.id}: #{e.message}"
      @logger.error e.backtrace.join("\n")
      raise
    end
  end
end
```

## Tagged Logging

### Request Tagging
```ruby
# config/application.rb
config.log_tags = [
  :request_id,
  :remote_ip,
  -> request { "User: #{request.session[:user_id]}" },
  lambda { |request|
    if request.headers['X-API-Key'].present?
      "API: #{request.headers['X-API-Key'][0..8]}..."
    end
  }
]

# Custom tagged logging
class ApplicationController < ActionController::Base
  around_action :tag_logs
  
  private
  
  def tag_logs
    Rails.logger.tagged(
      "#{controller_name}##{action_name}",
      "User:#{current_user&.id || 'anonymous'}"
    ) do
      yield
    end
  end
end
```

### Manual Tagging
```ruby
def complex_operation
  Rails.logger.tagged("ComplexOp", "Batch:#{batch_id}") do
    Rails.logger.info "Starting complex operation"
    
    items.each_with_index do |item, index|
      Rails.logger.tagged("Item:#{index}") do
        Rails.logger.debug "Processing item #{item.id}"
        process_item(item)
      end
    end
    
    Rails.logger.info "Complex operation completed"
  end
end
```

## Performance Monitoring

### Request Timing
```ruby
# app/controllers/concerns/request_timing.rb
module RequestTiming
  extend ActiveSupport::Concern
  
  included do
    before_action :start_timer
    after_action :log_timing
  end
  
  private
  
  def start_timer
    @request_start = Time.current
  end
  
  def log_timing
    duration = Time.current - @request_start
    
    Rails.logger.info {
      {
        event: 'request_timing',
        controller: controller_name,
        action: action_name,
        duration_ms: (duration * 1000).round(2),
        slow_request: duration > 1.0
      }.to_json
    }
    
    # Alert on slow requests
    if duration > 2.0
      SlowRequestAlert.notify(
        controller: "#{controller_name}##{action_name}",
        duration: duration,
        params: params.to_unsafe_h
      )
    end
  end
end
```

### Database Query Monitoring
```ruby
# config/initializers/query_monitoring.rb
ActiveSupport::Notifications.subscribe 'sql.active_record' do |name, started, finished, unique_id, data|
  duration = finished - started
  
  if duration > 0.1 # Log queries taking more than 100ms
    Rails.logger.warn {
      {
        event: 'slow_query',
        duration_ms: (duration * 1000).round(2),
        sql: data[:sql],
        name: data[:name],
        connection_id: data[:connection_id]
      }.to_json
    }
  end
end

# Custom query logging
class QueryLogger
  def self.log_query(sql, duration)
    Rails.logger.info {
      {
        event: 'database_query',
        sql: sql,
        duration_ms: duration,
        timestamp: Time.current.iso8601
      }.to_json
    }
  end
end
```

## Error Tracking

### Exception Logging
```ruby
class ApplicationController < ActionController::Base
  rescue_from StandardError, with: :handle_exception
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  
  private
  
  def handle_exception(exception)
    error_id = SecureRandom.uuid
    
    Rails.logger.error {
      {
        event: 'application_error',
        error_id: error_id,
        exception_class: exception.class.name,
        message: exception.message,
        backtrace: exception.backtrace,
        user_id: current_user&.id,
        request_id: request.uuid,
        params: params.to_unsafe_h
      }.to_json
    }
    
    # Send to error tracking service
    ErrorTracker.notify(exception, {
      error_id: error_id,
      user_id: current_user&.id,
      extra: { params: params.to_unsafe_h }
    })
    
    render json: { error: 'Internal server error', error_id: error_id }, 
           status: :internal_server_error
  end
end
```

### Sentry Integration
```ruby
# Gemfile
gem 'sentry-ruby'
gem 'sentry-rails'

# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.environment = Rails.env
  config.release = ENV['APP_VERSION']
  
  # Performance monitoring
  config.traces_sample_rate = 0.1
  
  # Filter sensitive data
  config.before_send = lambda do |event, hint|
    # Remove sensitive parameters
    if event.request&.data
      event.request.data.delete('password')
      event.request.data.delete('password_confirmation')
    end
    event
  end
end

# Usage
begin
  risky_operation
rescue => e
  Sentry.capture_exception(e, {
    tags: { component: 'payment' },
    extra: { order_id: @order.id }
  })
  raise
end
```

## Health Checks

### Application Health
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def show
    health_status = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version,
      checks: {
        database: database_health,
        redis: redis_health,
        storage: storage_health,
        external_apis: external_api_health
      }
    }
    
    overall_status = health_status[:checks].values.all? ? :ok : :service_unavailable
    
    Rails.logger.info "Health check: #{overall_status}"
    
    render json: health_status, status: overall_status
  end
  
  private
  
  def database_health
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue => e
    Rails.logger.error "Database health check failed: #{e.message}"
    false
  end
  
  def redis_health
    Redis.current.ping == 'PONG'
  rescue => e
    Rails.logger.error "Redis health check failed: #{e.message}"
    false
  end
  
  def storage_health
    ActiveStorage::Blob.service.exist?('health_check')
  rescue => e
    Rails.logger.error "Storage health check failed: #{e.message}"
    false
  end
  
  def external_api_health
    # Check critical external services
    response = HTTParty.get('https://api.external-service.com/health', timeout: 5)
    response.success?
  rescue => e
    Rails.logger.error "External API health check failed: #{e.message}"
    false
  end
end
```

## Metrics Collection

### Custom Metrics
```ruby
# app/services/metrics_collector.rb
class MetricsCollector
  def self.increment(metric_name, tags = {})
    Rails.logger.info {
      {
        event: 'metric_increment',
        metric: metric_name,
        tags: tags,
        timestamp: Time.current.to_f
      }.to_json
    }
    
    # Send to metrics service
    MetricsService.increment(metric_name, tags: tags)
  end
  
  def self.timing(metric_name, duration, tags = {})
    Rails.logger.info {
      {
        event: 'metric_timing',
        metric: metric_name,
        duration_ms: duration,
        tags: tags,
        timestamp: Time.current.to_f
      }.to_json
    }
    
    MetricsService.timing(metric_name, duration, tags: tags)
  end
  
  def self.gauge(metric_name, value, tags = {})
    MetricsService.gauge(metric_name, value, tags: tags)
  end
end

# Usage in controllers
class PostsController < ApplicationController
  def create
    start_time = Time.current
    
    @post = current_user.posts.build(post_params)
    
    if @post.save
      MetricsCollector.increment('posts.created', { user_type: current_user.account_type })
      MetricsCollector.timing('posts.creation_time', Time.current - start_time)
      redirect_to @post
    else
      MetricsCollector.increment('posts.creation_failed')
      render :new
    end
  end
end
```

### Memory and Performance Metrics
```ruby
# config/initializers/performance_monitoring.rb
ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  
  Rails.logger.info {
    {
      event: 'action_performance',
      controller: event.payload[:controller],
      action: event.payload[:action],
      duration: event.duration,
      view_runtime: event.payload[:view_runtime],
      db_runtime: event.payload[:db_runtime],
      allocations: event.payload[:allocations] || 0
    }.to_json
  }
end

# Memory usage tracking
class MemoryMonitor
  def self.log_memory_usage
    memory_usage = `ps -o rss= -p #{Process.pid}`.to_i
    
    Rails.logger.info {
      {
        event: 'memory_usage',
        memory_kb: memory_usage,
        pid: Process.pid,
        timestamp: Time.current.to_f
      }.to_json
    }
    
    # Alert if memory usage is high
    if memory_usage > 500_000 # 500MB
      Rails.logger.warn "High memory usage: #{memory_usage}KB"
    end
  end
end
```

## Log Analysis

### Log Parsing
```ruby
# lib/log_analyzer.rb
class LogAnalyzer
  def self.analyze_slow_requests(log_file)
    slow_requests = []
    
    File.foreach(log_file) do |line|
      if line.include?('request_timing')
        data = JSON.parse(line.split(' ', 4).last)
        
        if data['duration_ms'] > 1000 # Requests taking more than 1 second
          slow_requests << {
            controller_action: "#{data['controller']}##{data['action']}",
            duration: data['duration_ms'],
            timestamp: data['timestamp']
          }
        end
      end
    end
    
    slow_requests.sort_by { |req| req[:duration] }.reverse
  end
  
  def self.error_summary(log_file)
    errors = Hash.new(0)
    
    File.foreach(log_file) do |line|
      if line.include?('application_error')
        data = JSON.parse(line.split(' ', 4).last)
        errors[data['exception_class']] += 1
      end
    end
    
    errors
  end
end
```

### Logrotate Configuration
```bash
# /etc/logrotate.d/rails-app
/path/to/app/log/*.log {
  daily
  missingok
  rotate 30
  compress
  delaycompress
  notifempty
  sharedscripts
  postrotate
    systemctl reload nginx
  endscript
}
```

## References

- [Rails Debugging Guide](https://guides.rubyonrails.org/debugging_rails_applications.html)
- [Active Support Notifications](https://guides.rubyonrails.org/active_support_instrumentation.html)
- [Rails Logging Guide](https://guides.rubyonrails.org/debugging_rails_applications.html#the-logger)
- [Sentry Rails Integration](https://docs.sentry.io/platforms/ruby/guides/rails/)