# ActiveStorage & File Uploads

## Overview

ActiveStorage provides file upload and attachment functionality for Rails applications. It supports multiple cloud storage services, image processing, direct uploads, and provides a clean API for handling files.

## Basic Setup

### Installation and Configuration
```bash
# Install ActiveStorage (included by default in Rails)
rails active_storage:install
rails db:migrate

# This creates two tables:
# - active_storage_blobs (file metadata)
# - active_storage_attachments (polymorphic join table)
# - active_storage_variant_records (processed variants)
```

### Storage Configuration
```ruby
# config/storage.yml
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

# Amazon S3
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: us-east-1
  bucket: your-bucket-name
  public: false

# Google Cloud Storage
google:
  service: GCS
  project: your-project
  credentials: <%= Rails.application.credentials.dig(:gcs, :keyfile) %>
  bucket: your-bucket-name
  public: false

# Microsoft Azure
microsoft:
  service: AzureStorage
  storage_account_name: your-account-name
  storage_access_key: <%= Rails.application.credentials.dig(:azure, :storage_access_key) %>
  container: your-container-name
  public: false

# Environment-specific configuration
# config/environments/production.rb
Rails.application.configure do
  config.active_storage.service = :amazon
end

# config/environments/development.rb
Rails.application.configure do
  config.active_storage.service = :local
end
```

## Attachments

### Single File Attachments
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar
  has_one_attached :resume
  
  # Validations
  validates :avatar, content_type: ['image/png', 'image/jpg', 'image/jpeg'],
                    size: { less_than: 5.megabytes }
  
  def avatar_thumbnail
    avatar.variant(resize_to_limit: [150, 150]) if avatar.attached?
  end
end

# app/models/document.rb
class Document < ApplicationRecord
  has_one_attached :file
  
  # Custom validation
  validate :acceptable_file
  
  private
  
  def acceptable_file
    return unless file.attached?
    
    unless file.blob.content_type.start_with?('application/')
      errors.add(:file, 'must be a document')
    end
    
    if file.blob.byte_size > 10.megabytes
      errors.add(:file, 'must be less than 10MB')
    end
  end
end
```

### Multiple File Attachments
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many_attached :images
  has_many_attached :documents
  
  # Validate all images
  validate :validate_images
  
  def primary_image
    images.first
  end
  
  def thumbnail_images
    images.map { |image| image.variant(resize_to_limit: [300, 300]) }
  end
  
  private
  
  def validate_images
    return unless images.attached?
    
    images.each do |image|
      unless image.blob.content_type.start_with?('image/')
        errors.add(:images, 'must be images')
        break
      end
      
      if image.blob.byte_size > 5.megabytes
        errors.add(:images, 'must be less than 5MB each')
        break
      end
    end
    
    if images.count > 10
      errors.add(:images, 'cannot have more than 10 images')
    end
  end
end
```

## File Operations

### Uploading Files
```ruby
# In controllers
class UsersController < ApplicationController
  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'Profile updated successfully'
    else
      render :edit
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:name, :email, :avatar, :resume)
  end
end

class PostsController < ApplicationController
  def create
    @post = Post.new(post_params)
    
    if @post.save
      redirect_to @post
    else
      render :new
    end
  end
  
  private
  
  def post_params
    params.require(:post).permit(:title, :content, images: [], documents: [])
  end
end
```

### Programmatic File Attachment
```ruby
# Attach from file path
user.avatar.attach(
  io: File.open('/path/to/file.jpg'),
  filename: 'avatar.jpg',
  content_type: 'image/jpeg'
)

# Attach from URL
require 'open-uri'
user.avatar.attach(
  io: URI.open('https://example.com/avatar.jpg'),
  filename: 'avatar.jpg',
  content_type: 'image/jpeg'
)

# Attach multiple files
post.images.attach([
  {
    io: File.open('/path/to/image1.jpg'),
    filename: 'image1.jpg',
    content_type: 'image/jpeg'
  },
  {
    io: File.open('/path/to/image2.jpg'),
    filename: 'image2.jpg',
    content_type: 'image/jpeg'
  }
])

# Attach from uploaded file
def attach_from_upload(model, file_param)
  if file_param.present?
    model.file.attach(
      io: file_param.tempfile,
      filename: file_param.original_filename,
      content_type: file_param.content_type
    )
  end
end
```

### File Access and Metadata
```ruby
# Check if file is attached
user.avatar.attached? # => true/false
post.images.attached? # => true/false

# File metadata
if user.avatar.attached?
  user.avatar.filename # => "avatar.jpg"
  user.avatar.content_type # => "image/jpeg"
  user.avatar.byte_size # => 1024000
  user.avatar.checksum # => "abc123..."
  user.avatar.created_at # => DateTime
end

# Download file content
if user.avatar.attached?
  avatar_data = user.avatar.download
  # Process the file data
end

# File URL (for serving)
if user.avatar.attached?
  url_for(user.avatar) # => "/rails/active_storage/blobs/..."
  user.avatar.url # => full URL
end
```

## Image Processing

### Basic Image Variants
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many_attached :images
  
  def thumbnail_variant(image)
    image.variant(resize_to_limit: [150, 150])
  end
  
  def medium_variant(image)
    image.variant(resize_to_limit: [500, 500])
  end
  
  def cropped_variant(image)
    image.variant(
      resize_to_fill: [300, 200],
      crop: "300x200+0+0"
    )
  end
end
```

### Advanced Image Processing
```ruby
# Using ImageMagick operations
class User < ApplicationRecord
  has_one_attached :avatar
  
  def avatar_variants
    return {} unless avatar.attached? && avatar.blob.image?
    
    {
      thumb: avatar.variant(
        resize_to_limit: [100, 100],
        format: :webp,
        quality: 80
      ),
      medium: avatar.variant(
        resize_to_limit: [300, 300],
        format: :webp,
        quality: 85
      ),
      large: avatar.variant(
        resize_to_limit: [800, 800],
        format: :webp,
        quality: 90
      )
    }
  end
  
  # Circular avatar with border
  def circular_avatar
    avatar.variant(
      resize_to_fill: [200, 200],
      extent: "200x200",
      background: "white",
      gravity: "center",
      crop: "200x200+0+0",
      bordercolor: "#cccccc",
      border: "2x2"
    )
  end
end
```

### Custom Image Processing
```ruby
# app/models/concerns/image_processing.rb
module ImageProcessing
  extend ActiveSupport::Concern
  
  def process_image_variants(attachment, variants)
    return unless attachment.attached? && attachment.blob.image?
    
    variants.each do |name, options|
      attachment.variant(options).processed
    end
  end
  
  def generate_responsive_images(attachment)
    return unless attachment.attached? && attachment.blob.image?
    
    sizes = {
      small: { resize_to_limit: [480, nil] },
      medium: { resize_to_limit: [768, nil] },
      large: { resize_to_limit: [1200, nil] },
      xlarge: { resize_to_limit: [1920, nil] }
    }
    
    sizes.transform_values { |options| attachment.variant(options) }
  end
end

# Include in models
class Post < ApplicationRecord
  include ImageProcessing
  has_many_attached :images
  
  after_commit :process_images, on: [:create, :update]
  
  private
  
  def process_images
    images.each do |image|
      ImageProcessingJob.perform_later(image)
    end
  end
end
```

## Forms and Views

### File Upload Forms
```erb
<!-- Single file upload -->
<%= form_with model: @user, local: true do |form| %>
  <div class="field">
    <%= form.label :avatar %>
    <%= form.file_field :avatar, accept: 'image/*' %>
  </div>
  
  <div class="field">
    <%= form.label :resume %>
    <%= form.file_field :resume, accept: '.pdf,.doc,.docx' %>
  </div>
  
  <%= form.submit %>
<% end %>

<!-- Multiple file upload -->
<%= form_with model: @post, local: true do |form| %>
  <div class="field">
    <%= form.label :images %>
    <%= form.file_field :images, multiple: true, accept: 'image/*' %>
  </div>
  
  <div class="field">
    <%= form.label :documents %>
    <%= form.file_field :documents, multiple: true, accept: '.pdf,.doc,.docx' %>
  </div>
  
  <%= form.submit %>
<% end %>

<!-- Drag and drop upload -->
<div class="upload-area" data-controller="file-upload">
  <input type="file" 
         data-file-upload-target="input"
         data-action="change->file-upload#handleFiles"
         multiple 
         accept="image/*" 
         style="display: none;">
  
  <div class="upload-prompt" 
       data-action="click->file-upload#openFileDialog dragover->file-upload#handleDragOver drop->file-upload#handleDrop">
    <p>Click to upload or drag and drop files here</p>
  </div>
  
  <div data-file-upload-target="preview" class="file-preview"></div>
</div>
```

### Displaying Files
```erb
<!-- Display avatar with fallback -->
<div class="user-avatar">
  <% if @user.avatar.attached? %>
    <%= image_tag @user.avatar.variant(resize_to_limit: [150, 150]), 
                  alt: "#{@user.name}'s avatar",
                  class: "avatar" %>
  <% else %>
    <div class="avatar-placeholder">
      <%= @user.name.first %>
    </div>
  <% end %>
</div>

<!-- Display images gallery -->
<div class="image-gallery">
  <% @post.images.each do |image| %>
    <div class="image-item">
      <%= link_to image, target: '_blank' do %>
        <%= image_tag image.variant(resize_to_limit: [300, 300]),
                      alt: "Post image",
                      loading: "lazy" %>
      <% end %>
      
      <div class="image-info">
        <span class="filename"><%= image.filename %></span>
        <span class="filesize"><%= number_to_human_size(image.byte_size) %></span>
      </div>
    </div>
  <% end %>
</div>

<!-- Responsive images -->
<% if @post.featured_image.attached? %>
  <picture>
    <source media="(max-width: 480px)" 
            srcset="<%= url_for(@post.featured_image.variant(resize_to_limit: [480, nil])) %>">
    <source media="(max-width: 768px)" 
            srcset="<%= url_for(@post.featured_image.variant(resize_to_limit: [768, nil])) %>">
    <source media="(max-width: 1200px)" 
            srcset="<%= url_for(@post.featured_image.variant(resize_to_limit: [1200, nil])) %>">
    <%= image_tag @post.featured_image, alt: "Featured image" %>
  </picture>
<% end %>
```

## Direct Uploads

### JavaScript Direct Upload
```erb
<!-- Enable direct uploads -->
<%= form_with model: @post, local: true do |form| %>
  <%= form.file_field :images, 
                      multiple: true, 
                      direct_upload: true,
                      data: { 
                        controller: "direct-upload",
                        action: "direct-upload:progress->direct-upload#progress"
                      } %>
  
  <div data-direct-upload-target="progress" class="upload-progress"></div>
  <%= form.submit %>
<% end %>
```

```javascript
// app/javascript/controllers/direct_upload_controller.js
import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["progress"]
  
  progress(event) {
    const { progress } = event.detail
    this.progressTarget.style.width = `${progress}%`
    this.progressTarget.textContent = `${Math.round(progress)}%`
  }
}
```

### Custom Direct Upload
```javascript
// app/javascript/lib/direct_upload.js
export class CustomDirectUpload {
  constructor(file, url, delegate = {}) {
    this.file = file
    this.url = url
    this.delegate = delegate
  }
  
  create(callback) {
    const upload = new DirectUpload(this.file, this.url, this.delegate)
    
    upload.create((error, blob) => {
      if (error) {
        console.error('Upload failed:', error)
        this.delegate.directUploadDidError?.(error)
      } else {
        console.log('Upload completed:', blob)
        this.delegate.directUploadDidComplete?.(blob)
      }
      
      callback(error, blob)
    })
  }
}

// Usage
const fileInput = document.querySelector('input[type="file"]')
fileInput.addEventListener('change', (event) => {
  Array.from(event.target.files).forEach(file => {
    const upload = new CustomDirectUpload(file, '/rails/active_storage/direct_uploads', {
      directUploadWillCreateBlobWithXHR(xhr) {
        xhr.setRequestHeader('X-CSRF-Token', getCSRFToken())
      },
      
      directUploadDidProgress(event) {
        const progress = (event.loaded / event.total) * 100
        console.log(`Upload progress: ${progress}%`)
      }
    })
    
    upload.create((error, blob) => {
      if (!error) {
        // Add hidden field with blob signed_id
        const hiddenField = document.createElement('input')
        hiddenField.type = 'hidden'
        hiddenField.name = 'post[image_blobs][]'
        hiddenField.value = blob.signed_id
        fileInput.form.appendChild(hiddenField)
      }
    })
  })
})
```

## Background Processing

### Image Processing Jobs
```ruby
# app/jobs/image_processing_job.rb
class ImageProcessingJob < ApplicationJob
  queue_as :image_processing
  
  def perform(attachment_id)
    attachment = ActiveStorage::Attachment.find(attachment_id)
    return unless attachment.blob.image?
    
    # Generate common variants
    variants = {
      thumb: { resize_to_limit: [150, 150] },
      medium: { resize_to_limit: [500, 500] },
      large: { resize_to_limit: [1200, 1200] }
    }
    
    variants.each do |name, options|
      attachment.variant(options).processed
    end
    
    # Update record to indicate processing is complete
    attachment.record.update_column(:images_processed, true) if attachment.record.respond_to?(:images_processed)
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  has_many_attached :images
  
  after_commit :process_images, on: [:create, :update]
  
  private
  
  def process_images
    images.each do |image|
      ImageProcessingJob.perform_later(image.id)
    end
  end
end
```

### File Cleanup Jobs
```ruby
# app/jobs/cleanup_unattached_blobs_job.rb
class CleanupUnattachedBlobsJob < ApplicationJob
  queue_as :cleanup
  
  def perform
    # Remove blobs that have been unattached for more than 24 hours
    ActiveStorage::Blob.unattached.where('created_at < ?', 24.hours.ago).find_each(&:purge)
  end
end

# Schedule with cron
# config/schedule.rb (whenever gem)
every 1.day, at: '2:00 am' do
  runner "CleanupUnattachedBlobsJob.perform_later"
end
```

## File Serving and Security

### Secure File Serving
```ruby
# app/controllers/files_controller.rb
class FilesController < ApplicationController
  before_action :authenticate_user!
  
  def show
    @file = ActiveStorage::Blob.find_signed(params[:signed_id])
    
    # Authorization check
    attachment = @file.attachments.first
    authorize_file_access!(attachment)
    
    # Serve file
    redirect_to url_for(@file)
  end
  
  private
  
  def authorize_file_access!(attachment)
    case attachment.record_type
    when 'User'
      unless attachment.record == current_user || current_user.admin?
        raise Pundit::NotAuthorizedError
      end
    when 'Post'
      unless attachment.record.published? || attachment.record.user == current_user
        raise Pundit::NotAuthorizedError
      end
    end
  end
end
```

### Content Security Policy
```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    # Allow ActiveStorage blobs
    if Rails.env.development?
      policy.img_src :self, :data, "http://localhost:3000"
    else
      policy.img_src :self, :data, "https://your-bucket.s3.amazonaws.com"
    end
  end
end
```

## Testing

### Model Tests
```ruby
# test/models/user_test.rb
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "avatar attachment" do
    user = User.new(name: "Test User")
    
    # Attach test file
    user.avatar.attach(
      io: File.open(Rails.root.join('test', 'fixtures', 'files', 'avatar.jpg')),
      filename: 'avatar.jpg',
      content_type: 'image/jpeg'
    )
    
    assert user.avatar.attached?
    assert_equal 'avatar.jpg', user.avatar.filename.to_s
    assert_equal 'image/jpeg', user.avatar.content_type
  end
  
  test "avatar validation" do
    user = User.new(name: "Test User")
    
    # Test invalid file type
    user.avatar.attach(
      io: StringIO.new("fake content"),
      filename: 'document.txt',
      content_type: 'text/plain'
    )
    
    assert_not user.valid?
    assert_includes user.errors[:avatar], 'must be an image'
  end
end
```

### Integration Tests
```ruby
# test/integration/file_upload_test.rb
require 'test_helper'

class FileUploadTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile
  
  setup do
    @user = users(:one)
    sign_in @user
  end
  
  test "upload avatar" do
    patch user_path(@user), params: {
      user: {
        avatar: fixture_file_upload('avatar.jpg', 'image/jpeg')
      }
    }
    
    assert_redirected_to user_path(@user)
    assert @user.reload.avatar.attached?
  end
  
  test "upload multiple images" do
    post posts_path, params: {
      post: {
        title: 'Test Post',
        content: 'Content',
        images: [
          fixture_file_upload('image1.jpg', 'image/jpeg'),
          fixture_file_upload('image2.jpg', 'image/jpeg')
        ]
      }
    }
    
    post = Post.last
    assert_equal 2, post.images.count
  end
end
```

## Performance Optimization

### Lazy Loading and Caching
```ruby
# Eager load attachments
posts = Post.includes(images_attachments: :blob).limit(10)

# Cache variants
class Post < ApplicationRecord
  has_many_attached :images
  
  def cached_thumbnail(image)
    Rails.cache.fetch("post_#{id}_image_#{image.id}_thumb", expires_in: 1.hour) do
      url_for(image.variant(resize_to_limit: [150, 150]))
    end
  end
end
```

### CDN Configuration
```ruby
# config/environments/production.rb
Rails.application.configure do
  # Use CDN for ActiveStorage
  config.active_storage.variant_processor = :mini_magick
  config.active_storage.resolve_model_to_route = :rails_storage_proxy
  
  # CDN URL
  if ENV['CDN_HOST'].present?
    config.active_storage.url_options = { host: ENV['CDN_HOST'] }
  end
end
```

## References

- [Active Storage Overview](https://guides.rubyonrails.org/active_storage_overview.html)
- [Active Storage API](https://api.rubyonrails.org/classes/ActiveStorage.html)
- [Image Processing Gem](https://github.com/janko/image_processing)
- [Direct Uploads Guide](https://guides.rubyonrails.org/active_storage_overview.html#direct-uploads)