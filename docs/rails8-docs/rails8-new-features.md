# New Rails 8 Features

## Overview

Rails 8 introduces significant improvements focused on modern web development, deployment simplification, and enhanced developer experience. Key themes include simplified deployment, improved asset handling, and better defaults for new applications.

## Major New Features

### 1. Kamal Integration for Deployment

Rails 8 includes Kamal as the default deployment tool, replacing complex deployment setups with a simple, Docker-based solution.

#### Getting Started with Kamal
```bash
# Kamal is included by default in Rails 8
rails new myapp
cd myapp

# Initialize Kamal configuration
kamal init

# Setup and deploy
kamal setup
kamal deploy
```

#### Kamal Configuration
```yaml
# config/deploy.yml
service: myapp
image: myapp

servers:
  web:
    - 192.168.1.100
  job:
    - 192.168.1.101

registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    DB_HOST: 192.168.1.102
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL

accessories:
  db:
    image: postgres:15
    host: 192.168.1.102
    env:
      clear:
        POSTGRES_DB: myapp_production
      secret:
        - POSTGRES_PASSWORD
    files:
      - config/init.sql:/docker-entrypoint-initdb.d/setup.sql
    directories:
      - data:/var/lib/postgresql/data
```

#### Kamal Commands
```bash
# Deploy application
kamal deploy

# Deploy specific role
kamal deploy --roles=web

# Execute commands
kamal app exec "bin/rails console"
kamal app exec --interactive "bin/rails console"

# View logs
kamal app logs
kamal app logs --follow

# Scale services
kamal scale web=3

# Zero-downtime deployment
kamal deploy --skip-push
```

### 2. Propshaft Asset Pipeline

Rails 8 replaces Sprockets with Propshaft as the default asset pipeline for improved performance and simplicity.

#### Propshaft Features
```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Propshaft is enabled by default in Rails 8
    config.assets.pipeline = :propshaft
  end
end
```

#### Asset Organization
```
app/assets/
├── stylesheets/
│   ├── application.css
│   └── components/
├── javascript/
│   ├── application.js
│   └── controllers/
└── images/
    └── logo.png
```

#### Asset Helpers
```erb
<!-- In views -->
<%= stylesheet_link_tag "application" %>
<%= javascript_include_tag "application" %>
<%= image_tag "logo.png" %>

<!-- With integrity checking -->
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
```

### 3. Hotwire as Default

Rails 8 ships with Hotwire (Turbo + Stimulus) enabled by default, providing modern interactivity without complex JavaScript frameworks.

#### Turbo Frame Examples
```erb
<!-- app/views/posts/index.html.erb -->
<turbo-frame id="posts">
  <% @posts.each do |post| %>
    <turbo-frame id="post_<%= post.id %>">
      <%= render post %>
      <%= link_to "Edit", edit_post_path(post) %>
    </turbo-frame>
  <% end %>
</turbo-frame>
```

#### Turbo Stream Actions
```ruby
# app/controllers/posts_controller.rb
def create
  @post = Post.new(post_params)
  
  if @post.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

```erb
<!-- app/views/posts/create.turbo_stream.erb -->
<%= turbo_stream.prepend "posts", partial: "post", locals: { post: @post } %>
<%= turbo_stream.update "new_post_form", partial: "form", locals: { post: Post.new } %>
```

#### Stimulus Controllers
```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static classes = ["hidden"]
  
  toggle() {
    this.contentTarget.classList.toggle(this.hiddenClass)
  }
}
```

```erb
<!-- In views -->
<div data-controller="toggle">
  <button data-action="click->toggle#toggle">Toggle</button>
  <div data-toggle-target="content" data-toggle-hidden-class="hidden">
    Content to toggle
  </div>
</div>
```

### 4. Enhanced SQLite Support

Rails 8 significantly improves SQLite support, making it production-ready for many applications.

#### SQLite Improvements
```ruby
# config/database.yml
production:
  adapter: sqlite3
  database: storage/production.sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  # New SQLite features
  strict_strings: true
  journal_mode: wal
  synchronous: normal
  mmap_size: 134217728 # 128MB
  cache_size: 2000
```

#### SQLite Configuration
```ruby
# config/initializers/sqlite3.rb
if Rails.env.production?
  Rails.application.configure do
    config.active_record.sqlite3.strict_strings_by_default = true
    config.active_record.sqlite3.strict_integers_by_default = true
  end
end
```

### 5. Improved Authentication Generator

Rails 8 includes a built-in authentication generator that creates a complete authentication system.

#### Generate Authentication
```bash
# Generate authentication system
rails generate authentication User

# This creates:
# - User model with password authentication
# - Sessions controller
# - Password reset functionality
# - Email confirmation
# - Views and routes
```

#### Generated User Model
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  
  generates_token_for :password_reset, expires_in: 15.minutes
  generates_token_for :email_confirmation, expires_in: 24.hours
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  normalizes :email, with: ->(email) { email.strip.downcase }
  
  before_validation :set_confirmation_token, on: :create
  
  def confirmed?
    confirmed_at.present?
  end
  
  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end
  
  private
  
  def set_confirmation_token
    self.confirmation_token = SecureRandom.hex(32)
  end
end
```

### 6. Enhanced Generators and Scaffolding

Rails 8 improves generators with better defaults and more configuration options.

#### New Generator Options
```bash
# Generate with specific options
rails generate scaffold Post title:string content:rich_text --css=tailwind

# Generate API resources with versioning
rails generate scaffold api/v1/Post title:string --api --parent=Api::V1

# Generate with custom templates
rails generate controller Posts --template-engine=slim
```

#### Custom Generator Templates
```ruby
# lib/templates/rails/scaffold_controller/controller.rb.tt
class <%= controller_class_name %>Controller < ApplicationController
  before_action :authenticate_user!
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update, :destroy]
  
  # Standard actions with improved error handling
  def index
    @<%= plural_table_name %> = <%= class_name %>.includes(<%= associations.join(', ') %>)
                                              .page(params[:page])
  end
  
  # ... rest of the controller
end
```

### 7. Ruby 3.2+ Features Integration

Rails 8 leverages Ruby 3.2+ features for better performance and developer experience.

#### Data Classes Integration
```ruby
# app/models/concerns/address_value.rb
class AddressValue < Data.define(:street, :city, :state, :zip)
  def full_address
    "#{street}, #{city}, #{state} #{zip}"
  end
end

# Usage in models
class User < ApplicationRecord
  def address
    return nil unless address_data.present?
    
    AddressValue.new(**address_data.symbolize_keys)
  end
  
  def address=(address_value)
    self.address_data = address_value.to_h
  end
end
```

### 8. Improved Development Experience

#### Enhanced Error Pages
Rails 8 includes better error pages with more helpful debugging information and suggestions.

#### Better Console Experience
```ruby
# Enhanced rails console with better formatting
rails console

# New console features
>> User.first
=> #<User id: 1, email: "user@example.com", created_at: "2023-12-01 10:00:00.000000000 +0000">

# Improved query logging
User Load (0.2ms)  SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?  [["LIMIT", 1]]
```

### 9. Solid Queue Integration

Rails 8 includes Solid Queue as an alternative to Redis-based job queues.

#### Solid Queue Setup
```ruby
# config/application.rb
config.active_job.queue_adapter = :solid_queue

# Generates migration for queue tables
rails generate solid_queue:install
rails db:migrate
```

#### Job Configuration
```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  # Solid Queue specific options
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError
end
```

### 10. Enhanced Credentials Management

#### Environment-Specific Credentials
```bash
# Generate environment-specific credentials
rails credentials:edit --environment=staging
rails credentials:edit --environment=production

# This creates:
# config/credentials/staging.yml.enc
# config/credentials/production.yml.enc
```

#### Accessing Credentials
```ruby
# In application code
Rails.application.credentials.dig(:database, :password)
Rails.application.credentials.secret_key_base

# Environment-specific
Rails.application.credentials.dig(:production, :api_key)
```

## Migration from Rails 7

### Upgrading to Rails 8
```bash
# Update Gemfile
gem 'rails', '~> 8.0'

# Update application
bundle update rails
rails app:update

# Generate new defaults
rails generate config_file

# Update asset pipeline (if needed)
# Follow upgrade guide for Propshaft migration
```

### Breaking Changes
- Propshaft replaces Sprockets by default
- Some deprecated methods removed
- Updated minimum Ruby version requirement
- Changes in default configurations

### Compatibility Notes
```ruby
# config/application.rb
# For gradual migration, you can still use Sprockets
config.assets.pipeline = :sprockets  # If needed

# Or enable new features selectively
config.load_defaults 8.0, except: [:asset_pipeline]
```

## Best Practices for Rails 8

### 1. Leverage Hotwire
```erb
<!-- Use Turbo Frames for partial page updates -->
<turbo-frame id="user_profile">
  <%= render @user %>
</turbo-frame>

<!-- Use Turbo Streams for real-time updates -->
<%= turbo_stream_from @post %>
```

### 2. Optimize SQLite for Production
```ruby
# config/initializers/sqlite3.rb
if defined?(SQLite3)
  SQLite3::Database.new(":memory:").execute("PRAGMA optimize")
end
```

### 3. Use Kamal for Simple Deployment
```yaml
# Keep deploy.yml simple and environment-specific
service: <%= ENV['APP_NAME'] %>
image: <%= ENV['APP_NAME'] %>

servers:
  - <%= ENV['PRODUCTION_SERVER'] %>

env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
```

## References

- [Rails 8.0 Release Notes](https://edgeguides.rubyonrails.org/8_0_release_notes.html)
- [Kamal Documentation](https://kamal-deploy.org/)
- [Propshaft Guide](https://github.com/rails/propshaft)
- [Hotwire Documentation](https://hotwired.dev/)
- [Solid Queue Documentation](https://github.com/rails/solid_queue)