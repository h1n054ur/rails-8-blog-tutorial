# Upgrading Rails Versions

## Overview

Upgrading Rails requires careful planning and testing to ensure application stability. This guide covers the upgrade process, common issues, and best practices for migrating between Rails versions.

## Pre-Upgrade Preparation

### Assessment and Planning
```bash
# Check current Rails version
rails --version

# Check gem compatibility
bundle outdated

# Review deprecation warnings
rails runner "Rails.application.deprecators.each(&:debug)"

# Run full test suite
rails test
rails test:system
```

### Backup Strategy
```bash
# Backup database
pg_dump myapp_production > backup_$(date +%Y%m%d).sql

# Backup application
tar -czf app_backup_$(date +%Y%m%d).tar.gz /path/to/app

# Create git branch for upgrade
git checkout -b rails-upgrade-8
git push -u origin rails-upgrade-8
```

## Rails 8 Upgrade Process

### Step-by-Step Upgrade
```ruby
# 1. Update Gemfile
# Gemfile
gem 'rails', '~> 8.0.0'

# Update related gems
gem 'sprockets-rails', '>= 3.4.0'  # If using Sprockets
gem 'importmap-rails', '>= 1.0'     # For import maps
gem 'turbo-rails', '>= 1.0'         # For Turbo
gem 'stimulus-rails', '>= 1.0'       # For Stimulus
```

```bash
# 2. Update gems
bundle update rails

# 3. Run Rails update task
rails app:update

# 4. Review and merge configuration changes
# Check config files that were updated
```

### Configuration Updates
```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Load Rails 8 defaults
    config.load_defaults 8.0
    
    # Gradually enable new features
    # config.load_defaults 8.0, except: [:action_cable_connection_id]
  end
end

# config/environments/production.rb
Rails.application.configure do
  # New Rails 8 asset pipeline (Propshaft)
  config.assets.pipeline = :propshaft
  
  # Or keep Sprockets if needed
  # config.assets.pipeline = :sprockets
end
```

### Database Migrations
```bash
# Generate new Rails configurations
rails generate config_file

# Run any new migrations
rails db:migrate

# Update schema format if needed
rails db:schema:dump
```

## Common Upgrade Issues

### Deprecation Warnings
```ruby
# Before (deprecated)
Rails.application.secrets.secret_key_base

# After (Rails 8)
Rails.application.credentials.secret_key_base

# Before (deprecated)
config.force_ssl = true

# After (Rails 8)
config.assume_ssl = true
config.force_ssl = true
```

### Asset Pipeline Changes
```javascript
// Update import statements for Propshaft
// Before (Sprockets)
//= require rails-ujs
//= require turbo
//= require_tree .

// After (Propshaft with importmap)
import "@hotwired/turbo-rails"
import "controllers"
```

### JavaScript and CSS Changes
```bash
# Install new JavaScript dependencies
yarn add @hotwired/turbo-rails @hotwired/stimulus

# Update package.json build script
# package.json
{
  "scripts": {
    "build": "esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds"
  }
}
```

### Model and Controller Updates
```ruby
# Update strong parameters for new attributes
class PostsController < ApplicationController
  private
  
  def post_params
    # Add new permitted parameters
    params.require(:post).permit(
      :title, :content, :published,
      :meta_description,  # New in Rails 8
      tags_attributes: [:id, :name, :_destroy]
    )
  nend
end

# Update model validations
class User < ApplicationRecord
  # New Rails 8 validation syntax
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  
  # Update enum syntax if needed
  enum :status, { active: 0, inactive: 1, suspended: 2 }
end
```

## Testing After Upgrade

### Comprehensive Testing
```bash
# Run full test suite
rails test
rails test:system

# Check for deprecation warnings
RAILS_ENABLE_TEST_LOG=1 rails test

# Performance testing
rails test:benchmark

# Security testing
bundle audit
```

### Manual Testing Checklist
```ruby
# Create test checklist
class UpgradeTestChecklist
  CRITICAL_FEATURES = [
    'User authentication and authorization',
    'Payment processing',
    'File uploads and downloads',
    'Email delivery',
    'Background job processing',
    'API endpoints',
    'Third-party integrations'
  ].freeze
  
  def self.generate_test_plan
    CRITICAL_FEATURES.each do |feature|
      puts "☐ Test #{feature}"
      puts "  - Happy path scenarios"
      puts "  - Error conditions"
      puts "  - Performance impact"
      puts
    end
  end
end
```

## Gradual Migration Strategy

### Feature Flag Approach
```ruby
# Use feature flags for new Rails 8 features
class ApplicationController < ActionController::Base
  private
  
  def use_new_asset_pipeline?
    Rails.env.development? || 
    current_user&.beta_tester? || 
    params[:new_assets] == 'true'
  end
end

# Conditional asset loading
# app/views/layouts/application.html.erb
<% if use_new_asset_pipeline? %>
  <%= javascript_include_tag "application", defer: true %>
<% else %>
  <%= javascript_include_tag "application-legacy" %>
<% end %>
```

### Parallel Implementation
```ruby
# Run old and new implementations side by side
class PaymentService
  def process_payment(order)
    if Rails.application.config.use_new_payment_flow
      process_payment_v2(order)
    else
      process_payment_v1(order)
    end
  end
  
  private
  
  def process_payment_v1(order)
    # Legacy implementation
  end
  
  def process_payment_v2(order)
    # New Rails 8 optimized implementation
  end
end
```

## Performance Optimization

### Rails 8 Performance Features
```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Enable Rails 8 performance features
    config.active_record.query_log_tags_enabled = true
    config.active_record.cache_query_log_tags = true
    
    # Optimize asset delivery
    config.assets.compile = false
    config.assets.digest = true
    
    # Enable new caching features
    config.cache_classes = true
    config.eager_load = true
  end
end

# Use new Rails 8 caching improvements
class PostsController < ApplicationController
  def index
    @posts = Rails.cache.fetch(
      "posts/index/#{cache_key}", 
      expires_in: 15.minutes,
      race_condition_ttl: 10.seconds  # New in Rails 8
    ) do
      Post.published.includes(:user, :tags).limit(20)
    end
  end
end
```

## Database Considerations

### Schema Changes
```ruby
# Update database configuration for Rails 8
# config/database.yml
production:
  adapter: postgresql
  prepared_statements: true    # Improved in Rails 8
  advisory_locks: true         # New feature
  pool_size: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  checkout_timeout: 5
  
# Add new indexes for Rails 8 optimizations
class AddRails8Indexes < ActiveRecord::Migration[8.0]
  def change
    # Optimize common queries
    add_index :users, [:active, :created_at]
    add_index :posts, [:published, :featured, :created_at]
    
    # Add partial indexes
    add_index :posts, :user_id, where: "published = true"
  end
end
```

## Security Updates

### Rails 8 Security Features
```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Enhanced security features
    config.force_ssl = true
    config.ssl_options = {
      hsts: {
        expires: 1.year,
        subdomains: true,
        preload: true
      }
    }
    
    # Content Security Policy improvements
    config.content_security_policy do |policy|
      policy.default_src :self
      policy.script_src :self, :unsafe_inline, 'https://cdn.jsdelivr.net'
      policy.upgrade_insecure_requests true  # New in Rails 8
    end
  end
end

# Update authentication handling
class ApplicationController < ActionController::Base
  # Enhanced CSRF protection
  protect_from_forgery with: :exception, prepend: true
  
  # New session security features
  before_action :verify_session_authenticity
  
  private
  
  def verify_session_authenticity
    # Additional session validation
    reset_session if session_expired? || session_hijacked?
  end
end
```

## Rollback Strategy

### Rollback Plan
```ruby
# Create rollback script
#!/bin/bash
# rollback.sh

echo "Rolling back Rails upgrade..."

# 1. Restore previous Gemfile
git checkout HEAD~1 -- Gemfile Gemfile.lock

# 2. Restore configuration files
git checkout HEAD~1 -- config/

# 3. Restore database if needed
# psql myapp_production < backup_before_upgrade.sql

# 4. Bundle install
bundle install

# 5. Restart application
sudo systemctl restart myapp

echo "Rollback completed"
```

### Monitoring After Upgrade
```ruby
# Enhanced monitoring for Rails 8
class UpgradeMonitor
  def self.check_health
    {
      rails_version: Rails.version,
      response_time: check_response_time,
      error_rate: check_error_rate,
      memory_usage: check_memory_usage,
      database_health: check_database_health,
      cache_hit_rate: check_cache_performance
    }
  end
  
  def self.alert_if_issues
    health = check_health
    
    if health[:error_rate] > 5.0
      AlertService.critical("High error rate after Rails upgrade: #{health[:error_rate]}%")
    end
    
    if health[:response_time] > 2000
      AlertService.warning("Slow response times after upgrade: #{health[:response_time]}ms")
    end
  end
end
```

## Documentation Updates

### Update Documentation
```markdown
# Update README.md
## Requirements
- Ruby 3.2+
- Rails 8.0+
- PostgreSQL 12+
- Redis 6+

## Installation
```bash
bundle install
rails db:setup
yarn install
```

## New Features in Rails 8
- Propshaft asset pipeline
- Enhanced performance
- Improved security features
- Better development experience
```

### Update Deployment Documentation
```yaml
# Update CI/CD configuration
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
          
      - name: Run tests
        run: |
          bundle exec rails test
          bundle exec rails test:system
          
      - name: Deploy with Kamal
        run: |
          kamal deploy
```

## Post-Upgrade Optimization

### Performance Tuning
```ruby
# Optimize for Rails 8
class ApplicationController < ActionController::Base
  # Use new Rails 8 caching features
  caches_action :index, expires_in: 1.hour, cache_path: proc {
    [request.protocol, request.host_with_port, request.fullpath, current_user&.cache_key]
  }
  
  # Optimize database queries
  def index
    @posts = Post.includes(:user, :tags)
                .where(published: true)
                .order(created_at: :desc)
                .limit(per_page)
                .offset(offset)
  end
end
```

## References

- [Rails 8.0 Release Notes](https://edgeguides.rubyonrails.org/8_0_release_notes.html)
- [Rails Upgrade Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Rails Performance Guide](https://guides.rubyonrails.org/performance_testing.html)