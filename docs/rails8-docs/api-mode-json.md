# API Mode & JSON Serialization

## Overview

Rails API mode provides a streamlined framework for building JSON APIs by removing middleware and functionality specific to browser applications. It's optimized for mobile backends, microservices, and single-page applications.

## Creating API-Only Applications

### Generating API Applications
```bash
# Create new API-only Rails application
rails new my_api --api

# Add API mode to existing application
# Remove from config/application.rb:
# require 'rails/all'

# Add specific components:
require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_cable/railtie'
require 'rails/test_unit/railtie'

# Configure API mode
module MyApi
  class Application < Rails::Application
    config.api_only = true
  end
end
```

### API Application Structure
```
my_api/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── api/
│   │       └── v1/
│   │           ├── base_controller.rb
│   │           ├── users_controller.rb
│   │           └── posts_controller.rb
│   ├── models/
│   ├── serializers/
│   ├── jobs/
│   └── mailers/
├── config/
└── db/
```

## Controllers

### API Base Controller
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request
  
  before_action :authenticate_request
  before_action :set_default_format
  
  private
  
  def current_user
    @current_user ||= authenticate_with_token
  end
  
  def authenticate_request
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end
  
  def authenticate_with_token
    authenticate_with_http_token do |token, options|
      User.find_by(api_token: token)
    end
  end
  
  def set_default_format
    request.format = :json
  end
  
  # Error responses
  def not_found(exception)
    render json: { error: 'Resource not found' }, status: :not_found
  end
  
  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation failed',
      details: exception.record.errors
    }, status: :unprocessable_entity
  end
  
  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
```

### Versioned API Controllers
```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ApplicationController
  # Version-specific functionality
  
  private
  
  def render_success(data = {}, status = :ok)
    render json: {
      success: true,
      data: data,
      meta: response_meta
    }, status: status
  end
  
  def render_error(message, status = :bad_request, details = {})
    render json: {
      success: false,
      error: {
        message: message,
        details: details
      },
      meta: response_meta
    }, status: status
  end
  
  def response_meta
    {
      version: 'v1',
      timestamp: Time.current.iso8601,
      request_id: request.uuid
    }
  end
end

# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [:show, :update, :destroy]
  
  def index
    @users = User.includes(:posts).page(params[:page]).per(params[:per_page] || 20)
    
    render_success(
      users: UserSerializer.new(@users).serializable_hash[:data],
      pagination: pagination_meta(@users)
    )
  end
  
  def show
    render_success(
      user: UserSerializer.new(@user, include: [:posts]).serializable_hash[:data]
    )
  end
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      render_success(
        user: UserSerializer.new(@user).serializable_hash[:data]
      ), :created
    else
      render_error('User creation failed', :unprocessable_entity, @user.errors)
    end
  end
  
  def update
    if @user.update(user_params)
      render_success(
        user: UserSerializer.new(@user).serializable_hash[:data]
      )
    else
      render_error('User update failed', :unprocessable_entity, @user.errors)
    end
  end
  
  def destroy
    @user.destroy
    head :no_content
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
  
  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      per_page: collection.limit_value,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
end
```

## JSON Serialization

### Active Model Serializers
```ruby
# Gemfile
gem 'active_model_serializers'

# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :created_at, :updated_at
  
  # Conditional attributes
  attribute :admin?, key: :is_admin, if: :show_admin_status?
  
  # Custom attributes
  attribute :full_name
  attribute :avatar_url
  
  # Associations
  has_many :posts, serializer: PostSerializer
  has_one :profile, serializer: ProfileSerializer
  
  # Links
  link :self do
    api_v1_user_url(object)
  end
  
  def full_name
    "#{object.first_name} #{object.last_name}".strip
  end
  
  def avatar_url
    if object.avatar.attached?
      Rails.application.routes.url_helpers.url_for(object.avatar)
    else
      nil
    end
  end
  
  private
  
  def show_admin_status?
    current_user&.admin?
  end
end

# app/serializers/post_serializer.rb
class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :content, :published, :created_at, :updated_at
  
  belongs_to :user, serializer: UserSerializer
  has_many :comments, serializer: CommentSerializer
  
  # Conditional inclusion
  attribute :view_count, if: :show_analytics?
  
  def content
    if scope&.can?(:read_full_content, object)
      object.content
    else
      object.content.truncate(100)
    end
  end
  
  private
  
  def show_analytics?
    scope&.admin? || object.user == scope
  end
end
```

### JSONAPI::Serializer (Fast JSON API)
```ruby
# Gemfile
gem 'jsonapi-serializer'

# app/serializers/user_serializer.rb
class UserSerializer
  include JSONAPI::Serializer
  
  attributes :name, :email, :created_at
  
  # Conditional attributes
  attribute :admin do |user, params|
    user.admin? if params[:show_admin]
  end
  
  # Custom attributes
  attribute :full_name do |user|
    "#{user.first_name} #{user.last_name}".strip
  end
  
  # Relationships
  has_many :posts
  has_one :profile
  
  # Links
  link :self do |user|
    "/api/v1/users/#{user.id}"
  end
end

# Usage in controllers
def index
  users = User.all
  
  render json: UserSerializer.new(
    users,
    include: [:posts, :profile],
    params: { show_admin: current_user.admin? }
  ).serializable_hash
end
```

### Custom JSON Serialization
```ruby
# app/models/user.rb
class User < ApplicationRecord
  def as_json(options = {})
    super(options.merge(
      only: [:id, :name, :email, :created_at],
      methods: [:full_name, :avatar_url],
      include: {
        posts: {
          only: [:id, :title, :published, :created_at]
        }
      }
    ))
  end
  
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def avatar_url
    avatar.attached? ? Rails.application.routes.url_helpers.url_for(avatar) : nil
  end
end

# Custom serialization method
class User < ApplicationRecord
  def self.serialize_for_api(users, current_user: nil)
    users.map do |user|
      {
        id: user.id,
        name: user.name,
        email: user.email,
        full_name: user.full_name,
        avatar_url: user.avatar_url,
        is_admin: user.admin?,
        created_at: user.created_at.iso8601,
        posts_count: user.posts.count,
        # Conditional fields
        email_visible: current_user&.admin? || user == current_user
      }
    end
  end
end
```

## Authentication

### Token-Based Authentication
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token
  
  def regenerate_api_token!
    regenerate_api_token
    save!
  end
end

# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_request, only: [:login, :register]
  
  def login
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      render_success(
        user: UserSerializer.new(user).serializable_hash[:data],
        token: user.api_token
      )
    else
      render_error('Invalid credentials', :unauthorized)
    end
  end
  
  def register
    user = User.new(user_params)
    
    if user.save
      render_success(
        user: UserSerializer.new(user).serializable_hash[:data],
        token: user.api_token
      ), :created
    else
      render_error('Registration failed', :unprocessable_entity, user.errors)
    end
  end
  
  def logout
    current_user.regenerate_api_token!
    head :no_content
  end
  
  def me
    render_success(
      user: UserSerializer.new(current_user).serializable_hash[:data]
    )
  end
  
  private
  
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
```

### JWT Authentication
```ruby
# Gemfile
gem 'jwt'

# app/services/jwt_service.rb
class JwtService
  SECRET_KEY = Rails.application.secret_key_base
  
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end
  
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    raise ExceptionHandler::InvalidToken, e.message
  end
end

# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < Api::V1::BaseController
  def login
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      token = JwtService.encode(user_id: user.id)
      
      render_success(
        user: UserSerializer.new(user).serializable_hash[:data],
        token: token
      )
    else
      render_error('Invalid credentials', :unauthorized)
    end
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  private
  
  def current_user
    @current_user ||= user_from_token
  end
  
  def user_from_token
    return nil unless auth_header.present?
    
    token = auth_header.split(' ').last
    decoded = JwtService.decode(token)
    User.find(decoded[:user_id])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end
  
  def auth_header
    request.headers['Authorization']
  end
end
```

## API Versioning

### URL Versioning
```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users
      resources :posts
      post 'auth/login', to: 'auth#login'
      post 'auth/register', to: 'auth#register'
      delete 'auth/logout', to: 'auth#logout'
    end
    
    namespace :v2 do
      resources :users
      resources :posts
    end
  end
end
```

### Header Versioning
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :set_api_version
  
  private
  
  def set_api_version
    @api_version = request.headers['API-Version'] || 'v1'
  end
  
  def render_with_version(data, status = :ok)
    case @api_version
    when 'v1'
      render json: Api::V1::ResponseFormatter.format(data), status: status
    when 'v2'
      render json: Api::V2::ResponseFormatter.format(data), status: status
    else
      render json: { error: 'Unsupported API version' }, status: :not_acceptable
    end
  end
end

# app/services/api/v1/response_formatter.rb
module Api::V1
  class ResponseFormatter
    def self.format(data)
      {
        success: true,
        data: data,
        version: 'v1'
      }
    end
  end
end
```

## Pagination

### Pagination Implementation
```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ApplicationController
  protected
  
  def paginate(collection)
    page = params[:page]&.to_i || 1
    per_page = [(params[:per_page]&.to_i || 20), 100].min  # Max 100 per page
    
    collection.page(page).per(per_page)
  end
  
  def pagination_meta(collection)
    {
      pagination: {
        current_page: collection.current_page,
        per_page: collection.limit_value,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        next_page: collection.next_page,
        prev_page: collection.prev_page
      }
    }
  end
  
  def render_paginated_collection(collection, serializer_class, **options)
    paginated = paginate(collection)
    
    render json: {
      data: serializer_class.new(paginated, options).serializable_hash[:data],
      meta: pagination_meta(paginated)
    }
  end
end

# Usage
class Api::V1::PostsController < Api::V1::BaseController
  def index
    posts = Post.published.includes(:user)
    render_paginated_collection(posts, PostSerializer, include: [:user])
  end
end
```

### Cursor-Based Pagination
```ruby
# app/controllers/concerns/cursor_pagination.rb
module CursorPagination
  extend ActiveSupport::Concern
  
  def cursor_paginate(collection, cursor_field: :id, limit: 20)
    limit = [limit, 100].min  # Max 100 per page
    
    if params[:after].present?
      collection = collection.where("#{cursor_field} > ?", params[:after])
    end
    
    if params[:before].present?
      collection = collection.where("#{cursor_field} < ?", params[:before])
    end
    
    records = collection.limit(limit + 1).to_a
    has_more = records.size > limit
    
    if has_more
      records = records.take(limit)
    end
    
    {
      data: records,
      meta: {
        has_more: has_more,
        next_cursor: has_more ? records.last.send(cursor_field) : nil,
        prev_cursor: records.first&.send(cursor_field)
      }
    }
  end
end
```

## Filtering and Searching

### Advanced Filtering
```ruby
# app/controllers/api/v1/posts_controller.rb
class Api::V1::PostsController < Api::V1::BaseController
  def index
    posts = Post.includes(:user, :tags)
    posts = apply_filters(posts)
    posts = apply_sorting(posts)
    
    render_paginated_collection(posts, PostSerializer, include: [:user, :tags])
  end
  
  private
  
  def apply_filters(scope)
    scope = scope.where(published: true) unless params[:include_drafts] == 'true'
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where('title ILIKE ?', "%#{params[:title]}%") if params[:title].present?
    scope = scope.where('created_at >= ?', params[:created_after]) if params[:created_after].present?
    scope = scope.where('created_at <= ?', params[:created_before]) if params[:created_before].present?
    
    # Tag filtering
    if params[:tags].present?
      tag_names = params[:tags].split(',')
      scope = scope.joins(:tags).where(tags: { name: tag_names })
    end
    
    scope
  end
  
  def apply_sorting(scope)
    case params[:sort]
    when 'title'
      scope.order(:title)
    when 'created_at'
      scope.order(:created_at)
    when 'updated_at'
      scope.order(:updated_at)
    when 'popularity'
      scope.order(views_count: :desc)
    else
      scope.order(created_at: :desc)
    end
  end
end
```

### Search with Elasticsearch
```ruby
# Gemfile
gem 'elasticsearch-model'
gem 'elasticsearch-rails'

# app/models/post.rb
class Post < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  
  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :title, type: 'text', analyzer: 'english'
      indexes :content, type: 'text', analyzer: 'english'
      indexes :published, type: 'boolean'
      indexes :created_at, type: 'date'
      indexes :user, type: 'object' do
        indexes :name, type: 'text'
      end
    end
  end
  
  def as_indexed_json(options = {})
    {
      title: title,
      content: content,
      published: published,
      created_at: created_at,
      user: {
        name: user.name
      }
    }
  end
end

# app/controllers/api/v1/search_controller.rb
class Api::V1::SearchController < Api::V1::BaseController
  def posts
    query = params[:q]
    filters = build_filters
    
    search_results = Post.search(
      query: {
        bool: {
          must: [
            {
              multi_match: {
                query: query,
                fields: ['title^2', 'content'],
                fuzziness: 'AUTO'
              }
            }
          ],
          filter: filters
        }
      },
      highlight: {
        fields: {
          title: {},
          content: { fragment_size: 150 }
        }
      },
      size: params[:size] || 20,
      from: params[:from] || 0
    )
    
    render json: {
      data: search_results.records.map do |post|
        PostSerializer.new(post).serializable_hash[:data].merge(
          highlights: search_results.response['hits']['hits'].find { |hit| hit['_id'].to_i == post.id }&.dig('highlight')
        )
      end,
      meta: {
        total: search_results.response['hits']['total']['value'],
        took: search_results.response['took']
      }
    }
  end
  
  private
  
  def build_filters
    filters = []
    filters << { term: { published: true } } unless current_user&.admin?
    filters << { range: { created_at: { gte: params[:created_after] } } } if params[:created_after]
    filters << { range: { created_at: { lte: params[:created_before] } } } if params[:created_before]
    filters
  end
end
```

## File Uploads in APIs

### Base64 File Upload
```ruby
# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < Api::V1::BaseController
  def update_avatar
    if params[:avatar].present?
      decoded_file = decode_base64_file(params[:avatar])
      current_user.avatar.attach(decoded_file)
      
      render_success(
        user: UserSerializer.new(current_user).serializable_hash[:data]
      )
    else
      render_error('Avatar data is required')
    end
  end
  
  private
  
  def decode_base64_file(base64_string)
    # Extract file info from data URL
    data_uri_parts = base64_string.match(/\Adata:(.*?);base64,(.*)/)
    
    if data_uri_parts
      content_type = data_uri_parts[1]
      file_data = Base64.decode64(data_uri_parts[2])
      
      # Create temporary file
      temp_file = Tempfile.new(['upload', file_extension(content_type)])
      temp_file.binmode
      temp_file.write(file_data)
      temp_file.rewind
      
      {
        io: temp_file,
        filename: "avatar#{file_extension(content_type)}",
        content_type: content_type
      }
    else
      raise ArgumentError, 'Invalid base64 format'
    end
  end
  
  def file_extension(content_type)
    case content_type
    when 'image/jpeg' then '.jpg'
    when 'image/png' then '.png'
    when 'image/gif' then '.gif'
    else ''
    end
  end
end
```

### Direct Upload for APIs
```ruby
# app/controllers/api/v1/direct_uploads_controller.rb
class Api::V1::DirectUploadsController < Api::V1::BaseController
  def create
    blob = ActiveStorage::Blob.create_and_upload!(
      io: params[:file],
      filename: params[:file].original_filename,
      content_type: params[:file].content_type
    )
    
    render_success(
      blob: {
        id: blob.id,
        key: blob.key,
        filename: blob.filename,
        content_type: blob.content_type,
        byte_size: blob.byte_size,
        checksum: blob.checksum,
        created_at: blob.created_at,
        signed_id: blob.signed_id,
        url: url_for(blob)
      }
    )
  end
end
```

## Error Handling

### Comprehensive Error Handling
```ruby
# app/controllers/concerns/exception_handler.rb
module ExceptionHandler
  extend ActiveSupport::Concern
  
  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
    rescue_from ActionController::ParameterMissing, with: :parameter_missing
    rescue_from Pundit::NotAuthorizedError, with: :unauthorized
    rescue_from JWT::DecodeError, with: :invalid_token
    rescue_from StandardError, with: :internal_server_error
  end
  
  private
  
  def record_not_found(exception)
    render_error_response(
      message: 'Record not found',
      status: :not_found,
      code: 'RECORD_NOT_FOUND'
    )
  end
  
  def record_invalid(exception)
    render_error_response(
      message: 'Validation failed',
      status: :unprocessable_entity,
      code: 'VALIDATION_ERROR',
      details: format_validation_errors(exception.record.errors)
    )
  end
  
  def parameter_missing(exception)
    render_error_response(
      message: exception.message,
      status: :bad_request,
      code: 'PARAMETER_MISSING'
    )
  end
  
  def unauthorized(exception)
    render_error_response(
      message: 'Access denied',
      status: :forbidden,
      code: 'ACCESS_DENIED'
    )
  end
  
  def invalid_token(exception)
    render_error_response(
      message: 'Invalid authentication token',
      status: :unauthorized,
      code: 'INVALID_TOKEN'
    )
  end
  
  def internal_server_error(exception)
    Rails.logger.error exception.message
    Rails.logger.error exception.backtrace.join("\n")
    
    render_error_response(
      message: 'Internal server error',
      status: :internal_server_error,
      code: 'INTERNAL_ERROR'
    )
  end
  
  def render_error_response(message:, status:, code:, details: nil)
    error_response = {
      error: {
        message: message,
        code: code,
        status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
      }
    }
    
    error_response[:error][:details] = details if details
    
    render json: error_response, status: status
  end
  
  def format_validation_errors(errors)
    errors.messages.transform_values { |messages| messages.first }
  end
end
```

## Testing APIs

### Request Tests
```ruby
# test/integration/api/v1/users_test.rb
require 'test_helper'

class Api::V1::UsersTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @auth_headers = { 'Authorization' => "Bearer #{@user.api_token}" }
  end
  
  test "GET /api/v1/users returns users" do
    get api_v1_users_path, headers: @auth_headers
    
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_not_empty json_response['data']
  end
  
  test "POST /api/v1/users creates user" do
    user_params = {
      user: {
        name: 'New User',
        email: 'new@example.com',
        password: 'password123'
      }
    }
    
    assert_difference 'User.count', 1 do
      post api_v1_users_path, params: user_params, as: :json
    end
    
    assert_response :created
    
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 'New User', json_response['data']['attributes']['name']
  end
  
  test "authentication required" do
    get api_v1_users_path
    
    assert_response :unauthorized
    
    json_response = JSON.parse(response.body)
    assert_equal 'Unauthorized', json_response['error']['message']
  end
end
```

## API Documentation

### OpenAPI/Swagger Documentation
```ruby
# Gemfile
gem 'rspec_api_documentation'
gem 'apitome'

# spec/acceptance/users_spec.rb
require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Users' do
  header 'Authorization', 'Bearer TOKEN'
  header 'Content-Type', 'application/json'
  
  get '/api/v1/users' do
    parameter :page, 'Page number', type: :integer
    parameter :per_page, 'Items per page', type: :integer
    
    example 'List users' do
      do_request
      
      expect(status).to eq(200)
      expect(response_body).to match_json_schema('users_index')
    end
  end
  
  post '/api/v1/users' do
    parameter :name, 'User name', type: :string, required: true
    parameter :email, 'User email', type: :string, required: true
    parameter :password, 'User password', type: :string, required: true
    
    example 'Create user' do
      do_request(
        user: {
          name: 'John Doe',
          email: 'john@example.com',
          password: 'password123'
        }
      )
      
      expect(status).to eq(201)
    end
  end
end
```

## References

- [Rails API Documentation](https://guides.rubyonrails.org/api_app.html)
- [JSON API Specification](https://jsonapi.org/)
- [Active Model Serializers](https://github.com/rails-api/active_model_serializers)
- [JWT Authentication](https://jwt.io/introduction/)