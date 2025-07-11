# MVC Architecture

## Overview

Rails follows the Model-View-Controller (MVC) architectural pattern, separating application logic into three interconnected components. This separation promotes maintainable, testable, and scalable code.

## The Three Components

### Model (ActiveRecord)
**Purpose**: Data logic, business rules, and database interactions

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates :title, presence: true
  belongs_to :user
  has_many :comments, dependent: :destroy
  
  scope :published, -> { where(published: true) }
  
  def excerpt(length = 100)
    content.truncate(length)
  end
end
```

**Responsibilities**:
- Data validation
- Business logic
- Database relationships
- Scopes and queries
- Callbacks and lifecycle management

### View (ActionView)
**Purpose**: Presentation logic and user interface

```erb
<!-- app/views/posts/show.html.erb -->
<article class="post">
  <h1><%= @post.title %></h1>
  <p class="meta">By <%= @post.user.name %> on <%= @post.created_at.strftime("%B %d, %Y") %></p>
  
  <div class="content">
    <%= simple_format(@post.content) %>
  </div>
  
  <%= render 'comments/list', comments: @post.comments %>
</article>
```

**Responsibilities**:
- HTML markup and templates
- Data presentation
- User interface components
- Helper method usage
- Partial rendering

### Controller (ActionController)
**Purpose**: Request handling and coordination between Model and View

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  
  def index
    @posts = Post.published.includes(:user).page(params[:page])
  end
  
  def show
    @comment = Comment.new
  end
  
  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      redirect_to @post, notice: 'Post created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_post
    @post = Post.find(params[:id])
  end
  
  def post_params
    params.require(:post).permit(:title, :content, :published)
  end
end
```

**Responsibilities**:
- HTTP request processing
- Parameter handling and validation
- Authentication and authorization
- Model instantiation and manipulation
- Response rendering and redirects

## Request Flow

```
1. Router receives HTTP request
   ↓
2. Routes to appropriate Controller#action
   ↓
3. Controller processes request
   ↓
4. Controller interacts with Model(s)
   ↓
5. Model queries/updates database
   ↓
6. Controller assigns instance variables
   ↓
7. Controller renders View
   ↓
8. View accesses instance variables
   ↓
9. HTML response sent to browser
```

## Folder Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── posts_controller.rb
│   └── comments_controller.rb
├── models/
│   ├── application_record.rb
│   ├── post.rb
│   ├── user.rb
│   └── comment.rb
└── views/
    ├── layouts/
    │   └── application.html.erb
    ├── posts/
    │   ├── index.html.erb
    │   ├── show.html.erb
    │   ├── new.html.erb
    │   └── edit.html.erb
    └── shared/
        └── _navigation.html.erb
```

## Best Practices

### Fat Model, Skinny Controller
Move business logic to models, keep controllers focused on request handling.

```ruby
# Bad - logic in controller
class PostsController < ApplicationController
  def publish
    @post = Post.find(params[:id])
    @post.published = true
    @post.published_at = Time.current
    @post.save
    # send notification email
    # update search index
    # log activity
  end
end

# Good - logic in model
class Post < ApplicationRecord
  def publish!
    update!(published: true, published_at: Time.current)
    send_notification_email
    update_search_index
    log_publication_activity
  end
end

class PostsController < ApplicationController
  def publish
    @post = Post.find(params[:id])
    @post.publish!
  end
end
```

### Separation of Concerns

#### Controllers
- Handle HTTP-specific logic only
- Delegate business logic to models
- Keep actions focused and small

#### Models  
- Contain domain logic
- Handle data validation
- Manage relationships
- Provide query interfaces

#### Views
- Focus on presentation
- Use helpers for complex formatting
- Keep logic minimal

## Common Patterns

### Service Objects
For complex business operations spanning multiple models:

```ruby
# app/services/post_publisher.rb
class PostPublisher
  def initialize(post, user)
    @post = post
    @user = user
  end
  
  def call
    return false unless can_publish?
    
    @post.publish!
    notify_subscribers
    update_analytics
    true
  end
  
  private
  
  def can_publish?
    @user.can_publish?(@post)
  end
end

# In controller
class PostsController < ApplicationController
  def publish
    @post = Post.find(params[:id])
    
    if PostPublisher.new(@post, current_user).call
      redirect_to @post, notice: 'Published successfully'
    else
      redirect_to @post, alert: 'Cannot publish post'
    end
  end
end
```

### Form Objects
For complex forms spanning multiple models:

```ruby
# app/forms/user_registration_form.rb
class UserRegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :name, :string
  attribute :email, :string
  attribute :company_name, :string
  
  validates :name, :email, :company_name, presence: true
  
  def save
    return false unless valid?
    
    ActiveRecord::Base.transaction do
      user = User.create!(name: name, email: email)
      company = Company.create!(name: company_name, owner: user)
      user.update!(company: company)
    end
  end
end
```

## Testing MVC Components

### Model Tests
```ruby
# test/models/post_test.rb
class PostTest < ActiveSupport::TestCase
  test "should not save post without title" do
    post = Post.new
    assert_not post.save
  end
  
  test "excerpt should truncate content" do
    post = posts(:one)
    assert_equal 10, post.excerpt(10).length
  end
end
```

### Controller Tests
```ruby
# test/controllers/posts_controller_test.rb
class PostsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get posts_path
    assert_response :success
  end
  
  test "should create post when logged in" do
    sign_in users(:one)
    assert_difference('Post.count') do
      post posts_path, params: { post: { title: 'New Post', content: 'Content' } }
    end
  end
end
```

### View Tests
```ruby
# test/views/posts/show_test.rb
class PostsShowViewTest < ActionView::TestCase
  test "displays post title and content" do
    post = posts(:one)
    assign(:post, post)
    
    render template: 'posts/show'
    
    assert_select 'h1', post.title
    assert_select '.content', text: post.content
  end
end
```

## References

- [Action Controller Overview](https://guides.rubyonrails.org/action_controller_overview.html)
- [Active Record Basics](https://guides.rubyonrails.org/active_record_basics.html)
- [Action View Overview](https://guides.rubyonrails.org/action_view_overview.html)
- [Rails Routing](https://guides.rubyonrails.org/routing.html)