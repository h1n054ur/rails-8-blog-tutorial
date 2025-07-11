# Testing (Minitest & RSpec)

## Overview

Rails provides excellent testing support with Minitest as the default framework. RSpec is a popular alternative. Both frameworks support unit testing, integration testing, and system testing for comprehensive application coverage.

## Minitest (Rails Default)

### Test Structure
```ruby
# test/test_helper.rb
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)
  
  # Setup all fixtures in test/fixtures/*.yml for all tests
  fixtures :all
  
  # Add more helper methods to be used by all tests here...
  
  def sign_in(user)
    post login_path, params: { email: user.email, password: 'password' }
  end
  
  def json_response
    JSON.parse(response.body)
  end
end
```

### Model Tests
```ruby
# test/models/user_test.rb
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(name: "Test User", email: "test@example.com")
  end
  
  test "should be valid" do
    assert @user.valid?
  end
  
  test "name should be present" do
    @user.name = "   "
    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end
  
  test "email should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end
  
  test "should have many posts" do
    assert_respond_to @user, :posts
  end
  
  test "associated posts should be destroyed" do
    @user.save
    @user.posts.create!(title: "Test Post", content: "Content")
    assert_difference 'Post.count', -1 do
      @user.destroy
    end
  end
  
  # Test scopes
  test "active scope returns only active users" do
    active_user = users(:active_user)
    inactive_user = users(:inactive_user)
    
    active_users = User.active
    assert_includes active_users, active_user
    assert_not_includes active_users, inactive_user
  end
  
  # Test instance methods
  test "full_name returns first and last name" do
    user = User.new(first_name: "John", last_name: "Doe")
    assert_equal "John Doe", user.full_name
  end
  
  # Test validations with custom messages
  test "email format validation" do
    invalid_emails = %w[user@foo,com user_at_foo.org example.user@foo.]
    invalid_emails.each do |email|
      @user.email = email
      assert_not @user.valid?, "#{email.inspect} should be invalid"
    end
  end
end
```

### Controller Tests
```ruby
# test/controllers/posts_controller_test.rb
require 'test_helper'

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = posts(:one)
    sign_in @user
  end
  
  test "should get index" do
    get posts_path
    assert_response :success
    assert_select 'h1', 'Posts'
    assert_select '.post', minimum: 1
  end
  
  test "should show post" do
    get post_path(@post)
    assert_response :success
    assert_select 'h1', @post.title
  end
  
  test "should get new" do
    get new_post_path
    assert_response :success
    assert_select 'form'
  end
  
  test "should create post" do
    assert_difference('Post.count') do
      post posts_path, params: { 
        post: { 
          title: 'New Post', 
          content: 'Post content',
          published: true
        } 
      }
    end
    
    assert_redirected_to post_path(Post.last)
    assert_equal 'New Post', Post.last.title
    follow_redirect!
    assert_select 'h1', 'New Post'
  end
  
  test "should not create post with invalid params" do
    assert_no_difference('Post.count') do
      post posts_path, params: { post: { title: '', content: '' } }
    end
    
    assert_response :unprocessable_entity
    assert_select '.error'
  end
  
  test "should get edit" do
    get edit_post_path(@post)
    assert_response :success
    assert_select 'form'
    assert_select "input[value='#{@post.title}']"
  end
  
  test "should update post" do
    patch post_path(@post), params: { 
      post: { title: 'Updated Title' } 
    }
    
    assert_redirected_to post_path(@post)
    @post.reload
    assert_equal 'Updated Title', @post.title
  end
  
  test "should destroy post" do
    assert_difference('Post.count', -1) do
      delete post_path(@post)
    end
    
    assert_redirected_to posts_path
  end
  
  test "should require authentication" do
    sign_out
    get new_post_path
    assert_redirected_to login_path
  end
  
  test "should deny access to other users' posts" do
    other_post = posts(:other_user_post)
    get edit_post_path(other_post)
    assert_redirected_to posts_path
  end
  
  # Test JSON responses
  test "should return posts as JSON" do
    get posts_path, as: :json
    assert_response :success
    assert_equal 'application/json', response.content_type
    
    json = JSON.parse(response.body)
    assert json.is_a?(Array)
  end
end
```

### Integration Tests
```ruby
# test/integration/user_flows_test.rb
require 'test_helper'

class UserFlowsTest < ActionDispatch::IntegrationTest
  test "user signup and login flow" do
    # Signup
    get signup_path
    assert_response :success
    
    assert_difference 'User.count', 1 do
      post users_path, params: {
        user: {
          name: 'New User',
          email: 'newuser@example.com',
          password: 'password',
          password_confirmation: 'password'
        }
      }
    end
    
    assert_redirected_to root_path
    follow_redirect!
    assert_select '.notice', text: /welcome/i
    
    # Logout
    delete logout_path
    assert_redirected_to root_path
    
    # Login
    post login_path, params: {
      email: 'newuser@example.com',
      password: 'password'
    }
    
    assert_redirected_to root_path
    follow_redirect!
    assert_select '.notice', text: /logged in/i
  end
  
  test "complete post creation workflow" do
    user = users(:author)
    sign_in user
    
    # Navigate to new post
    get posts_path
    click_on 'New Post'
    assert_current_path new_post_path
    
    # Fill and submit form
    fill_in 'Title', with: 'Integration Test Post'
    fill_in 'Content', with: 'This is a test post created during integration testing.'
    check 'Published'
    click_button 'Create Post'
    
    # Verify creation and redirect
    post = Post.last
    assert_equal 'Integration Test Post', post.title
    assert_current_path post_path(post)
    assert_text 'Post was successfully created'
    
    # Edit the post
    click_on 'Edit'
    fill_in 'Title', with: 'Updated Integration Test Post'
    click_button 'Update Post'
    
    # Verify update
    assert_current_path post_path(post)
    assert_text 'Updated Integration Test Post'
  end
end
```

### System Tests (Capybara)
```ruby
# test/system/posts_test.rb
require 'application_system_test_case'

class PostsTest < ApplicationSystemTestCase
  setup do
    @user = users(:author)
    @post = posts(:published)
  end
  
  test "visiting the index" do
    visit posts_path
    
    assert_selector "h1", text: "Posts"
    assert_selector ".post", count: Post.published.count
  end
  
  test "creating a Post" do
    login_as @user
    visit posts_path
    
    click_on "New Post"
    
    fill_in "Title", with: "System Test Post"
    fill_in "Content", with: "Created via system test"
    check "Published"
    
    click_on "Create Post"
    
    assert_text "Post was successfully created"
    assert_current_path post_path(Post.last)
    assert_text "System Test Post"
  end
  
  test "updating a Post" do
    login_as @user
    visit post_path(@post)
    
    click_on "Edit"
    
    fill_in "Title", with: "Updated Post Title"
    click_on "Update Post"
    
    assert_text "Post was successfully updated"
    assert_text "Updated Post Title"
  end
  
  test "destroying a Post" do
    login_as @user
    visit post_path(@post)
    
    accept_confirm do
      click_on "Delete"
    end
    
    assert_text "Post was successfully deleted"
    assert_current_path posts_path
  end
  
  # Test JavaScript interactions
  test "commenting with AJAX" do
    login_as @user
    visit post_path(@post)
    
    fill_in "Comment", with: "This is a test comment"
    click_button "Post Comment"
    
    assert_text "This is a test comment"
    assert_field "Comment", with: "" # Form should be reset
  end
  
  # Test responsive design
  test "mobile navigation" do
    resize_to "mobile"
    visit root_path
    
    assert_selector ".mobile-menu-toggle"
    click_button "Menu"
    assert_selector ".mobile-menu.open"
  end
end
```

### Test Configuration
```ruby
# test/application_system_test_case.rb
require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  
  # Helper methods for system tests
  def login_as(user)
    visit login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Log In"
  end
  
  def resize_to(size)
    case size
    when "mobile"
      page.driver.browser.manage.window.resize_to(375, 667)
    when "tablet"
      page.driver.browser.manage.window.resize_to(768, 1024)
    when "desktop"
      page.driver.browser.manage.window.resize_to(1400, 1400)
    end
  end
end
```

## RSpec Alternative

### RSpec Setup
```ruby
# Gemfile
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'database_cleaner-active_record'
  gem 'shoulda-matchers'
end
```

```bash
# Installation
rails generate rspec:install
```

### RSpec Configuration
```ruby
# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rspec/rails'

# Shoulda matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  
  # Include Factory Bot methods
  config.include FactoryBot::Syntax::Methods
  
  # Include custom helpers
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :system
end
```

### RSpec Model Tests
```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_length_of(:name).is_at_least(2) }
  end
  
  describe 'associations' do
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_one(:profile).dependent(:destroy) }
  end
  
  describe 'scopes' do
    let!(:active_user) { create(:user, active: true) }
    let!(:inactive_user) { create(:user, active: false) }
    
    describe '.active' do
      it 'returns only active users' do
        expect(User.active).to include(active_user)
        expect(User.active).not_to include(inactive_user)
      end
    end
  end
  
  describe '#full_name' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }
    
    it 'returns the full name' do
      expect(user.full_name).to eq('John Doe')
    end
    
    context 'when last name is missing' do
      let(:user) { build(:user, first_name: 'John', last_name: nil) }
      
      it 'returns only first name' do
        expect(user.full_name).to eq('John')
      end
    end
  end
  
  describe 'callbacks' do
    it 'normalizes email before save' do
      user = build(:user, email: '  TEST@EXAMPLE.COM  ')
      user.save
      expect(user.email).to eq('test@example.com')
    end
  end
end
```

### Factory Bot
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password' }
    active { true }
    
    trait :inactive do
      active { false }
    end
    
    trait :admin do
      role { 'admin' }
    end
    
    factory :admin_user, traits: [:admin]
  end
end

# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    published { true }
    association :user
    
    trait :draft do
      published { false }
    end
    
    trait :with_comments do
      after(:create) do |post|
        create_list(:comment, 3, post: post)
      end
    end
  end
end
```

### RSpec Controller Tests
```ruby
# spec/controllers/posts_controller_spec.rb
require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user) }
  
  before { sign_in user }
  
  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end
    
    it 'assigns published posts' do
      published_post = create(:post, published: true)
      draft_post = create(:post, :draft)
      
      get :index
      expect(assigns(:posts)).to include(published_post)
      expect(assigns(:posts)).not_to include(draft_post)
    end
  end
  
  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: post.id }
      expect(response).to be_successful
    end
  end
  
  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        { title: 'New Post', content: 'Post content', published: true }
      end
      
      it 'creates a new Post' do
        expect {
          post :create, params: { post: valid_attributes }
        }.to change(Post, :count).by(1)
      end
      
      it 'redirects to the created post' do
        post :create, params: { post: valid_attributes }
        expect(response).to redirect_to(Post.last)
      end
    end
    
    context 'with invalid parameters' do
      let(:invalid_attributes) { { title: '', content: '' } }
      
      it 'does not create a new Post' do
        expect {
          post :create, params: { post: invalid_attributes }
        }.not_to change(Post, :count)
      end
      
      it 'renders new template' do
        post :create, params: { post: invalid_attributes }
        expect(response).to render_template(:new)
      end
    end
  end
end
```

## Test Data and Fixtures

### Fixtures (Minitest)
```yaml
# test/fixtures/users.yml
one:
  name: User One
  email: user1@example.com
  active: true

two:
  name: User Two
  email: user2@example.com
  active: false

admin:
  name: Admin User
  email: admin@example.com
  active: true
  role: admin

# test/fixtures/posts.yml
published:
  title: Published Post
  content: This is a published post
  published: true
  user: one

draft:
  title: Draft Post
  content: This is a draft post
  published: false
  user: one
```

### Database Cleaner (RSpec)
```ruby
# spec/support/database_cleaner.rb
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
```

## Testing Best Practices

### Test Organization
```ruby
# Good: Descriptive test names
test "should not save user without email" do
  user = User.new(name: "Test")
  assert_not user.save
end

# Good: Group related tests
class UserTest < ActiveSupport::TestCase
  describe "validations" do
    # validation tests
  end
  
  describe "associations" do
    # association tests
  end
  
  describe "instance methods" do
    # method tests
  end
end
```

### Test Helpers
```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  def sign_in(user)
    post login_path, params: { email: user.email, password: 'password' }
  end
  
  def sign_out
    delete logout_path
  end
  
  def json_response
    JSON.parse(response.body)
  end
  
  def assert_json_response(expected)
    assert_equal expected, json_response
  end
end
```

### Performance Testing
```ruby
# test/performance/posts_test.rb
require 'test_helper'

class PostsPerformanceTest < ActionDispatch::IntegrationTest
  test "posts index performance" do
    create_posts(100)
    
    assert_performs_better_than(100) do
      get posts_path
    end
  end
  
  private
  
  def create_posts(count)
    count.times do |i|
      Post.create!(
        title: "Post #{i}",
        content: "Content for post #{i}",
        user: users(:one)
      )
    end
  end
  
  def assert_performs_better_than(milliseconds)
    start_time = Time.current
    yield
    duration = (Time.current - start_time) * 1000
    
    assert duration < milliseconds, 
           "Expected operation to take less than #{milliseconds}ms, took #{duration.round(2)}ms"
  end
end
```

### Testing Commands
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run specific test method
rails test test/models/user_test.rb::UserTest#test_should_be_valid

# Run tests with coverage
rails test

# Run system tests
rails test:system

# Run tests in parallel
rails test PARALLEL_WORKERS=4

# RSpec commands
bundle exec rspec
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/models/user_spec.rb:10
```

## References

- [Testing Rails Applications](https://guides.rubyonrails.org/testing.html)
- [RSpec Rails Documentation](https://github.com/rspec/rspec-rails)
- [Factory Bot Documentation](https://github.com/thoughtbot/factory_bot)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)