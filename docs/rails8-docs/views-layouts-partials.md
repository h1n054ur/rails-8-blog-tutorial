# Views, Layouts & Partials

## Overview

Rails views handle the presentation layer of your application using Action View. Views use ERB (Embedded Ruby) templates to generate HTML, and are organized using layouts for consistent structure and partials for reusable components.

## Basic View Structure

### ERB Templates
```erb
<!-- app/views/posts/show.html.erb -->
<article class="post">
  <header>
    <h1><%= @post.title %></h1>
    <div class="meta">
      <span class="author">By <%= @post.user.name %></span>
      <time datetime="<%= @post.created_at.iso8601 %>">
        <%= @post.created_at.strftime("%B %d, %Y") %>
      </time>
    </div>
  </header>
  
  <div class="content">
    <%= simple_format(@post.content) %>
  </div>
  
  <footer class="actions">
    <%= link_to "Edit", edit_post_path(@post), class: "btn btn-primary" if can?(:edit, @post) %>
    <%= link_to "Delete", post_path(@post), method: :delete, 
                confirm: "Are you sure?", class: "btn btn-danger" if can?(:destroy, @post) %>
  </footer>
</article>

<%= render 'comments/list', comments: @post.comments %>
```

### ERB Syntax
```erb
<!-- Output with HTML escaping (default) -->
<%= @post.title %>

<!-- Raw output (use carefully) -->
<%== @post.html_content %>

<!-- Ruby code without output -->
<% @posts.each do |post| %>
  <div><%= post.title %></div>
<% end %>

<!-- Comments -->
<%# This is a comment that won't appear in HTML %>

<!-- Conditionals -->
<% if user_signed_in? %>
  <p>Welcome, <%= current_user.name %>!</p>
<% else %>
  <p><%= link_to "Sign in", new_user_session_path %></p>
<% end %>

<!-- Loops -->
<ul>
  <% @posts.each do |post| %>
    <li><%= link_to post.title, post_path(post) %></li>
  <% end %>
</ul>
```

## Layouts

### Application Layout
```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>
      <%= content_for?(:title) ? "#{content_for(:title)} - " : "" %>MyApp
    </title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>
    
    <!-- Additional head content -->
    <%= yield :head %>
  </head>

  <body>
    <header class="navbar">
      <%= render 'shared/navigation' %>
    </header>
    
    <main class="container">
      <!-- Flash messages -->
      <% flash.each do |type, message| %>
        <div class="alert alert-<%= type %>" data-controller="alert">
          <%= message %>
        </div>
      <% end %>
      
      <!-- Page content -->
      <%= yield %>
    </main>
    
    <footer>
      <%= render 'shared/footer' %>
    </footer>
    
    <!-- Additional body content -->
    <%= yield :bottom %>
  </body>
</html>
```

### Multiple Layouts
```ruby
# app/controllers/admin_controller.rb
class AdminController < ApplicationController
  layout 'admin'
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  layout 'blog', only: [:show, :index]
  layout false, only: [:preview]  # No layout
  
  def show
    # Uses 'blog' layout
  end
  
  def edit
    # Uses default 'application' layout
  end
  
  def preview
    # No layout
    render layout: false
  end
end
```

### Custom Layouts
```erb
<!-- app/views/layouts/admin.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>Admin - MyApp</title>
    <%= stylesheet_link_tag "admin" %>
    <%= javascript_include_tag "admin" %>
  </head>
  
  <body class="admin-body">
    <div class="admin-sidebar">
      <%= render 'admin/navigation' %>
    </div>
    
    <div class="admin-content">
      <%= yield %>
    </div>
  </body>
</html>
```

### Content Blocks
```erb
<!-- In views -->
<% content_for :title, "Posts Index" %>
<% content_for :head do %>
  <meta name="description" content="List of blog posts">
  <%= stylesheet_link_tag "posts" %>
<% end %>

<% content_for :bottom do %>
  <%= javascript_include_tag "posts" %>
<% end %>

<h1>Posts</h1>
<!-- Page content -->
```

## Partials

### Basic Partials
```erb
<!-- app/views/posts/_post.html.erb -->
<article class="post-summary" id="post_<%= post.id %>">
  <h3><%= link_to post.title, post_path(post) %></h3>
  <p class="excerpt"><%= truncate(post.content, length: 150) %></p>
  <div class="meta">
    <span class="author"><%= post.user.name %></span>
    <span class="date"><%= post.created_at.strftime("%b %d, %Y") %></span>
  </div>
</article>
```

### Rendering Partials
```erb
<!-- app/views/posts/index.html.erb -->
<div class="posts">
  <!-- Render single partial -->
  <%= render 'post', post: @featured_post %>
  
  <!-- Render collection -->
  <%= render @posts %>
  <!-- Equivalent to: -->
  <%= render partial: 'post', collection: @posts %>
  
  <!-- With custom locals -->
  <%= render partial: 'post', collection: @posts, locals: { show_author: true } %>
  
  <!-- With spacer template -->
  <%= render partial: 'post', collection: @posts, spacer_template: 'post_separator' %>
</div>
```

### Partial with Locals
```erb
<!-- app/views/shared/_card.html.erb -->
<div class="card <%= css_class %>">
  <% if title.present? %>
    <div class="card-header">
      <h3><%= title %></h3>
    </div>
  <% end %>
  
  <div class="card-body">
    <%= content %>
  </div>
  
  <% if actions.present? %>
    <div class="card-footer">
      <%= actions %>
    </div>
  <% end %>
</div>
```

```erb
<!-- Usage -->
<%= render 'shared/card', 
    title: "User Profile", 
    css_class: "user-card",
    content: render('users/profile', user: @user),
    actions: link_to("Edit", edit_user_path(@user)) %>
```

### Collection Partials
```erb
<!-- app/views/comments/_comment.html.erb -->
<div class="comment" data-comment-id="<%= comment.id %>">
  <div class="comment-author">
    <%= comment.user.name %>
    <span class="comment-date"><%= time_ago_in_words(comment.created_at) %> ago</span>
  </div>
  <div class="comment-content">
    <%= simple_format(comment.content) %>
  </div>
</div>

<!-- app/views/posts/show.html.erb -->
<div class="comments">
  <h3>Comments</h3>
  <%= render @post.comments %>
  <!-- Rails automatically uses comments/_comment.html.erb -->
</div>
```

### Shared Partials
```erb
<!-- app/views/shared/_flash_messages.html.erb -->
<% flash.each do |type, message| %>
  <div class="alert alert-<%= type %>" data-controller="alert" data-alert-timeout-value="5000">
    <%= message %>
    <button type="button" class="close" data-action="click->alert#close">
      <span>&times;</span>
    </button>
  </div>
<% end %>

<!-- app/views/shared/_form_errors.html.erb -->
<% if object.errors.any? %>
  <div class="error-container">
    <h4><%= pluralize(object.errors.count, "error") %> prohibited this <%= object.class.name.downcase %> from being saved:</h4>
    <ul>
      <% object.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

## View Helpers

### Built-in Helpers
```erb
<!-- Text helpers -->
<%= truncate(@post.content, length: 100) %>
<%= simple_format(@post.content) %>
<%= pluralize(@posts.count, 'post') %>
<%= word_wrap(@post.content, line_width: 80) %>

<!-- Date/time helpers -->
<%= time_ago_in_words(@post.created_at) %>
<%= distance_of_time_in_words(@post.created_at, @post.updated_at) %>
<%= @post.created_at.strftime("%B %d, %Y at %I:%M %p") %>

<!-- Number helpers -->
<%= number_to_currency(@product.price) %>
<%= number_with_delimiter(@post.views_count) %>
<%= number_to_percentage(@score, precision: 1) %>

<!-- URL helpers -->
<%= link_to "Edit Post", edit_post_path(@post), class: "btn" %>
<%= mail_to @user.email, "Contact #{@user.name}" %>
<%= url_for(@post) %>

<!-- Tag helpers -->
<%= content_tag :div, "Hello", class: "greeting", id: "main" %>
<%= tag.div "Hello", class: "greeting", data: { toggle: "modal" } %>
```

### Custom Helpers
```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def page_title(title = nil)
    if title.present?
      content_for(:title, title)
      title
    else
      content_for?(:title) ? content_for(:title) : "MyApp"
    end
  end
  
  def active_link_class(path)
    current_page?(path) ? 'active' : ''
  end
  
  def bootstrap_flash_class(type)
    case type.to_s
    when 'notice' then 'success'
    when 'alert' then 'danger'
    when 'warning' then 'warning'
    else 'info'
    end
  end
  
  def user_avatar(user, size: 'md')
    size_class = case size
                 when 'sm' then 'w-8 h-8'
                 when 'lg' then 'w-16 h-16'
                 else 'w-12 h-12'
                 end
    
    if user.avatar.attached?
      image_tag user.avatar, class: "rounded-full #{size_class}"
    else
      content_tag :div, user.initials, class: "rounded-full #{size_class} bg-gray-300 flex items-center justify-center"
    end
  end
end

# app/helpers/posts_helper.rb
module PostsHelper
  def post_status_badge(post)
    css_class = case post.status
                when 'published' then 'badge-success'
                when 'draft' then 'badge-warning'
                when 'archived' then 'badge-secondary'
                else 'badge-primary'
                end
    
    content_tag :span, post.status.humanize, class: "badge #{css_class}"
  end
  
  def reading_time(content)
    words_per_minute = 200
    word_count = content.split.size
    minutes = (word_count / words_per_minute.to_f).ceil
    
    "#{minutes} min read"
  end
end
```

## Forms and Form Helpers

### Form Helpers
```erb
<!-- app/views/posts/_form.html.erb -->
<%= form_with model: @post, local: true do |form| %>
  <%= render 'shared/form_errors', object: @post %>
  
  <div class="field">
    <%= form.label :title %>
    <%= form.text_field :title, class: 'form-control' %>
  </div>
  
  <div class="field">
    <%= form.label :content %>
    <%= form.text_area :content, rows: 10, class: 'form-control' %>
  </div>
  
  <div class="field">
    <%= form.label :category_id %>
    <%= form.collection_select :category_id, Category.all, :id, :name, 
                               { prompt: "Select a category" }, 
                               { class: 'form-control' } %>
  </div>
  
  <div class="field">
    <%= form.collection_check_boxes :tag_ids, Tag.all, :id, :name do |builder| %>
      <div class="checkbox">
        <%= builder.check_box %>
        <%= builder.label %>
      </div>
    <% end %>
  </div>
  
  <div class="field">
    <%= form.check_box :published %>
    <%= form.label :published %>
  </div>
  
  <div class="actions">
    <%= form.submit class: 'btn btn-primary' %>
    <%= link_to 'Cancel', posts_path, class: 'btn btn-secondary' %>
  </div>
<% end %>
```

### AJAX Forms
```erb
<!-- Remote form -->
<%= form_with model: @comment, remote: true do |form| %>
  <%= form.text_area :content, placeholder: "Add a comment..." %>
  <%= form.submit "Post Comment" %>
<% end %>
```

```erb
<!-- app/views/comments/create.turbo_stream.erb -->
<%= turbo_stream.append "comments" do %>
  <%= render @comment %>
<% end %>

<%= turbo_stream.update "comment_form" do %>
  <%= render 'form', comment: Comment.new %>
<% end %>
```

## Asset Helpers

### Image and Asset Helpers
```erb
<!-- Images -->
<%= image_tag "logo.png", alt: "Company Logo", class: "logo" %>
<%= image_tag @user.avatar, alt: @user.name if @user.avatar.attached? %>

<!-- Stylesheets and JavaScript -->
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
<%= javascript_include_tag "application", defer: true %>

<!-- Asset paths -->
<%= asset_path "logo.png" %>
<%= asset_url "logo.png" %>

<!-- Preload assets -->
<%= preload_link_tag asset_path("hero-image.jpg"), as: :image %>
```

## Advanced View Patterns

### View Objects
```ruby
# app/views/objects/post_presenter.rb
class PostPresenter
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers
  
  def initialize(post, view_context)
    @post = post
    @view_context = view_context
  end
  
  def title_with_status
    status_icon = @post.published? ? "✓" : "✎"
    "#{status_icon} #{@post.title}"
  end
  
  def formatted_content
    simple_format(truncate(@post.content, length: 300))
  end
  
  def edit_link
    return unless can_edit?
    
    link_to "Edit", edit_post_path(@post), class: "btn btn-primary"
  end
  
  private
  
  def can_edit?
    @view_context.can?(:edit, @post)
  end
end
```

### Decorator Pattern
```ruby
# app/decorators/user_decorator.rb
class UserDecorator < SimpleDelegator
  include ActionView::Helpers
  
  def full_name_with_title
    "#{title} #{full_name}".strip
  end
  
  def avatar_or_initials(size: 'md')
    if avatar.attached?
      image_tag avatar, class: avatar_classes(size)
    else
      content_tag :div, initials, class: initials_classes(size)
    end
  end
  
  def membership_duration
    return "New member" unless created_at
    
    "Member for #{time_ago_in_words(created_at)}"
  end
  
  private
  
  def avatar_classes(size)
    base_classes = "rounded-full object-cover"
    size_class = size == 'lg' ? 'w-16 h-16' : 'w-8 h-8'
    "#{base_classes} #{size_class}"
  end
  
  def initials_classes(size)
    base_classes = "rounded-full bg-gray-300 flex items-center justify-center text-gray-700"
    size_class = size == 'lg' ? 'w-16 h-16 text-lg' : 'w-8 h-8 text-sm'
    "#{base_classes} #{size_class}"
  end
end

# Usage in controller
def show
  @user = UserDecorator.new(User.find(params[:id]))
end
```

## View Testing

### View Tests
```ruby
# test/views/posts/show_test.rb
require 'test_helper'

class PostsShowViewTest < ActionView::TestCase
  setup do
    @post = posts(:published)
    @user = users(:author)
  end
  
  test "displays post title and content" do
    assign(:post, @post)
    render template: 'posts/show'
    
    assert_select 'h1', @post.title
    assert_select '.content', text: @post.content
  end
  
  test "shows edit link for post owner" do
    assign(:post, @post)
    
    def can?(action, object)
      true
    end
    
    render template: 'posts/show'
    assert_select 'a[href=?]', edit_post_path(@post), text: 'Edit'
  end
end
```

### Helper Tests
```ruby
# test/helpers/application_helper_test.rb
require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "page_title with custom title" do
    assert_equal "Custom Title", page_title("Custom Title")
    assert_equal "Custom Title", content_for(:title)
  end
  
  test "page_title without custom title" do
    assert_equal "MyApp", page_title
  end
  
  test "active_link_class returns active for current page" do
    stubs(:current_page?).returns(true)
    assert_equal 'active', active_link_class('/posts')
  end
end
```

## Performance Optimization

### Caching Views
```erb
<!-- Fragment caching -->
<% cache @post do %>
  <%= render @post %>
<% end %>

<!-- Collection caching -->
<%= render partial: 'post', collection: @posts, cached: true %>

<!-- Cache with custom key -->
<% cache [@post, current_user] do %>
  <%= render 'post_with_user_actions' %>
<% end %>
```

### Lazy Loading
```erb
<!-- Use lazy loading for images -->
<%= image_tag @post.featured_image, loading: "lazy", alt: @post.title %>

<!-- Conditional rendering -->
<% if @post.comments.loaded? %>
  <%= render @post.comments %>
<% else %>
  <%= link_to "Load Comments", post_comments_path(@post), remote: true %>
<% end %>
```

## References

- [Action View Overview](https://guides.rubyonrails.org/action_view_overview.html)
- [Layouts and Rendering](https://guides.rubyonrails.org/layouts_and_rendering.html)
- [Form Helpers](https://guides.rubyonrails.org/form_helpers.html)
- [Action View Helpers](https://api.rubyonrails.org/classes/ActionView/Helpers.html)