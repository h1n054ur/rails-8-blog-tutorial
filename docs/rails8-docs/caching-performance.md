# Caching & Performance Tuning

## Overview

Rails provides multiple caching layers to improve application performance. Understanding and implementing proper caching strategies can dramatically reduce response times and server load.

## Cache Types

### Page Caching
```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  caches_page :index, :show
  
  def index
    @posts = Post.published.includes(:user)
  end
  
  def show
    @post = Post.find(params[:id])
  end
end

# Expire page cache
expire_page action: 'index'
expire_page @post
```

### Action Caching
```ruby
class PostsController < ApplicationController
  caches_action :index, :show, expires_in: 1.hour
  caches_action :show, cache_path: proc { |c| c.params.slice(:id, :page) }
  
  def index
    @posts = Post.published.page(params[:page])
  end
end
```

### Fragment Caching
```erb
<!-- View caching -->
<% cache @post do %>
  <div class="post">
    <h1><%= @post.title %></h1>
    <p><%= @post.content %></p>
  </div>
<% end %>

<!-- Collection caching -->
<% cache @posts do %>
  <% @posts.each do |post| %>
    <% cache post do %>
      <%= render post %>
    <% end %>
  <% end %>
<% end %>

<!-- Conditional caching -->
<% cache [@post, current_user] if should_cache? do %>
  <%= render 'post_content' %>
<% end %>
```

### Low-Level Caching
```ruby
class PostsController < ApplicationController
  def expensive_calculation
    @result = Rails.cache.fetch("expensive_calc_#{params[:id]}", expires_in: 12.hours) do
      # Expensive operation
      perform_complex_calculation(params[:id])
    end
  end
end

# Manual cache operations
Rails.cache.read('key')
Rails.cache.write('key', 'value', expires_in: 1.hour)
Rails.cache.delete('key')
Rails.cache.exist?('key')
Rails.cache.increment('counter')
Rails.cache.decrement('counter')
```

## Cache Stores

### Memory Store
```ruby
# config/environments/development.rb
config.cache_store = :memory_store, { size: 64.megabytes }
```

### File Store
```ruby
# config/environments/development.rb
config.cache_store = :file_store, Rails.root.join('tmp', 'cache')
```

### Redis Store
```ruby
# Gemfile
gem 'redis'

# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  pool_size: 5,
  pool_timeout: 5,
  namespace: 'myapp_cache',
  expires_in: 1.hour
}
```

### Memcached
```ruby
# Gemfile
gem 'dalli'

# config/environments/production.rb
config.cache_store = :mem_cache_store, 'cache1.example.com', 'cache2.example.com'
```

## Database Optimization

### Query Optimization
```ruby
# N+1 queries (bad)
@posts.each { |post| puts post.user.name }

# Eager loading (good)
@posts = Post.includes(:user)
@posts.each { |post| puts post.user.name }

# Preloading multiple associations
@posts = Post.includes(:user, :comments, :tags)

# Select specific fields
@posts = Post.select(:id, :title, :created_at)

# Use pluck for simple data
user_names = User.pluck(:name)
user_emails = User.where(active: true).pluck(:email)
```

### Database Indexes
```ruby
# Migration
class AddIndexesToPosts < ActiveRecord::Migration[7.1]
  def change
    add_index :posts, :user_id
    add_index :posts, [:published, :created_at]
    add_index :posts, :title, unique: true
    add_index :users, :email, unique: true
  end
end
```

### Counter Caches
```ruby
# Migration
class AddPostsCountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :posts_count, :integer, default: 0
    
    # Populate existing data
    User.reset_counters(User.all.pluck(:id), :posts)
  end
end

# Model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

class User < ApplicationRecord
  has_many :posts
end
```

## Performance Monitoring

### Rails Performance Tools
```ruby
# Gemfile
gem 'bullet'              # N+1 query detection
gem 'rack-mini-profiler' # Request profiling
gem 'memory_profiler'    # Memory usage analysis
gem 'stackprof'         # CPU profiling

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
end
```

### Custom Performance Monitoring
```ruby
# app/controllers/concerns/performance_monitoring.rb
module PerformanceMonitoring
  extend ActiveSupport::Concern
  
  included do
    around_action :monitor_performance
  end
  
  private
  
  def monitor_performance
    start_time = Time.current
    memory_before = get_memory_usage
    
    yield
    
    duration = Time.current - start_time
    memory_after = get_memory_usage
    memory_used = memory_after - memory_before
    
    log_performance_metrics(duration, memory_used)
    send_slow_request_alert(duration) if duration > 1.second
  end
  
  def get_memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i
  end
  
  def log_performance_metrics(duration, memory)
    Rails.logger.info "Performance: #{action_name} took #{duration.round(3)}s, used #{memory}KB memory"
  end
  
  def send_slow_request_alert(duration)
    SlowRequestNotifier.notify(
      controller: controller_name,
      action: action_name,
      duration: duration,
      params: params.to_unsafe_h
    )
  end
end
```

## Asset Optimization

### Image Optimization
```ruby
# config/environments/production.rb
config.assets.compress = true
config.assets.css_compressor = :sass
config.assets.js_compressor = :terser

# Image processing
class User < ApplicationRecord
  has_one_attached :avatar
  
  def optimized_avatar
    avatar.variant(
      resize_to_limit: [300, 300],
      format: :webp,
      quality: 80
    )
  end
end
```

### CDN Configuration
```ruby
# config/environments/production.rb
config.asset_host = 'https://cdn.example.com'

# ActionMailer asset host
config.action_mailer.asset_host = 'https://cdn.example.com'

# ActiveStorage URLs
config.active_storage.variant_processor = :mini_magick
```

## Background Processing

### Async Operations
```ruby
# Move expensive operations to background
class PostsController < ApplicationController
  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      # Process in background
      ProcessPostJob.perform_later(@post)
      EmailNotificationJob.perform_later(@post)
      
      redirect_to @post
    else
      render :new
    end
  end
end

# Job implementation
class ProcessPostJob < ApplicationJob
  def perform(post)
    # Generate SEO metadata
    post.update_seo_data
    
    # Process images
    post.process_attached_images
    
    # Update search index
    post.update_search_index
  end
end
```

## HTTP Performance

### Compression
```ruby
# config/application.rb
config.middleware.use Rack::Deflater

# Gzip compression for assets
config.assets.gzip = true
```

### HTTP Caching Headers
```ruby
class ApplicationController < ActionController::Base
  private
  
  def set_cache_headers
    if stale?(last_modified: @resource.updated_at, etag: @resource)
      # Resource hasn't changed, send 304 Not Modified
      return
    end
    
    # Set cache control headers
    expires_in 1.hour, public: true
  end
end

class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    
    # Conditional GET support
    if stale?(@post)
      respond_to do |format|
        format.html
        format.json { render json: @post }
      end
    end
  end
end
```

## Memory Management

### Memory Optimization
```ruby
# Process large datasets in batches
User.find_each(batch_size: 1000) do |user|
  user.process_data
end

# Use pluck instead of loading full objects
email_list = User.active.pluck(:email)

# Stream large responses
class ReportsController < ApplicationController
  def large_csv
    send_data generate_csv_stream, 
              type: 'text/csv',
              filename: 'report.csv',
              stream: true
  end
  
  private
  
  def generate_csv_stream
    Enumerator.new do |yielder|
      yielder << CSV.generate_line(['Name', 'Email'])
      
      User.find_each do |user|
        yielder << CSV.generate_line([user.name, user.email])
      end
    end
  end
end
```

## References

- [Rails Caching Guide](https://guides.rubyonrails.org/caching_with_rails.html)
- [Performance Testing](https://guides.rubyonrails.org/performance_testing.html)
- [Active Record Performance](https://guides.rubyonrails.org/active_record_querying.html#retrieving-objects-from-the-database)