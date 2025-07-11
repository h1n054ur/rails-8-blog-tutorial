# ActiveRecord: Models, Validations, Associations

## Overview

ActiveRecord is Rails' Object-Relational Mapping (ORM) layer that connects classes to database tables. It provides a rich API for database operations, validations, and relationships between models.

## Basic Model Structure

### Generating Models
```bash
# Basic model
rails generate model User name:string email:string

# With associations
rails generate model Post title:string content:text user:references

# Run migration
rails db:migrate
```

### Model Definition
```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  # Associations
  has_many :posts, dependent: :destroy
  has_many :comments
  has_one :profile, dependent: :destroy
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks
  before_save :normalize_email
  after_create :send_welcome_email
  
  # Class methods
  def self.find_by_username(username)
    find_by(email: "#{username}@company.com")
  end
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  private
  
  def normalize_email
    self.email = email.downcase.strip
  end
  
  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
```

## Validations

### Common Validation Types
```ruby
class Post < ApplicationRecord
  # Presence
  validates :title, presence: true
  validates :content, presence: { message: "can't be blank" }
  
  # Length
  validates :title, length: { minimum: 5, maximum: 100 }
  validates :slug, length: { is: 10 }
  
  # Format
  validates :email, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }
  validates :phone, format: { with: /\A\d{10}\z/, message: "must be 10 digits" }
  
  # Uniqueness
  validates :email, uniqueness: true
  validates :slug, uniqueness: { scope: :user_id }
  
  # Inclusion/Exclusion
  validates :status, inclusion: { in: %w[draft published archived] }
  validates :username, exclusion: { in: %w[admin root] }
  
  # Numericality
  validates :age, numericality: { greater_than: 0, less_than: 150 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  
  # Custom validations
  validate :future_date
  validate :unique_title_per_user
  
  private
  
  def future_date
    return unless publish_date
    
    errors.add(:publish_date, "can't be in the past") if publish_date < Date.current
  end
  
  def unique_title_per_user
    return unless title && user_id
    
    existing = Post.where(user_id: user_id, title: title).where.not(id: id)
    errors.add(:title, "already exists for this user") if existing.exists?
  end
end
```

### Conditional Validations
```ruby
class User < ApplicationRecord
  validates :password, presence: true, if: :password_required?
  validates :company, presence: true, unless: :personal_account?
  validates :tax_id, presence: true, if: -> { business_account? && country == 'US' }
  
  private
  
  def password_required?
    new_record? || password.present?
  end
  
  def personal_account?
    account_type == 'personal'
  end
end
```

## Associations

### Basic Associations
```ruby
class User < ApplicationRecord
  # One-to-many
  has_many :posts
  has_many :comments
  
  # One-to-one
  has_one :profile
  has_one :subscription
  
  # Many-to-many through join table
  has_many :user_groups
  has_many :groups, through: :user_groups
  
  # Polymorphic
  has_many :attachments, as: :attachable
end

class Post < ApplicationRecord
  # Belongs to
  belongs_to :user
  belongs_to :category, optional: true
  
  # One-to-many
  has_many :comments, dependent: :destroy
  has_many :tags, through: :post_tags
  
  # Self-referential
  belongs_to :parent_post, class_name: 'Post', optional: true
  has_many :child_posts, class_name: 'Post', foreign_key: 'parent_post_id'
end

class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user
  
  # Polymorphic
  belongs_to :commentable, polymorphic: true
end
```

### Advanced Association Options
```ruby
class User < ApplicationRecord
  # With custom foreign key
  has_many :authored_posts, class_name: 'Post', foreign_key: 'author_id'
  
  # With conditions
  has_many :published_posts, -> { where(published: true) }, class_name: 'Post'
  has_many :recent_comments, -> { where(created_at: 1.week.ago..) }, class_name: 'Comment'
  
  # Through associations
  has_many :post_comments, through: :posts, source: :comments
  has_many :commenters, through: :post_comments, source: :user
  
  # Dependent options
  has_many :posts, dependent: :destroy        # Delete associated records
  has_many :drafts, dependent: :delete_all    # Skip callbacks for performance
  has_one :profile, dependent: :destroy       # Delete the associated record
  has_many :views, dependent: :nullify        # Set foreign key to NULL
end
```

### Association Callbacks
```ruby
class User < ApplicationRecord
  has_many :posts, 
           before_add: :check_post_limit,
           after_add: :update_post_count,
           before_remove: :archive_post
  
  private
  
  def check_post_limit(post)
    raise "Post limit exceeded" if posts.count >= 100
  end
  
  def update_post_count(post)
    increment!(:posts_count)
  end
  
  def archive_post(post)
    post.update!(archived: true)
  end
end
```

## Querying and Scopes

### Basic Queries
```ruby
# Find methods
User.find(1)                          # Find by ID
User.find_by(email: 'user@example.com') # Find first match
User.where(active: true)              # All matching records
User.first                            # First record
User.last                             # Last record

# Conditions
User.where(active: true)
User.where("age > ?", 18)
User.where(age: 18..65)
User.where(name: ['John', 'Jane'])
User.where.not(status: 'banned')

# Ordering
User.order(:name)
User.order(created_at: :desc)
User.order("LOWER(name)")

# Limiting
User.limit(10)
User.offset(20)
User.limit(10).offset(20)

# Grouping and aggregation
User.group(:status).count
User.where(active: true).average(:age)
User.maximum(:created_at)
```

### Advanced Queries
```ruby
# Joins
User.joins(:posts)
User.joins(posts: :comments)
User.left_joins(:posts)

# Includes (eager loading)
User.includes(:posts)
User.includes(posts: [:comments, :tags])

# Preload and eager_load
User.preload(:posts)        # Separate queries
User.eager_load(:posts)     # LEFT JOIN

# Exists
User.where(posts: Post.where(published: true))
User.where.exists(posts: { published: true })

# Subqueries
popular_posts = Post.where('comments_count > ?', 10)
User.where(id: popular_posts.select(:user_id))
```

### Scopes
```ruby
class Post < ApplicationRecord
  # Basic scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { where(created_at: 1.week.ago..) }
  scope :by_author, ->(author) { where(user: author) }
  
  # Parameterized scopes
  scope :tagged_with, ->(tag) { joins(:tags).where(tags: { name: tag }) }
  scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  
  # Conditional scopes
  scope :featured, -> { where(featured: true) if conditions_met? }
  
  # Default scope (use sparingly)
  default_scope { where(deleted_at: nil) }
  
  # Class methods as alternative to scopes
  def self.popular
    where('views_count > ?', 1000)
  end
  
  def self.search(term)
    where("title ILIKE ? OR content ILIKE ?", "%#{term}%", "%#{term}%")
  end
end

# Usage
Post.published.recent
Post.by_author(current_user).tagged_with('ruby')
Post.created_between(1.month.ago, Date.current)
```

## Callbacks

### Callback Types and Order
```ruby
class Post < ApplicationRecord
  # Validation callbacks
  before_validation :clean_title
  after_validation :log_errors
  
  # Save callbacks
  before_save :set_slug
  around_save :benchmark_save
  after_save :update_search_index
  
  # Create callbacks
  before_create :set_defaults
  after_create :send_notification
  
  # Update callbacks
  before_update :track_changes
  after_update :clear_cache
  
  # Destroy callbacks
  before_destroy :check_dependencies
  after_destroy :cleanup_files
  
  private
  
  def clean_title
    self.title = title.strip.titleize if title
  end
  
  def set_slug
    self.slug = title.parameterize if title_changed?
  end
  
  def benchmark_save
    start_time = Time.current
    yield
    Rails.logger.info "Save took #{Time.current - start_time}s"
  end
  
  def set_defaults
    self.status ||= 'draft'
    self.published_at ||= Time.current if published?
  end
end
```

### Conditional Callbacks
```ruby
class User < ApplicationRecord
  before_save :encrypt_password, if: :password_changed?
  after_create :send_welcome_email, unless: :admin?
  before_destroy :prevent_admin_deletion, if: -> { admin? && User.admin.count == 1 }
end
```

## Attributes and Serialization

### Custom Attributes
```ruby
class User < ApplicationRecord
  # Enum attributes
  enum status: { active: 0, inactive: 1, banned: 2 }
  enum role: { user: 'user', admin: 'admin', moderator: 'moderator' }
  
  # Serialized attributes
  serialize :preferences, JSON
  serialize :tags, Array
  
  # Store accessor for JSON columns
  store :settings, accessors: [:theme, :language, :timezone]
  
  # Custom attribute methods
  def full_name
    [first_name, last_name].compact.join(' ')
  end
  
  def full_name=(name)
    parts = name.split(' ', 2)
    self.first_name = parts[0]
    self.last_name = parts[1]
  end
end
```

### Dirty Tracking
```ruby
class Post < ApplicationRecord
  before_save :log_title_change
  
  private
  
  def log_title_change
    if title_changed?
      Rails.logger.info "Title changed from '#{title_was}' to '#{title}'"
    end
  end
end

# Usage
post = Post.find(1)
post.title = "New Title"
post.title_changed?        # => true
post.title_was            # => "Old Title"
post.title_change         # => ["Old Title", "New Title"]
post.changed              # => ["title"]
post.changes              # => {"title" => ["Old Title", "New Title"]}
```

## Database Transactions

```ruby
# Basic transaction
ActiveRecord::Base.transaction do
  user = User.create!(name: 'John', email: 'john@example.com')
  profile = Profile.create!(user: user, bio: 'Software developer')
  # If any operation fails, all changes are rolled back
end

# Transaction with specific models
User.transaction do
  user.update!(status: 'inactive')
  user.posts.update_all(published: false)
end

# Nested transactions with savepoints
User.transaction do
  user.save!
  
  User.transaction(requires_new: true) do
    # This uses a savepoint
    risky_operation
  end
  
  user.profile.save!
end

# Manual rollback
User.transaction do
  user.save!
  raise ActiveRecord::Rollback if some_condition?
  user.profile.save!
end
```

## Performance Optimization

### N+1 Query Prevention
```ruby
# Bad - N+1 queries
posts = Post.all
posts.each { |post| puts post.user.name }

# Good - eager loading
posts = Post.includes(:user)
posts.each { |post| puts post.user.name }

# Multiple associations
posts = Post.includes(:user, :comments, tags: :category)
```

### Counter Cache
```ruby
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :category, counter_cache: :posts_count
end

class User < ApplicationRecord
  has_many :posts
  # Requires posts_count column in users table
end

# Reset counter cache
User.reset_counters(user_id, :posts)
```

### Database Indexes
```ruby
# In migration
class AddIndexesToPosts < ActiveRecord::Migration[7.0]
  def change
    add_index :posts, :user_id
    add_index :posts, [:status, :created_at]
    add_index :posts, :title, unique: true
    add_index :posts, :content, using: 'gin'  # For full-text search
  end
end
```

## References

- [Active Record Basics](https://guides.rubyonrails.org/active_record_basics.html)
- [Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html)
- [Active Record Validations](https://guides.rubyonrails.org/active_record_validations.html)
- [Active Record Associations](https://guides.rubyonrails.org/association_basics.html)
- [Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html)
- [Active Record Callbacks](https://guides.rubyonrails.org/active_record_callbacks.html)