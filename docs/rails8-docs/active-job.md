# ActiveJob & Background Processing

## Overview

ActiveJob provides a unified interface for background job processing in Rails. It works with multiple queuing backends and allows you to run jobs asynchronously, improving application performance and user experience.

## Basic Job Structure

### Creating Jobs
```bash
# Generate a job
rails generate job ProcessPayment

# Generate job with arguments
rails generate job SendEmail user_id:integer template:string
```

### Job Class Structure
```ruby
# app/jobs/process_payment_job.rb
class ProcessPaymentJob < ApplicationJob
  queue_as :payments
  
  # Retry configuration
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  retry_on PaymentGatewayError, wait: 30.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError
  
  def perform(order_id, payment_method)
    order = Order.find(order_id)
    
    # Process payment logic
    result = PaymentProcessor.charge(
      amount: order.total,
      method: payment_method,
      order_id: order.id
    )
    
    if result.success?
      order.mark_as_paid!
      OrderMailer.payment_confirmation(order).deliver_now
    else
      order.mark_as_failed!(result.error_message)
      raise PaymentProcessingError, result.error_message
    end
  end
end
```

### Job Inheritance
```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  # Global configuration for all jobs
  queue_as :default
  
  # Global retry logic
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError
  
  # Global callbacks
  before_perform :set_current_tenant
  after_perform :cleanup_temp_files
  around_perform :benchmark_job
  
  private
  
  def set_current_tenant
    Current.tenant = arguments.first.tenant if arguments.first.respond_to?(:tenant)
  end
  
  def cleanup_temp_files
    # Clean up any temporary files created during job execution
  end
  
  def benchmark_job
    start_time = Time.current
    yield
    duration = Time.current - start_time
    Rails.logger.info "Job #{self.class.name} completed in #{duration.round(3)}s"
  end
end
```

## Queueing Jobs

### Immediate Execution
```ruby
# Execute job immediately (synchronously)
ProcessPaymentJob.perform_now(order.id, 'credit_card')

# Execute job in background (asynchronously)
ProcessPaymentJob.perform_later(order.id, 'credit_card')

# Schedule job for later
ProcessPaymentJob.set(wait: 1.hour).perform_later(order.id, 'credit_card')
ProcessPaymentJob.set(wait_until: Date.tomorrow.noon).perform_later(order.id, 'credit_card')

# Set priority (higher numbers = higher priority)
ProcessPaymentJob.set(priority: 10).perform_later(order.id, 'credit_card')

# Set custom queue
ProcessPaymentJob.set(queue: :high_priority).perform_later(order.id, 'credit_card')
```

### Bulk Enqueuing
```ruby
# Enqueue multiple jobs efficiently
orders = Order.pending_payment
ProcessPaymentJob.perform_bulk(orders.map { |order| [order.id, 'credit_card'] })

# Enqueue with different options
jobs_data = orders.map do |order|
  {
    arguments: [order.id, 'credit_card'],
    queue: order.priority_customer? ? 'high_priority' : 'default',
    priority: order.priority_customer? ? 10 : 0
  }
end
ProcessPaymentJob.perform_bulk(jobs_data)
```

## Queue Configuration

### Queue Adapters
```ruby
# config/application.rb
class Application < Rails::Application
  # Built-in adapters
  config.active_job.queue_adapter = :async        # In-memory (development)
  config.active_job.queue_adapter = :inline       # Immediate execution
  config.active_job.queue_adapter = :test         # Testing
  
  # External adapters (require gems)
  config.active_job.queue_adapter = :sidekiq      # Redis-based
  config.active_job.queue_adapter = :resque       # Redis-based
  config.active_job.queue_adapter = :delayed_job  # Database-based
  config.active_job.queue_adapter = :solid_queue  # Rails 8 default
end

# Environment-specific configuration
# config/environments/production.rb
Rails.application.configure do
  config.active_job.queue_adapter = :sidekiq
end

# config/environments/development.rb
Rails.application.configure do
  config.active_job.queue_adapter = :async
end

# config/environments/test.rb
Rails.application.configure do
  config.active_job.queue_adapter = :test
end
```

### Queue Names and Priorities
```ruby
# config/application.rb
Rails.application.configure do
  # Define queue names with priorities
  config.active_job.queue_name_prefix = Rails.env
  config.active_job.queue_name_delimiter = '_'
  
  # Queue mapping
  config.active_job.queue_names = {
    critical: 'critical_queue',
    high: 'high_priority_queue',
    default: 'default_queue',
    low: 'low_priority_queue'
  }
end

# Job with specific queue
class CriticalJob < ApplicationJob
  queue_as :critical
end

class ReportGenerationJob < ApplicationJob
  queue_as :low
end

# Dynamic queue assignment
class NotificationJob < ApplicationJob
  queue_as do
    case user.subscription_tier
    when 'premium' then :high
    when 'basic' then :default
    else :low
    end
  end
  
  def perform(user, message)
    # Send notification
  end
end
```

## Sidekiq Integration

### Sidekiq Setup
```ruby
# Gemfile
gem 'sidekiq'
gem 'sidekiq-web'  # Web UI
gem 'sidekiq-cron' # Scheduled jobs (optional)

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
  
  # Configure job retry
  config.death_handlers << lambda do |job, _ex|
    SidekiqJobFailureNotifier.call(job)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
end

# Set job concurrency
Sidekiq.configure_server do |config|
  config.concurrency = 5
end
```

### Sidekiq Configuration File
```yaml
# config/sidekiq.yml
:concurrency: 10
:timeout: 25
:verbose: false

:queues:
  - critical
  - high_priority
  - default
  - low_priority

production:
  :concurrency: 25

staging:
  :concurrency: 15

development:
  :concurrency: 5
```

### Running Sidekiq
```bash
# Start Sidekiq
bundle exec sidekiq

# With specific configuration
bundle exec sidekiq -C config/sidekiq.yml

# Process specific queues
bundle exec sidekiq -q critical -q high_priority -q default

# With custom concurrency
bundle exec sidekiq -c 20

# In production with systemd
sudo systemctl start sidekiq
sudo systemctl enable sidekiq
```

### Sidekiq Web UI
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Protect with authentication
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  
  # Or with basic auth
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
  end
  mount Sidekiq::Web => '/sidekiq'
end
```

## Solid Queue (Rails 8)

### Solid Queue Setup
```ruby
# Gemfile (included by default in Rails 8)
gem 'solid_queue'

# Generate and run migrations
rails generate solid_queue:install
rails db:migrate

# Configuration
# config/queue.yml
production:
  dispatcher:
    batch_size: 500
    concurrency_maintenance_interval: 600
    recurring_schedule:
      cleanup_finished_jobs:
        command: CleanupJob.perform_later
        schedule: "0 1 * * *"  # Daily at 1 AM
  
  workers:
    - queues: [critical, high_priority]
      threads: 5
    - queues: [default]
      threads: 3
    - queues: [low_priority]
      threads: 1
```

### Running Solid Queue
```bash
# Start Solid Queue worker
bin/jobs

# With specific configuration
bin/jobs --queue high_priority --threads 10

# In production
bundle exec rake solid_queue:start
```

## Job Patterns and Examples

### Email Jobs
```ruby
# app/jobs/email_job.rb
class EmailJob < ApplicationJob
  queue_as :emails
  
  retry_on Net::SMTPServerBusy, wait: 30.seconds, attempts: 5
  discard_on Net::SMTPFatalError
  
  def perform(user_id, template, **options)
    user = User.find(user_id)
    
    case template
    when 'welcome'
      UserMailer.welcome(user).deliver_now
    when 'notification'
      UserMailer.notification(user, options[:message]).deliver_now
    when 'weekly_digest'
      UserMailer.weekly_digest(user).deliver_now
    end
  end
end

# Usage
EmailJob.perform_later(user.id, 'welcome')
EmailJob.perform_later(user.id, 'notification', message: 'New feature available!')
```

### File Processing Jobs
```ruby
# app/jobs/image_processing_job.rb
class ImageProcessingJob < ApplicationJob
  queue_as :image_processing
  
  def perform(attachment_id)
    attachment = ActiveStorage::Attachment.find(attachment_id)
    return unless attachment.blob.image?
    
    # Generate thumbnails
    variants = {
      thumb: { resize_to_limit: [150, 150] },
      medium: { resize_to_limit: [500, 500] },
      large: { resize_to_limit: [1200, 1200] }
    }
    
    variants.each do |name, options|
      attachment.variant(options).processed
      Rails.logger.info "Generated #{name} variant for #{attachment.filename}"
    end
    
    # Update record
    attachment.record.update!(image_processed: true)
  end
end

# Triggered after upload
class Document < ApplicationRecord
  has_one_attached :file
  
  after_commit :process_image, if: -> { file.attached? && file.blob.image? }
  
  private
  
  def process_image
    ImageProcessingJob.perform_later(file.id)
  end
end
```

### Batch Processing Jobs
```ruby
# app/jobs/bulk_update_job.rb
class BulkUpdateJob < ApplicationJob
  queue_as :bulk_operations
  
  def perform(model_class, ids, attributes)
    model_class.constantize.where(id: ids).update_all(attributes)
    
    # Log the operation
    Rails.logger.info "Updated #{ids.count} #{model_class} records"
  end
end

# app/jobs/report_generation_job.rb
class ReportGenerationJob < ApplicationJob
  queue_as :reports
  
  def perform(report_id)
    report = Report.find(report_id)
    report.update!(status: 'generating')
    
    begin
      # Generate report data
      data = ReportGenerator.new(report).generate
      
      # Create and attach file
      csv_data = CSV.generate do |csv|
        csv << data.first.keys  # Headers
        data.each { |row| csv << row.values }
      end
      
      report.file.attach(
        io: StringIO.new(csv_data),
        filename: "#{report.name}_#{Date.current}.csv",
        content_type: 'text/csv'
      )
      
      report.update!(status: 'completed', completed_at: Time.current)
      ReportMailer.ready(report).deliver_now
      
    rescue StandardError => e
      report.update!(status: 'failed', error_message: e.message)
      raise
    end
  end
end
```

### Periodic Jobs
```ruby
# app/jobs/cleanup_job.rb
class CleanupJob < ApplicationJob
  queue_as :maintenance
  
  def perform
    # Clean up old temporary files
    cleanup_temp_files
    
    # Remove expired sessions
    cleanup_expired_sessions
    
    # Archive old records
    archive_old_records
  end
  
  private
  
  def cleanup_temp_files
    Dir.glob(Rails.root.join('tmp', 'uploads', '*')).each do |file|
      File.delete(file) if File.mtime(file) < 24.hours.ago
    end
  end
  
  def cleanup_expired_sessions
    ActiveRecord::SessionStore::Session.where('updated_at < ?', 30.days.ago).delete_all
  end
  
  def archive_old_records
    OldRecord.where('created_at < ?', 1.year.ago).find_in_batches do |batch|
      ArchiveOldRecordsJob.perform_later(batch.map(&:id))
    end
  end
end

# Schedule with cron (using sidekiq-cron)
# config/initializers/sidekiq.rb
require 'sidekiq/cron'

Sidekiq::Cron::Job.create(
  name: 'Daily Cleanup',
  cron: '0 2 * * *',  # 2 AM daily
  class: 'CleanupJob'
)
```

## Job Callbacks and Instrumentation

### Job Callbacks
```ruby
class ProcessOrderJob < ApplicationJob
  before_perform :check_order_status
  after_perform :send_confirmation
  around_perform :with_error_handling
  
  def perform(order_id)
    @order = Order.find(order_id)
    # Process order logic
  end
  
  private
  
  def check_order_status
    raise "Order already processed" if @order&.processed?
  end
  
  def send_confirmation
    OrderMailer.processed(@order).deliver_now if @order.processed?
  end
  
  def with_error_handling
    yield
  rescue StandardError => e
    ErrorTracker.notify(e, order_id: @order&.id)
    raise
  end
end
```

### Job Instrumentation
```ruby
# config/initializers/job_instrumentation.rb
ActiveSupport::Notifications.subscribe 'perform.active_job' do |name, started, finished, unique_id, data|
  job = data[:job]
  duration = finished - started
  
  Rails.logger.info "Job #{job.class.name} took #{duration.round(3)}s"
  
  # Send metrics to monitoring service
  MetricsService.timing("job.#{job.class.name.underscore}.duration", duration)
  MetricsService.increment("job.#{job.class.name.underscore}.performed")
  
  # Alert on slow jobs
  if duration > 30.seconds
    SlackNotifier.alert("Slow job: #{job.class.name} took #{duration.round(2)}s")
  end
end

# Track job failures
ActiveSupport::Notifications.subscribe 'retry.active_job' do |name, started, finished, unique_id, data|
  job = data[:job]
  error = data[:error]
  
  Rails.logger.warn "Job #{job.class.name} failed: #{error.message}"
  MetricsService.increment("job.#{job.class.name.underscore}.retried")
end
```

## Testing Jobs

### Job Tests
```ruby
# test/jobs/process_payment_job_test.rb
require 'test_helper'

class ProcessPaymentJobTest < ActiveJob::TestCase
  setup do
    @order = orders(:pending)
  end
  
  test "processes payment successfully" do
    # Mock payment processor
    PaymentProcessor.stub :charge, OpenStruct.new(success?: true) do
      assert_performed_jobs 1 do
        ProcessPaymentJob.perform_later(@order.id, 'credit_card')
      end
      
      @order.reload
      assert @order.paid?
    end
  end
  
  test "handles payment failure" do
    PaymentProcessor.stub :charge, OpenStruct.new(success?: false, error_message: 'Card declined') do
      assert_raises PaymentProcessingError do
        ProcessPaymentJob.perform_now(@order.id, 'credit_card')
      end
      
      @order.reload
      assert @order.failed?
    end
  end
  
  test "job is queued correctly" do
    assert_enqueued_with(job: ProcessPaymentJob, args: [@order.id, 'credit_card']) do
      ProcessPaymentJob.perform_later(@order.id, 'credit_card')
    end
  end
  
  test "job uses correct queue" do
    job = ProcessPaymentJob.new(@order.id, 'credit_card')
    assert_equal 'payments', job.queue_name
  end
end
```

### Integration Tests
```ruby
# test/integration/job_integration_test.rb
require 'test_helper'

class JobIntegrationTest < ActionDispatch::IntegrationTest
  test "order processing workflow" do
    # Perform jobs inline for testing
    perform_enqueued_jobs do
      order = orders(:pending)
      
      # Trigger job through controller action
      post process_order_path(order)
      
      # Verify job was performed and order updated
      order.reload
      assert order.processed?
      assert_performed_jobs 1, only: ProcessOrderJob
    end
  end
end
```

## Performance and Monitoring

### Job Performance Tips
```ruby
class OptimizedJob < ApplicationJob
  def perform(record_ids)
    # Process in batches to avoid memory issues
    record_ids.in_groups_of(100, false) do |batch_ids|
      records = Record.where(id: batch_ids).includes(:associations)
      
      records.each do |record|
        process_record(record)
      end
      
      # Give other jobs a chance
      sleep(0.1) if batch_ids.count == 100
    end
  end
  
  private
  
  def process_record(record)
    # Efficient processing logic
  end
end
```

### Job Monitoring
```ruby
# app/models/job_stats.rb
class JobStats
  def self.queue_sizes
    case Rails.configuration.active_job.queue_adapter
    when :sidekiq
      Sidekiq::Stats.new.queues
    when :solid_queue
      SolidQueue::Job.group(:queue_name).count
    end
  end
  
  def self.failed_jobs_count
    case Rails.configuration.active_job.queue_adapter
    when :sidekiq
      Sidekiq::Stats.new.failed
    when :solid_queue
      SolidQueue::Job.failed.count
    end
  end
end

# Health check endpoint
class HealthController < ApplicationController
  def jobs
    stats = {
      queue_sizes: JobStats.queue_sizes,
      failed_jobs: JobStats.failed_jobs_count,
      processing: processing_jobs_count
    }
    
    render json: stats
  end
  
  private
  
  def processing_jobs_count
    # Implementation depends on adapter
  end
end
```

## References

- [Active Job Basics](https://guides.rubyonrails.org/active_job_basics.html)
- [Sidekiq Documentation](https://sidekiq.org/)
- [Solid Queue Documentation](https://github.com/rails/solid_queue)
- [Action Mailer Basics](https://guides.rubyonrails.org/action_mailer_basics.html)