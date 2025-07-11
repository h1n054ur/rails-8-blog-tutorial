# Plugins & Engines

## Overview

Rails engines provide a way to wrap and distribute reusable functionality as gems. Engines can contain models, views, controllers, routes, and other Rails components. Plugins extend Rails functionality through hooks and extensions.

## Rails Engines

### Creating an Engine
```bash
# Generate a new engine
rails plugin new my_engine --mountable

# Or as a full engine
rails plugin new my_engine --full

# With specific options
rails plugin new my_engine --mountable --skip-test --database=postgresql
```

### Engine Structure
```
my_engine/
├── app/
│   ├── controllers/
│   │   └── my_engine/
│   │       └── application_controller.rb
│   ├── models/
│   │   └── my_engine/
│   ├── views/
│   │   └── my_engine/
│   └── assets/
├── config/
│   └── routes.rb
├── lib/
│   ├── my_engine/
│   │   ├── engine.rb
│   │   └── version.rb
│   └── my_engine.rb
├── my_engine.gemspec
└── Gemfile
```

### Engine Configuration
```ruby
# lib/my_engine/engine.rb
module MyEngine
  class Engine < ::Rails::Engine
    # Isolate engine namespace
    isolate_namespace MyEngine
    
    # Engine configuration
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end
    
    # Load paths
    config.autoload_paths << File.expand_path('../../app/models/concerns', __FILE__)
    
    # Asset paths
    config.assets.paths << File.expand_path('../../app/assets/javascripts', __FILE__)
    config.assets.paths << File.expand_path('../../app/assets/stylesheets', __FILE__)
    
    # Precompile assets
    config.assets.precompile += ['my_engine/application.js', 'my_engine/application.css']
    
    # Engine initializers
    initializer "my_engine.assets.precompile" do |app|
      app.config.assets.precompile += %w[my_engine/application.js my_engine/application.css]
    end
    
    # Load translations
    config.i18n.load_path += Dir[File.expand_path('../../config/locales/*.yml', __FILE__)]
  end
end

# lib/my_engine.rb
require "my_engine/engine"

module MyEngine
  # Engine configuration
  mattr_accessor :default_currency
  @@default_currency = 'USD'
  
  mattr_accessor :admin_email
  @@admin_email = 'admin@example.com'
  
  def self.setup
    yield(self)
  end
end
```

### Engine Models and Controllers
```ruby
# app/models/my_engine/product.rb
module MyEngine
  class Product < ApplicationRecord
    validates :name, presence: true
    validates :price, presence: true, numericality: { greater_than: 0 }
    
    scope :active, -> { where(active: true) }
    scope :featured, -> { where(featured: true) }
  end
end

# app/controllers/my_engine/application_controller.rb
module MyEngine
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    
    private
    
    def current_user
      # Delegate to main application
      main_app_current_user if respond_to?(:main_app_current_user)
    end
  end
end

# app/controllers/my_engine/products_controller.rb
module MyEngine
  class ProductsController < ApplicationController
    before_action :set_product, only: [:show, :edit, :update, :destroy]
    
    def index
      @products = Product.active.page(params[:page])
    end
    
    def show
      # @product set by before_action
    end
    
    def new
      @product = Product.new
    end
    
    def create
      @product = Product.new(product_params)
      
      if @product.save
        redirect_to @product, notice: 'Product created successfully'
      else
        render :new
      end
    end
    
    private
    
    def set_product
      @product = Product.find(params[:id])
    end
    
    def product_params
      params.require(:product).permit(:name, :description, :price, :active, :featured)
    end
  end
end
```

### Engine Routes
```ruby
# config/routes.rb
MyEngine::Engine.routes.draw do
  root 'products#index'
  
  resources :products do
    member do
      patch :toggle_featured
    end
    
    collection do
      get :featured
    end
  end
  
  namespace :admin do
    resources :products
    resources :categories
  end
end
```

## Mounting Engines

### Mount in Host Application
```ruby
# Host application's config/routes.rb
Rails.application.routes.draw do
  # Mount at root
  mount MyEngine::Engine, at: '/'
  
  # Mount at specific path
  mount MyEngine::Engine, at: '/shop'
  
  # Mount with constraints
  constraints subdomain: 'shop' do
    mount MyEngine::Engine, at: '/'
  end
  
  # Multiple mounts
  mount BlogEngine::Engine, at: '/blog'
  mount ForumEngine::Engine, at: '/forum'
end

# Gemfile
gem 'my_engine', path: 'engines/my_engine'
# or
gem 'my_engine', git: 'https://github.com/company/my_engine.git'
```

### Engine Configuration in Host App
```ruby
# config/initializers/my_engine.rb
MyEngine.setup do |config|
  config.default_currency = 'EUR'
  config.admin_email = 'shop@company.com'
  config.allow_guest_checkout = true
end

# Override engine behavior
MyEngine::Engine.configure do
  config.time_zone = 'UTC'
  config.default_locale = :en
end
```

## Engine Migrations

### Engine Migrations
```ruby
# Generate migration in engine
rails generate migration CreateMyEngineProducts name:string price:decimal

# db/migrate/001_create_my_engine_products.rb
class CreateMyEngineProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :my_engine_products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.boolean :active, default: true
      t.boolean :featured, default: false
      
      t.timestamps
    end
    
    add_index :my_engine_products, :active
    add_index :my_engine_products, :featured
  end
end
```

### Install Engine Migrations
```bash
# In host application
rails my_engine:install:migrations
rails db:migrate

# Or copy specific migrations
rails railties:install:migrations FROM=my_engine
```

## Engine Assets

### Asset Organization
```
my_engine/app/assets/
├── stylesheets/
│   └── my_engine/
│       ├── application.css
│       ├── products.css
│       └── admin.css
├── javascripts/
│   └── my_engine/
│       ├── application.js
│       └── products.js
└── images/
    └── my_engine/
        └── logo.png
```

### Asset Compilation
```ruby
# my_engine/lib/my_engine/engine.rb
module MyEngine
  class Engine < ::Rails::Engine
    # Precompile engine assets
    initializer "my_engine.assets" do |app|
      app.config.assets.precompile += [
        'my_engine/application.js',
        'my_engine/application.css',
        'my_engine/admin.js',
        'my_engine/admin.css'
      ]
    end
  end
end

# Include in host application
# app/assets/stylesheets/application.css
/*
 *= require my_engine/application
 */

# app/assets/javascripts/application.js
//= require my_engine/application
```

## Engine Testing

### Test Environment Setup
```ruby
# spec/rails_helper.rb (in engine)
require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../test/dummy/config/environment', __dir__)

require 'rspec/rails'
require 'factory_bot_rails'

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  
  config.include FactoryBot::Syntax::Methods
  config.include MyEngine::Engine.routes.url_helpers
end

# Dummy application for testing
# test/dummy/config/application.rb
require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)
require "my_engine"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
  end
end
```

### Model and Controller Tests
```ruby
# spec/models/my_engine/product_spec.rb
require 'rails_helper'

module MyEngine
  RSpec.describe Product, type: :model do
    it 'is valid with valid attributes' do
      product = build(:product)
      expect(product).to be_valid
    end
    
    it 'requires a name' do
      product = build(:product, name: nil)
      expect(product).not_to be_valid
      expect(product.errors[:name]).to include("can't be blank")
    end
    
    describe 'scopes' do
      let!(:active_product) { create(:product, active: true) }
      let!(:inactive_product) { create(:product, active: false) }
      
      it 'returns only active products' do
        expect(Product.active).to include(active_product)
        expect(Product.active).not_to include(inactive_product)
      end
    end
  end
end

# spec/controllers/my_engine/products_controller_spec.rb
require 'rails_helper'

module MyEngine
  RSpec.describe ProductsController, type: :controller do
    routes { MyEngine::Engine.routes }
    
    describe 'GET #index' do
      it 'returns success response' do
        get :index
        expect(response).to be_successful
      end
      
      it 'assigns active products' do
        active_product = create(:product, active: true)
        inactive_product = create(:product, active: false)
        
        get :index
        expect(assigns(:products)).to include(active_product)
        expect(assigns(:products)).not_to include(inactive_product)
      end
    end
  end
end
```

## Engine Hooks and Extensions

### Extending Host Application
```ruby
# lib/my_engine/engine.rb
module MyEngine
  class Engine < ::Rails::Engine
    # Extend ActiveRecord
    initializer "my_engine.active_record" do
      ActiveSupport.on_load(:active_record) do
        extend MyEngine::ProductConcern
      end
    end
    
    # Add middleware
    initializer "my_engine.middleware" do |app|
      app.config.middleware.use MyEngine::TrackingMiddleware
    end
    
    # Register observers
    initializer "my_engine.observers" do
      ActiveRecord::Base.observers = :product_observer
    end
    
    # Add helpers to host application
    initializer "my_engine.action_controller" do
      ActiveSupport.on_load(:action_controller) do
        helper MyEngine::ApplicationHelper
      end
    end
  end
end

# Concerns for extending models
# app/models/concerns/my_engine/product_concern.rb
module MyEngine
  module ProductConcern
    extend ActiveSupport::Concern
    
    included do
      has_many :my_engine_products, class_name: 'MyEngine::Product'
    end
    
    def total_product_value
      my_engine_products.sum(:price)
    end
  end
end
```

### Configuration and Customization
```ruby
# lib/my_engine.rb
module MyEngine
  class Configuration
    attr_accessor :currency, :tax_rate, :shipping_cost
    
    def initialize
      @currency = 'USD'
      @tax_rate = 0.08
      @shipping_cost = 10.0
    end
  end
  
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  def self.configure
    yield(configuration)
  end
end

# Usage in host application
MyEngine.configure do |config|
  config.currency = 'EUR'
  config.tax_rate = 0.21
  config.shipping_cost = 15.0
end
```

## Distributing Engines

### Gemspec Configuration
```ruby
# my_engine.gemspec
$:.push File.expand_path("lib", __dir__)
require "my_engine/version"

Gem::Specification.new do |spec|
  spec.name        = "my_engine"
  spec.version     = MyEngine::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["your.email@example.com"]
  spec.homepage    = "https://github.com/yourname/my_engine"
  spec.summary     = "A Rails engine for product management"
  spec.description = "MyEngine provides product management functionality for Rails applications"
  spec.license     = "MIT"
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourname/my_engine"
  spec.metadata["changelog_uri"] = "https://github.com/yourname/my_engine/blob/main/CHANGELOG.md"
  
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  
  spec.require_paths = ["lib"]
  
  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "image_processing", "~> 1.2"
  
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "sqlite3"
end
```

### Publishing Engine
```bash
# Build gem
gem build my_engine.gemspec

# Test gem locally
gem install my_engine-0.1.0.gem

# Publish to RubyGems
gem push my_engine-0.1.0.gem

# Or use bundler
bundle exec rake release
```

## Engine Best Practices

### Namespace Isolation
```ruby
# Always use proper namespacing
module MyEngine
  class Product < ApplicationRecord
    # Engine-specific implementation
  end
end

# Avoid polluting global namespace
# Bad
class Product < ApplicationRecord
end

# Good
module MyEngine
  class Product < ApplicationRecord
  end
end
```

### Configuration Management
```ruby
# Provide sensible defaults
module MyEngine
  mattr_accessor :settings
  
  self.settings = {
    currency: 'USD',
    tax_rate: 0.0,
    allow_backorders: false
  }
  
  def self.setting(key)
    settings[key]
  end
  
  def self.configure
    yield(settings)
  end
end
```

### Database Considerations
```ruby
# Use engine-specific table names
class CreateMyEngineProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :my_engine_products do |t|
      # Table definition
    end
  end
end

# Provide installation generator
# lib/generators/my_engine/install_generator.rb
module MyEngine
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      
      source_root File.expand_path('templates', __dir__)
      
      def copy_initializer
        template 'my_engine.rb', 'config/initializers/my_engine.rb'
      end
      
      def install_migrations
        rake 'my_engine:install:migrations'
      end
    end
  end
end
```

## References

- [Rails Engines Guide](https://guides.rubyonrails.org/engines.html)
- [Creating Gem with Bundler](https://bundler.io/v2.0/guides/creating_gem.html)
- [Rails Plugin Development](https://guides.rubyonrails.org/plugins.html)
- [Engine Testing Strategies](https://guides.rubyonrails.org/engines.html#testing-an-engine)