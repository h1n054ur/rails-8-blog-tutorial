# Credentials & Encrypted Secrets

## Overview

Rails provides encrypted credentials and secrets management to securely store sensitive information like API keys, database passwords, and other configuration data. This system replaces the deprecated `secrets.yml` approach with a more secure encrypted solution.

## Encrypted Credentials

### Basic Setup
```bash
# Generate master key and credentials file (done automatically in new Rails apps)
rails credentials:edit

# This creates:
# - config/master.key (DO NOT commit to version control)
# - config/credentials.yml.enc (encrypted, safe to commit)

# Set master key as environment variable in production
export RAILS_MASTER_KEY=your_master_key_here
```

### Credentials File Structure
```yaml
# config/credentials.yml.enc (decrypted content)
# Edit with: rails credentials:edit

secret_key_base: your_secret_key_base_here

# Database
database:
  username: myapp_user
  password: secure_database_password

# Third-party APIs
stripe:
  publishable_key: pk_test_...
  secret_key: sk_test_...
  webhook_secret: whsec_...

sendgrid:
  api_key: SG.xxx
  username: apikey

aws:
  access_key_id: AKIA...
  secret_access_key: xxx...
  region: us-east-1
  bucket: myapp-production

redis:
  url: redis://localhost:6379/0

jwt:
  secret: your_jwt_secret_here

oauth:
  google:
    client_id: your_google_client_id
    client_secret: your_google_client_secret
  facebook:
    app_id: your_facebook_app_id
    app_secret: your_facebook_app_secret
  github:
    client_id: your_github_client_id
    client_secret: your_github_client_secret

# External services
elasticsearch:
  host: https://elasticsearch.example.com
  username: elastic
  password: changeme

monitoring:
  sentry_dsn: https://xxx@sentry.io/xxx
  newrelic_license_key: xxx

# Email
smtp:
  host: smtp.gmail.com
  port: 587
  username: your_email@gmail.com
  password: your_app_password

# Encryption keys
encryption:
  primary_key: 32_byte_base64_encoded_key
  deterministic_key: another_32_byte_key
  key_derivation_salt: 32_byte_salt
```

### Accessing Credentials
```ruby
# In application code
Rails.application.credentials.secret_key_base
Rails.application.credentials.database[:password]
Rails.application.credentials.stripe[:secret_key]
Rails.application.credentials.aws[:access_key_id]

# Using dig for nested access
Rails.application.credentials.dig(:oauth, :google, :client_id)

# With fallback values
api_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV['STRIPE_SECRET_KEY']

# Check if credential exists
if Rails.application.credentials.sendgrid
  ActionMailer::Base.smtp_settings = {
    user_name: Rails.application.credentials.sendgrid[:username],
    password: Rails.application.credentials.sendgrid[:api_key],
    domain: 'yourdomain.com',
    address: 'smtp.sendgrid.net',
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }
end
```

### Configuration Usage
```ruby
# config/database.yml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  database: myapp_production
  username: <%= Rails.application.credentials.dig(:database, :username) %>
  password: <%= Rails.application.credentials.dig(:database, :password) %>

# config/environments/production.rb
Rails.application.configure do
  # Use credentials for configuration
  config.active_storage.service = :amazon
  
  # Mailer configuration
  config.action_mailer.smtp_settings = {
    address: Rails.application.credentials.dig(:smtp, :host),
    port: Rails.application.credentials.dig(:smtp, :port),
    user_name: Rails.application.credentials.dig(:smtp, :username),
    password: Rails.application.credentials.dig(:smtp, :password),
    authentication: :plain,
    enable_starttls_auto: true
  }
end

# config/storage.yml
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: <%= Rails.application.credentials.dig(:aws, :region) %>
  bucket: <%= Rails.application.credentials.dig(:aws, :bucket) %>
```

## Environment-Specific Credentials

### Per-Environment Credentials
```bash
# Create environment-specific credentials
rails credentials:edit --environment=staging
rails credentials:edit --environment=production

# This creates:
# config/credentials/staging.yml.enc
# config/credentials/staging.key
# config/credentials/production.yml.enc  
# config/credentials/production.key
```

### Environment-Specific Structure
```yaml
# config/credentials/production.yml.enc
database:
  username: myapp_production_user
  password: super_secure_production_password

aws:
  access_key_id: AKIA_PRODUCTION_KEY
  secret_access_key: production_secret_key
  bucket: myapp-production-bucket

stripe:
  publishable_key: pk_live_...
  secret_key: sk_live_...

# config/credentials/staging.yml.enc  
database:
  username: myapp_staging_user
  password: staging_password

aws:
  access_key_id: AKIA_STAGING_KEY
  secret_access_key: staging_secret_key
  bucket: myapp-staging-bucket

stripe:
  publishable_key: pk_test_...
  secret_key: sk_test_...
```

### Accessing Environment Credentials
```ruby
# Rails automatically loads environment-specific credentials
# when RAILS_ENV matches the environment name

# In production environment:
Rails.application.credentials.database[:password]  # Uses production credentials

# Explicit environment access
Rails.application.credentials.config_for(:database, env: 'staging')

# Fallback pattern
def database_config
  Rails.application.credentials.database || 
  Rails.application.credentials.config_for(:database, env: Rails.env)
end
```

## Initializers and Configuration

### Service Configuration
```ruby
# config/initializers/stripe.rb
if Rails.application.credentials.stripe
  Stripe.api_key = Rails.application.credentials.stripe[:secret_key]
  Stripe.publishable_key = Rails.application.credentials.stripe[:publishable_key]
end

# config/initializers/aws.rb
if Rails.application.credentials.aws
  Aws.config.update({
    region: Rails.application.credentials.aws[:region],
    credentials: Aws::Credentials.new(
      Rails.application.credentials.aws[:access_key_id],
      Rails.application.credentials.aws[:secret_access_key]
    )
  })
end

# config/initializers/sentry.rb
if Rails.application.credentials.dig(:monitoring, :sentry_dsn)
  Sentry.init do |config|
    config.dsn = Rails.application.credentials.monitoring[:sentry_dsn]
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.environment = Rails.env
  end
end
```

### Conditional Configuration
```ruby
# config/initializers/redis.rb
redis_config = Rails.application.credentials.redis

if redis_config
  Redis.current = Redis.new(url: redis_config[:url])
elsif ENV['REDIS_URL']
  Redis.current = Redis.new(url: ENV['REDIS_URL'])
else
  Redis.current = Redis.new(host: 'localhost', port: 6379, db: 0)
end

# config/initializers/elasticsearch.rb
if Rails.application.credentials.elasticsearch
  config = Rails.application.credentials.elasticsearch
  
  Elasticsearch::Model.client = Elasticsearch::Client.new(
    host: config[:host],
    user: config[:username],
    password: config[:password],
    transport_options: {
      ssl: { verify: Rails.env.production? }
    }
  )
end
```

## Helper Methods and Patterns

### Credential Helper Module
```ruby
# app/models/concerns/credential_helper.rb
module CredentialHelper
  extend ActiveSupport::Concern
  
  class_methods do
    def credential(key_path, fallback: nil)
      value = Rails.application.credentials.dig(*Array(key_path))
      value.presence || fallback
    end
    
    def required_credential(key_path)
      credential(key_path) || 
        raise("Missing required credential: #{Array(key_path).join('.')}")
    end
    
    def credential_present?(key_path)
      credential(key_path).present?
    end
  end
end

# Usage
class PaymentService
  include CredentialHelper
  
  def initialize
    @api_key = required_credential([:stripe, :secret_key])
    @webhook_secret = credential([:stripe, :webhook_secret], fallback: ENV['STRIPE_WEBHOOK_SECRET'])
  end
  
  def self.available?
    credential_present?([:stripe, :secret_key])
  end
end
```

### Service Configuration Classes
```ruby
# app/services/app_config.rb
class AppConfig
  def self.database
    @database ||= OpenStruct.new(
      Rails.application.credentials.database || {}
    )
  end
  
  def self.aws
    @aws ||= OpenStruct.new(
      Rails.application.credentials.aws || {}
    )
  end
  
  def self.stripe
    @stripe ||= OpenStruct.new(
      Rails.application.credentials.stripe || {}
    )
  end
  
  def self.oauth
    @oauth ||= OpenStruct.new(
      Rails.application.credentials.oauth || {}
    )
  end
  
  def self.reload!
    instance_variables.each { |var| remove_instance_variable(var) }
  end
end

# Usage
AppConfig.stripe.secret_key
AppConfig.aws.bucket
AppConfig.oauth.google.client_id
```

## Development and Testing

### Development Credentials
```yaml
# config/credentials/development.yml.enc
database:
  username: myapp_dev
  password: development_password

stripe:
  publishable_key: pk_test_development
  secret_key: sk_test_development

aws:
  access_key_id: AKIA_DEV_KEY
  secret_access_key: dev_secret_key
  bucket: myapp-development-bucket

# Fake credentials for development
oauth:
  google:
    client_id: fake_google_client_id
    client_secret: fake_google_client_secret
```

### Test Configuration
```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  # Mock credentials for testing
  def with_credentials(credentials_hash)
    original_credentials = Rails.application.credentials
    
    mock_credentials = OpenStruct.new(credentials_hash)
    def mock_credentials.dig(*keys)
      keys.reduce(self) { |obj, key| obj&.send(key) }
    end
    
    Rails.application.stub(:credentials, mock_credentials) do
      yield
    end
  end
end

# Usage in tests
class PaymentServiceTest < ActiveSupport::TestCase
  test "processes payment with valid credentials" do
    with_credentials(stripe: { secret_key: 'sk_test_123' }) do
      service = PaymentService.new
      assert service.process_payment(amount: 1000)
    end
  end
  
  test "raises error without credentials" do
    with_credentials({}) do
      assert_raises(RuntimeError) { PaymentService.new }
    end
  end
end
```

### Environment Variable Fallbacks
```ruby
# app/models/concerns/configurable.rb
module Configurable
  extend ActiveSupport::Concern
  
  class_methods do
    def config_value(credential_path, env_var: nil, default: nil)
      # Try credentials first
      value = Rails.application.credentials.dig(*credential_path)
      
      # Fall back to environment variable
      value ||= ENV[env_var.to_s] if env_var
      
      # Use default if nothing found
      value || default
    end
  end
end

# Usage
class ApiClient
  include Configurable
  
  API_KEY = config_value(
    [:external_api, :key], 
    env_var: :EXTERNAL_API_KEY,
    default: 'development_key'
  )
  
  BASE_URL = config_value(
    [:external_api, :base_url],
    env_var: :EXTERNAL_API_URL,
    default: 'https://api.example.com'
  )
end
```

## Security Best Practices

### Master Key Management
```bash
# Production deployment with environment variable
export RAILS_MASTER_KEY="your_master_key_here"

# Or use a key file (ensure proper permissions)
echo "your_master_key_here" > config/master.key
chmod 600 config/master.key

# For Docker deployments
# Use secrets management (Docker Swarm, Kubernetes secrets)
docker run -e RAILS_MASTER_KEY="$MASTER_KEY" myapp

# For Kubernetes
kubectl create secret generic rails-master-key \
  --from-literal=RAILS_MASTER_KEY="your_master_key_here"
```

### Key Rotation
```ruby
# config/initializers/credentials_rotation.rb
class CredentialsRotation
  def self.rotate_master_key!
    # Generate new master key
    new_key = SecureRandom.hex(32)
    
    # Decrypt with old key
    old_credentials = Rails.application.credentials.config
    
    # Re-encrypt with new key
    Rails.application.credentials.write(old_credentials.to_yaml)
    
    # Update master key
    File.write(Rails.root.join('config/master.key'), new_key)
    
    puts "Master key rotated. New key: #{new_key}"
    puts "Update your production environment with the new key."
  end
end

# Usage (in Rails console or rake task)
# CredentialsRotation.rotate_master_key!
```

### Audit and Monitoring
```ruby
# app/models/concerns/credential_auditing.rb
module CredentialAuditing
  extend ActiveSupport::Concern
  
  included do
    after_initialize :audit_credential_access, if: :production?
  end
  
  private
  
  def audit_credential_access
    return unless defined?(Rails.application.credentials)
    
    # Log credential access for security monitoring
    Rails.logger.info "Credential access from #{self.class.name}"
    
    # Send to security monitoring service
    SecurityMonitor.log_event(
      type: 'credential_access',
      class: self.class.name,
      timestamp: Time.current
    )
  end
  
  def production?
    Rails.env.production?
  end
end
```

## CI/CD Integration

### GitHub Actions
```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
          
      - name: Setup test credentials
        run: |
          echo "${{ secrets.RAILS_MASTER_KEY }}" > config/master.key
          
      - name: Run tests
        env:
          RAILS_ENV: test
        run: |
          bundle exec rails test

# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy to production
        env:
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
        run: |
          # Your deployment script
          ./deploy.sh
```

### Kamal Deployment
```yaml
# config/deploy.yml
service: myapp
image: myapp

servers:
  - 192.168.1.100

env:
  secret:
    - RAILS_MASTER_KEY

# Kamal will automatically use RAILS_MASTER_KEY from environment
```

### Docker Integration
```dockerfile
# Dockerfile
FROM ruby:3.2

WORKDIR /app

# Copy credentials (encrypted file is safe)
COPY config/credentials.yml.enc config/

# Master key will be provided as environment variable
ENV RAILS_MASTER_KEY=""

# Rest of Dockerfile...
```

## Backup and Recovery

### Credential Backup Strategy
```ruby
# lib/tasks/credentials.rake
namespace :credentials do
  desc "Backup encrypted credentials"
  task :backup => :environment do
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_dir = Rails.root.join('tmp', 'credentials_backup', timestamp)
    FileUtils.mkdir_p(backup_dir)
    
    # Copy encrypted files (safe to backup)
    Dir.glob(Rails.root.join('config', 'credentials*.yml.enc')).each do |file|
      FileUtils.cp(file, backup_dir)
    end
    
    puts "Credentials backed up to: #{backup_dir}"
  end
  
  desc "Validate all credentials"
  task :validate => :environment do
    begin
      Rails.application.credentials.config
      puts "✓ Default credentials valid"
    rescue => e
      puts "✗ Default credentials invalid: #{e.message}"
    end
    
    Dir.glob(Rails.root.join('config', 'credentials', '*.yml.enc')).each do |file|
      env = File.basename(file, '.yml.enc')
      begin
        Rails.application.credentials.config_for(env.to_sym)
        puts "✓ #{env} credentials valid"
      rescue => e
        puts "✗ #{env} credentials invalid: #{e.message}"
      end
    end
  end
end
```

## Migration from Secrets

### Converting from secrets.yml
```ruby
# lib/tasks/migrate_secrets.rake
namespace :credentials do
  desc "Migrate from secrets.yml to credentials"
  task :migrate_from_secrets => :environment do
    secrets_file = Rails.root.join('config', 'secrets.yml')
    
    if File.exist?(secrets_file)
      secrets = YAML.load_file(secrets_file)
      
      # Convert to credentials format
      credentials_data = {}
      
      secrets.each do |env, config|
        credentials_data[env] = config
      end
      
      # Write to credentials
      Rails.application.credentials.write(credentials_data.to_yaml)
      
      puts "Secrets migrated to credentials successfully!"
      puts "You can now remove config/secrets.yml"
    else
      puts "No secrets.yml file found"
    end
  end
end
```

## References

- [Rails Credentials Guide](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Encrypted Credentials](https://guides.rubyonrails.org/configuring.html#credentials-yml-enc)
- [Environment Security](https://guides.rubyonrails.org/configuring.html#configuring-a-database)
- [Security Best Practices](https://guides.rubyonrails.org/security.html)