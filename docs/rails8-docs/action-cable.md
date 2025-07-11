# ActionCable (WebSockets)

## Overview

ActionCable provides WebSocket functionality for Rails applications, enabling real-time features like chat, notifications, live updates, and collaborative editing. It integrates seamlessly with Rails and supports both server-side and client-side components.

## Basic Setup

### Installation and Configuration
```ruby
# ActionCable is included by default in Rails
# config/cable.yml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: myapp_production
```

### Mount ActionCable
```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  # other routes...
end
```

### Cable Configuration
```ruby
# config/environments/development.rb
Rails.application.configure do
  config.action_cable.disable_request_forgery_protection = true
  config.action_cable.url = "ws://localhost:3000/cable"
  config.action_cable.allowed_request_origins = [
    "http://localhost:3000",
    /http:\/\/localhost*/
  ]
end

# config/environments/production.rb
Rails.application.configure do
  config.action_cable.url = "wss://example.com/cable"
  config.action_cable.allowed_request_origins = [
    "https://example.com",
    "https://www.example.com"
  ]
  
  # Use Redis for production
  config.action_cable.adapter = :redis
  config.action_cable.cable = {
    "adapter" => "redis",
    "url" => ENV['REDIS_URL']
  }
end
```

## Channels

### Creating Channels
```bash
# Generate a channel
rails generate channel Chat

# Generate channel with actions
rails generate channel Notifications notify update
```

### Basic Channel Structure
```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    # Called when the consumer successfully subscribes
    stream_from "chat_#{params[:room_id]}"
    
    # Log the subscription
    Rails.logger.info "User #{current_user&.id} subscribed to chat room #{params[:room_id]}"
  end

  def unsubscribed
    # Called when the consumer unsubscribes
    Rails.logger.info "User #{current_user&.id} unsubscribed from chat room #{params[:room_id]}"
  end

  def speak(data)
    # Action called from client
    message = current_user.messages.create!(
      content: data['message'],
      room_id: params[:room_id]
    )
    
    # Broadcast to all subscribers
    ActionCable.server.broadcast(
      "chat_#{params[:room_id]}",
      {
        message: message.content,
        user: current_user.name,
        timestamp: message.created_at.strftime('%H:%M')
      }
    )
  end
  
  def typing(data)
    # Broadcast typing indicator
    broadcast_to_others(
      user: current_user.name,
      typing: data['typing']
    )
  end
  
  private
  
  def broadcast_to_others(data)
    ActionCable.server.broadcast(
      "chat_#{params[:room_id]}_typing",
      data.merge(user_id: current_user.id)
    )
  end
end
```

### Application Cable Channel
```ruby
# app/channels/application_cable/channel.rb
module ApplicationCable
  class Channel < ActionCable::Channel::Base
    # Common functionality for all channels
    
    protected
    
    def current_user
      @current_user ||= User.find(connection.current_user_id) if connection.current_user_id
    end
    
    def ensure_authenticated!
      reject unless current_user
    end
    
    def ensure_authorized!(resource)
      reject unless current_user.can?(:access, resource)
    end
  end
end
```

## Connection Authentication

### Connection Class
```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user_id
    
    def connect
      self.current_user_id = find_verified_user_id
    end
    
    private
    
    def find_verified_user_id
      # Cookie-based authentication
      if session_user_id = cookies.encrypted[:user_id]
        user = User.find_by(id: session_user_id)
        return user.id if user
      end
      
      # Token-based authentication
      if token = request.params[:token]
        user = User.find_by(auth_token: token)
        return user.id if user
      end
      
      # JWT authentication
      if jwt_token = request.headers['Authorization']&.split(' ')&.last
        decoded_token = JWT.decode(jwt_token, Rails.application.secret_key_base).first
        user = User.find_by(id: decoded_token['user_id'])
        return user.id if user
      end
      
      reject_unauthorized_connection
    rescue JWT::DecodeError
      reject_unauthorized_connection
    end
  end
end
```

### Advanced Authentication
```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :session_id
    
    def connect
      self.current_user = find_verified_user
      self.session_id = SecureRandom.hex
      
      logger.add_tags "ActionCable", "User #{current_user.id}", "Session #{session_id}"
    end
    
    def disconnect
      # Cleanup when user disconnects
      UserPresence.offline(current_user)
    end
    
    private
    
    def find_verified_user
      # Multiple authentication strategies
      user = authenticate_with_cookies || 
             authenticate_with_token || 
             authenticate_with_session
             
      user || reject_unauthorized_connection
    end
    
    def authenticate_with_cookies
      if user_id = cookies.encrypted[:user_id]
        User.find_by(id: user_id)
      end
    end
    
    def authenticate_with_token
      if token = request.params[:token]
        User.find_by(auth_token: token)
      end
    end
    
    def authenticate_with_session
      if session[:user_id]
        User.find_by(id: session[:user_id])
      end
    end
  end
end
```

## Client-Side JavaScript

### Basic Connection
```javascript
// app/javascript/channels/index.js
import { createConsumer } from "@rails/actioncable"

export default createConsumer()

// app/javascript/channels/chat_channel.js
import consumer from "./index"

const chatChannel = consumer.subscriptions.create(
  { 
    channel: "ChatChannel", 
    room_id: document.getElementById('room-id').value 
  },
  {
    connected() {
      console.log("Connected to chat channel")
      this.install()
    },

    disconnected() {
      console.log("Disconnected from chat channel")
      this.uninstall()
    },

    received(data) {
      console.log("Received:", data)
      this.appendMessage(data)
    },

    speak(message) {
      this.perform('speak', { message: message })
    },
    
    typing(isTyping) {
      this.perform('typing', { typing: isTyping })
    },

    install() {
      const messageForm = document.getElementById('message-form')
      const messageInput = document.getElementById('message-input')
      
      messageForm.addEventListener('submit', (event) => {
        event.preventDefault()
        const message = messageInput.value.trim()
        if (message) {
          this.speak(message)
          messageInput.value = ''
        }
      })
      
      // Typing indicator
      let typingTimer
      messageInput.addEventListener('input', () => {
        this.typing(true)
        clearTimeout(typingTimer)
        typingTimer = setTimeout(() => {
          this.typing(false)
        }, 1000)
      })
    },

    uninstall() {
      // Cleanup event listeners
    },

    appendMessage(data) {
      const messagesContainer = document.getElementById('messages')
      const messageElement = document.createElement('div')
      messageElement.className = 'message'
      messageElement.innerHTML = `
        <div class="message-header">
          <span class="user">${data.user}</span>
          <span class="timestamp">${data.timestamp}</span>
        </div>
        <div class="message-content">${data.message}</div>
      `
      messagesContainer.appendChild(messageElement)
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
)

// Export for external use
window.chatChannel = chatChannel
```

### Advanced Client Features
```javascript
// app/javascript/channels/notifications_channel.js
import consumer from "./index"

class NotificationsChannel {
  constructor() {
    this.subscription = null
    this.connect()
  }
  
  connect() {
    this.subscription = consumer.subscriptions.create(
      "NotificationsChannel",
      {
        connected: () => this.onConnected(),
        disconnected: () => this.onDisconnected(),
        received: (data) => this.onReceived(data),
        rejected: () => this.onRejected()
      }
    )
  }
  
  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }
  
  onConnected() {
    console.log("Connected to notifications")
    this.updateConnectionStatus("connected")
  }
  
  onDisconnected() {
    console.log("Disconnected from notifications")
    this.updateConnectionStatus("disconnected")
    
    // Attempt to reconnect after delay
    setTimeout(() => {
      if (!this.subscription) {
        this.connect()
      }
    }, 5000)
  }
  
  onReceived(data) {
    switch(data.type) {
      case 'message':
        this.showNotification(data)
        break
      case 'update':
        this.handleUpdate(data)
        break
      case 'alert':
        this.showAlert(data)
        break
    }
  }
  
  onRejected() {
    console.error("Subscription rejected")
    this.updateConnectionStatus("rejected")
  }
  
  showNotification(data) {
    // Use browser notifications API
    if (Notification.permission === "granted") {
      new Notification(data.title, {
        body: data.message,
        icon: "/icon.png"
      })
    }
    
    // Also show in-app notification
    this.createToast(data)
  }
  
  createToast(data) {
    const toast = document.createElement('div')
    toast.className = 'toast'
    toast.innerHTML = `
      <div class="toast-header">
        <strong>${data.title}</strong>
        <button type="button" class="close" onclick="this.parentElement.parentElement.remove()">×</button>
      </div>
      <div class="toast-body">${data.message}</div>
    `
    
    document.getElementById('notifications-container').appendChild(toast)
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (toast.parentElement) {
        toast.parentElement.removeChild(toast)
      }
    }, 5000)
  }
  
  updateConnectionStatus(status) {
    const indicator = document.getElementById('connection-status')
    if (indicator) {
      indicator.className = `connection-status ${status}`
      indicator.textContent = status
    }
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  window.notificationsChannel = new NotificationsChannel()
  
  // Request notification permission
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission()
  }
})
```

## Real-Time Features

### Live Chat Implementation
```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :user
  belongs_to :room
  
  validates :content, presence: true
  
  after_create_commit :broadcast_message
  
  private
  
  def broadcast_message
    ActionCable.server.broadcast(
      "chat_#{room_id}",
      {
        id: id,
        content: content,
        user: user.name,
        avatar_url: user.avatar.attached? ? Rails.application.routes.url_helpers.url_for(user.avatar) : nil,
        timestamp: created_at.strftime('%H:%M'),
        user_id: user.id
      }
    )
  end
end

# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def create
    @message = current_user.messages.build(message_params)
    @message.room = Room.find(params[:room_id])
    
    if @message.save
      head :ok
    else
      render json: { errors: @message.errors }, status: :unprocessable_entity
    end
  end
  
  private
  
  def message_params
    params.require(:message).permit(:content)
  end
end
```

### Live Notifications
```ruby
# app/channels/notifications_channel.rb
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
  
  def mark_as_read(data)
    notification = current_user.notifications.find(data['notification_id'])
    notification.update!(read_at: Time.current)
    
    # Broadcast read status to other sessions
    NotificationsChannel.broadcast_to(
      current_user,
      {
        type: 'read',
        notification_id: notification.id
      }
    )
  end
end

# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true
  
  scope :unread, -> { where(read_at: nil) }
  
  after_create_commit :broadcast_to_user
  
  private
  
  def broadcast_to_user
    NotificationsChannel.broadcast_to(
      user,
      {
        type: 'notification',
        id: id,
        title: title,
        message: message,
        url: url,
        created_at: created_at.iso8601
      }
    )
  end
end
```

### Live Updates
```ruby
# app/channels/post_channel.rb
class PostChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find(params[:post_id])
    ensure_authorized!(post)
    stream_for post
  end
  
  def update_content(data)
    post = Post.find(params[:post_id])
    ensure_authorized!(post)
    
    if post.update(content: data['content'])
      PostChannel.broadcast_to(
        post,
        {
          type: 'content_updated',
          content: post.content,
          updated_by: current_user.name,
          updated_at: post.updated_at.iso8601
        }
      )
    end
  end
  
  private
  
  def ensure_authorized!(post)
    reject unless current_user.can?(:edit, post)
  end
end
```

## Broadcasting

### Model Broadcasting
```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user
  
  # Broadcast after creation
  after_create_commit :broadcast_creation
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_deletion
  
  private
  
  def broadcast_creation
    ActionCable.server.broadcast(
      'posts',
      {
        type: 'post_created',
        post: {
          id: id,
          title: title,
          content: content,
          author: user.name,
          created_at: created_at.iso8601
        }
      }
    )
  end
  
  def broadcast_update
    ActionCable.server.broadcast(
      "post_#{id}",
      {
        type: 'post_updated',
        post: {
          id: id,
          title: title,
          content: content,
          updated_at: updated_at.iso8601
        }
      }
    )
  end
  
  def broadcast_deletion
    ActionCable.server.broadcast(
      'posts',
      {
        type: 'post_deleted',
        post_id: id
      }
    )
  end
end
```

### Job Broadcasting
```ruby
# app/jobs/notification_broadcast_job.rb
class NotificationBroadcastJob < ApplicationJob
  queue_as :default
  
  def perform(user_ids, notification_data)
    User.where(id: user_ids).find_each do |user|
      NotificationsChannel.broadcast_to(
        user,
        notification_data.merge(user_id: user.id)
      )
    end
  end
end

# Usage
user_ids = User.active.pluck(:id)
NotificationBroadcastJob.perform_later(
  user_ids,
  {
    type: 'system_announcement',
    title: 'System Maintenance',
    message: 'Scheduled maintenance tonight at 2 AM'
  }
)
```

## Performance and Scaling

### Connection Monitoring
```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user_id, :session_id
    
    def connect
      self.current_user_id = find_verified_user_id
      self.session_id = SecureRandom.hex
      
      # Track connection
      ConnectionTracker.connected(current_user_id, session_id)
      
      logger.add_tags "ActionCable", current_user_id, session_id
    end
    
    def disconnect
      # Track disconnection
      ConnectionTracker.disconnected(current_user_id, session_id)
    end
  end
end

# app/services/connection_tracker.rb
class ConnectionTracker
  def self.connected(user_id, session_id)
    Rails.cache.increment("connections:#{user_id}", 1)
    Rails.cache.set("session:#{session_id}", user_id, expires_in: 1.hour)
  end
  
  def self.disconnected(user_id, session_id)
    Rails.cache.decrement("connections:#{user_id}", 1)
    Rails.cache.delete("session:#{session_id}")
  end
  
  def self.user_connections(user_id)
    Rails.cache.read("connections:#{user_id}") || 0
  end
  
  def self.total_connections
    Rails.cache.read("total_connections") || 0
  end
end
```

### Redis Configuration
```ruby
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: myapp_production
  
  # Redis connection pool
  pool: 5
  timeout: 5
  
  # Redis configuration
  redis:
    connect_timeout: 30
    read_timeout: 30
    write_timeout: 30
    reconnect_attempts: 3
```

## Testing

### Channel Tests
```ruby
# test/channels/chat_channel_test.rb
require 'test_helper'

class ChatChannelTest < ActionCable::Channel::TestCase
  setup do
    @user = users(:one)
    @room = rooms(:one)
  end
  
  test "subscribes to chat channel" do
    stub_connection current_user_id: @user.id
    
    subscribe room_id: @room.id
    
    assert subscription.confirmed?
    assert_has_stream "chat_#{@room.id}"
  end
  
  test "rejects subscription without user" do
    subscribe room_id: @room.id
    
    assert subscription.rejected?
  end
  
  test "broadcasts message when speaking" do
    stub_connection current_user_id: @user.id
    subscribe room_id: @room.id
    
    assert_broadcast_on("chat_#{@room.id}", message: "Hello", user: @user.name) do
      perform :speak, message: "Hello"
    end
  end
  
  test "creates message record when speaking" do
    stub_connection current_user_id: @user.id
    subscribe room_id: @room.id
    
    assert_difference 'Message.count', 1 do
      perform :speak, message: "Hello"
    end
    
    message = Message.last
    assert_equal "Hello", message.content
    assert_equal @user, message.user
    assert_equal @room, message.room
  end
end
```

### Integration Tests
```ruby
# test/integration/action_cable_test.rb
require 'test_helper'

class ActionCableTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper
  
  setup do
    @user = users(:one)
    @room = rooms(:one)
  end
  
  test "chat message flow" do
    # Connect to ActionCable
    connect_to_channel(ChatChannel, room_id: @room.id, current_user_id: @user.id)
    
    # Send message via HTTP
    post room_messages_path(@room), params: {
      message: { content: "Hello from integration test" }
    }, as: :json
    
    assert_response :success
    
    # Verify broadcast
    assert_broadcast_on("chat_#{@room.id}") do
      # Broadcast happens in model callback
    end
  end
end
```

## Security Considerations

### CSRF Protection
```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    def connect
      # Verify origin
      if request.origin.present?
        allowed_origins = Rails.application.config.action_cable.allowed_request_origins
        reject_unauthorized_connection unless origin_allowed?(request.origin, allowed_origins)
      end
      
      self.current_user_id = find_verified_user_id
    end
    
    private
    
    def origin_allowed?(origin, allowed_origins)
      case allowed_origins
      when String
        origin == allowed_origins
      when Array
        allowed_origins.any? { |allowed| origin_matches?(origin, allowed) }
      else
        false
      end
    end
    
    def origin_matches?(origin, allowed)
      case allowed
      when String
        origin == allowed
      when Regexp
        origin =~ allowed
      else
        false
      end
    end
  end
end
```

### Rate Limiting
```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def speak(data)
    # Rate limiting
    unless rate_limit_check
      reject
      return
    end
    
    # Process message...
  end
  
  private
  
  def rate_limit_check
    key = "rate_limit:chat:#{current_user.id}"
    count = Rails.cache.read(key) || 0
    
    if count >= 10  # Max 10 messages per minute
      false
    else
      Rails.cache.write(key, count + 1, expires_in: 1.minute)
      true
    end
  end
end
```

## References

- [Action Cable Overview](https://guides.rubyonrails.org/action_cable_overview.html)
- [Action Cable API](https://api.rubyonrails.org/classes/ActionCable.html)
- [WebSocket Protocol](https://tools.ietf.org/html/rfc6455)
- [Rails WebSocket Testing](https://guides.rubyonrails.org/testing.html#testing-action-cable)