# Internationalization (I18n)

## Overview

Rails internationalization (I18n) provides a framework for translating applications into multiple languages and localizing content for different regions. It supports translation of text, number formatting, date formatting, and pluralization rules.

## Basic Setup

### Configuration
```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Default locale
    config.i18n.default_locale = :en
    
    # Available locales
    config.i18n.available_locales = [:en, :es, :fr, :de, :ja]
    
    # Load paths for translations
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    
    # Fallback behavior
    config.i18n.fallbacks = true
  end
end

# config/initializers/i18n.rb
I18n.available_locales = [:en, :es, :fr, :de, :ja]
I18n.default_locale = :en

# Exception handling
I18n.exception_handler = lambda do |exception, locale, key, options|
  case exception
  when I18n::MissingTranslation
    Rails.logger.warn "Missing translation: #{key} for locale #{locale}"
    "translation missing: #{key}"
  else
    raise exception
  end
end
```

### Translation Files Structure
```
config/locales/
├── en.yml                  # Default English translations
├── es.yml                  # Spanish translations
├── fr.yml                  # French translations
├── models/
│   ├── user.en.yml
│   ├── user.es.yml
│   └── post.en.yml
├── views/
│   ├── posts.en.yml
│   └── posts.es.yml
└── activerecord.en.yml     # Model/validation translations
```

## Translation Files

### Basic Translation Files
```yaml
# config/locales/en.yml
en:
  app_name: "My Application"
  
  navigation:
    home: "Home"
    about: "About"
    contact: "Contact"
    sign_in: "Sign In"
    sign_out: "Sign Out"
    profile: "Profile"
  
  actions:
    create: "Create"
    update: "Update"
    delete: "Delete"
    edit: "Edit"
    show: "Show"
    back: "Back"
    cancel: "Cancel"
    save: "Save"
    submit: "Submit"
    
  messages:
    welcome: "Welcome to %{app_name}!"
    success:
      created: "%{resource} was successfully created."
      updated: "%{resource} was successfully updated."
      deleted: "%{resource} was successfully deleted."
    errors:
      not_found: "The requested resource was not found."
      access_denied: "You don't have permission to access this resource."
      invalid_credentials: "Invalid email or password."
      
  time:
    formats:
      default: "%B %d, %Y at %I:%M %p"
      short: "%b %d, %Y"
      long: "%A, %B %d, %Y at %I:%M %p"

# config/locales/es.yml
es:
  app_name: "Mi Aplicación"
  
  navigation:
    home: "Inicio"
    about: "Acerca de"
    contact: "Contacto"
    sign_in: "Iniciar Sesión"
    sign_out: "Cerrar Sesión"
    profile: "Perfil"
  
  actions:
    create: "Crear"
    update: "Actualizar"
    delete: "Eliminar"
    edit: "Editar"
    show: "Mostrar"
    back: "Volver"
    cancel: "Cancelar"
    save: "Guardar"
    submit: "Enviar"
    
  messages:
    welcome: "¡Bienvenido a %{app_name}!"
    success:
      created: "%{resource} fue creado exitosamente."
      updated: "%{resource} fue actualizado exitosamente."
      deleted: "%{resource} fue eliminado exitosamente."
    errors:
      not_found: "El recurso solicitado no fue encontrado."
      access_denied: "No tienes permisos para acceder a este recurso."
      invalid_credentials: "Email o contraseña inválidos."
```

### Model Translations
```yaml
# config/locales/models/user.en.yml
en:
  activerecord:
    models:
      user:
        one: "User"
        other: "Users"
    attributes:
      user:
        name: "Name"
        email: "Email"
        password: "Password"
        password_confirmation: "Password Confirmation"
        created_at: "Created At"
        updated_at: "Updated At"
        admin: "Administrator"
        active: "Active"
        
  users:
    form:
      title: "User Information"
      submit: "Save User"
    index:
      title: "All Users"
      new_user: "New User"
    show:
      title: "User Details"
      edit: "Edit User"

# config/locales/models/user.es.yml
es:
  activerecord:
    models:
      user:
        one: "Usuario"
        other: "Usuarios"
    attributes:
      user:
        name: "Nombre"
        email: "Correo Electrónico"
        password: "Contraseña"
        password_confirmation: "Confirmación de Contraseña"
        created_at: "Creado en"
        updated_at: "Actualizado en"
        admin: "Administrador"
        active: "Activo"
        
  users:
    form:
      title: "Información del Usuario"
      submit: "Guardar Usuario"
    index:
      title: "Todos los Usuarios"
      new_user: "Nuevo Usuario"
    show:
      title: "Detalles del Usuario"
      edit: "Editar Usuario"
```

### Validation Messages
```yaml
# config/locales/activerecord.en.yml
en:
  activerecord:
    errors:
      messages:
        record_invalid: "Validation failed: %{errors}"
        restrict_dependent_destroy:
          has_one: "Cannot delete record because a dependent %{record} exists"
          has_many: "Cannot delete record because dependent %{record} exist"
      models:
        user:
          attributes:
            email:
              blank: "Email is required"
              invalid: "Email format is invalid"
              taken: "Email is already taken"
            password:
              blank: "Password is required"
              too_short: "Password must be at least %{count} characters"
            name:
              blank: "Name is required"
              too_short: "Name must be at least %{count} characters"

# config/locales/activerecord.es.yml
es:
  activerecord:
    errors:
      messages:
        record_invalid: "La validación falló: %{errors}"
        restrict_dependent_destroy:
          has_one: "No se puede eliminar el registro porque existe un %{record} dependiente"
          has_many: "No se puede eliminar el registro porque existen %{record} dependientes"
      models:
        user:
          attributes:
            email:
              blank: "El email es requerido"
              invalid: "El formato del email es inválido"
              taken: "El email ya está en uso"
            password:
              blank: "La contraseña es requerida"
              too_short: "La contraseña debe tener al menos %{count} caracteres"
            name:
              blank: "El nombre es requerido"
              too_short: "El nombre debe tener al menos %{count} caracteres"
```

## Using Translations

### In Controllers
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_locale
  
  private
  
  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
  end
  
  def extract_locale
    # Priority order: params, user preference, session, browser, default
    locale = nil
    
    # 1. Check URL parameter
    locale = params[:locale] if params[:locale].present?
    
    # 2. Check user preference
    locale ||= current_user&.locale if current_user.respond_to?(:locale)
    
    # 3. Check session
    locale ||= session[:locale]
    
    # 4. Check Accept-Language header
    locale ||= extract_locale_from_accept_language_header
    
    # Validate locale
    locale if I18n.available_locales.map(&:to_s).include?(locale.to_s)
  end
  
  def extract_locale_from_accept_language_header
    return nil unless request.env['HTTP_ACCEPT_LANGUAGE']
    
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end
  
  def default_url_options
    { locale: I18n.locale }
  end
end

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    
    if @user.save
      flash[:notice] = t('messages.success.created', resource: t('activerecord.models.user.one'))
      redirect_to @user
    else
      flash.now[:alert] = t('messages.errors.validation_failed')
      render :new
    end
  end
  
  def index
    @users = User.all
    @page_title = t('users.index.title')
  end
end
```

### In Views
```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html lang="<%= I18n.locale %>">
  <head>
    <title>
      <%= content_for?(:title) ? "#{content_for(:title)} - " : "" %>
      <%= t('app_name') %>
    </title>
  </head>
  
  <body>
    <nav class="navbar">
      <%= link_to t('navigation.home'), root_path %>
      <%= link_to t('navigation.about'), about_path %>
      <%= link_to t('navigation.contact'), contact_path %>
      
      <div class="user-menu">
        <% if user_signed_in? %>
          <%= link_to t('navigation.profile'), profile_path %>
          <%= link_to t('navigation.sign_out'), destroy_user_session_path, method: :delete %>
        <% else %>
          <%= link_to t('navigation.sign_in'), new_user_session_path %>
        <% end %>
      </div>
      
      <!-- Language switcher -->
      <div class="language-switcher">
        <% I18n.available_locales.each do |locale| %>
          <%= link_to locale.upcase, url_for(locale: locale), 
                      class: ('active' if I18n.locale == locale) %>
        <% end %>
      </div>
    </nav>
    
    <%= yield %>
  </body>
</html>

<!-- app/views/users/index.html.erb -->
<% content_for :title, t('users.index.title') %>

<h1><%= t('users.index.title') %></h1>

<%= link_to t('users.index.new_user'), new_user_path, class: 'btn btn-primary' %>

<table class="table">
  <thead>
    <tr>
      <th><%= t('activerecord.attributes.user.name') %></th>
      <th><%= t('activerecord.attributes.user.email') %></th>
      <th><%= t('activerecord.attributes.user.created_at') %></th>
      <th><%= t('actions.actions') %></th>
    </tr>
  </thead>
  <tbody>
    <% @users.each do |user| %>
      <tr>
        <td><%= user.name %></td>
        <td><%= user.email %></td>
        <td><%= l(user.created_at, format: :short) %></td>
        <td>
          <%= link_to t('actions.show'), user %>
          <%= link_to t('actions.edit'), edit_user_path(user) %>
          <%= link_to t('actions.delete'), user, method: :delete,
                      confirm: t('messages.confirm_delete') %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>

<!-- app/views/users/_form.html.erb -->
<%= form_with model: user, local: true do |form| %>
  <% if user.errors.any? %>
    <div class="alert alert-danger">
      <h4><%= t('errors.messages.validation_failed') %></h4>
      <ul>
        <% user.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-group">
    <%= form.label :name, t('activerecord.attributes.user.name') %>
    <%= form.text_field :name, class: 'form-control' %>
  </div>

  <div class="form-group">
    <%= form.label :email, t('activerecord.attributes.user.email') %>
    <%= form.email_field :email, class: 'form-control' %>
  </div>

  <div class="form-group">
    <%= form.label :password, t('activerecord.attributes.user.password') %>
    <%= form.password_field :password, class: 'form-control' %>
  </div>

  <%= form.submit t('users.form.submit'), class: 'btn btn-primary' %>
  <%= link_to t('actions.cancel'), users_path, class: 'btn btn-secondary' %>
<% end %>
```

### In Models
```ruby
# app/models/user.rb
class User < ApplicationRecord
  validates :name, presence: { message: I18n.t('activerecord.errors.models.user.attributes.name.blank') }
  validates :email, presence: true, uniqueness: true
  
  def display_name
    I18n.t('users.display_name', name: name, email: email)
  end
  
  def status_text
    if active?
      I18n.t('users.status.active')
    else
      I18n.t('users.status.inactive')
    end
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
  
  def published_status
    if published?
      I18n.t('posts.status.published')
    else
      I18n.t('posts.status.draft')
    end
  end
  
  def reading_time
    words = content.split.size
    minutes = (words / 200.0).ceil
    I18n.t('posts.reading_time', count: minutes)
  end
end
```

## Advanced Features

### Pluralization
```yaml
# config/locales/en.yml
en:
  posts:
    reading_time:
      one: "%{count} minute read"
      other: "%{count} minutes read"
    comments:
      zero: "No comments"
      one: "1 comment"
      other: "%{count} comments"
  
  users:
    followers:
      zero: "No followers"
      one: "1 follower"
      other: "%{count} followers"

# config/locales/es.yml
es:
  posts:
    reading_time:
      one: "Lectura de %{count} minuto"
      other: "Lectura de %{count} minutos"
    comments:
      zero: "Sin comentarios"
      one: "1 comentario"
      other: "%{count} comentarios"
```

```ruby
# Usage
I18n.t('posts.comments', count: 0)   # "No comments"
I18n.t('posts.comments', count: 1)   # "1 comment"
I18n.t('posts.comments', count: 5)   # "5 comments"
```

### Interpolation and Context
```yaml
# config/locales/en.yml
en:
  greetings:
    welcome_user: "Welcome, %{name}!"
    goodbye_user: "Goodbye, %{name}. See you soon!"
    
  emails:
    subject:
      welcome: "Welcome to %{app_name}, %{name}!"
      password_reset: "Reset your password for %{app_name}"
      
  notifications:
    user_mentioned: "%{mentioner} mentioned you in a post"
    post_liked: "%{liker} liked your post \"%{post_title}\""
```

```ruby
# Usage
I18n.t('greetings.welcome_user', name: current_user.name)
I18n.t('emails.subject.welcome', app_name: 'MyApp', name: user.name)
I18n.t('notifications.post_liked', liker: liker.name, post_title: post.title)
```

### Scoped Translations
```ruby
# In controllers/views, you can scope translations
class PostsController < ApplicationController
  def show
    # Scoped lookup: posts.show.title
    @page_title = t('.title')
    
    # Equivalent to: t('posts.show.title')
    @description = t('.description', post_title: @post.title)
  end
end
```

```erb
<!-- In views -->
<h1><%= t('.title') %></h1>
<p><%= t('.description') %></p>

<!-- Lazy lookup in partials -->
<!-- _post.html.erb -->
<div class="post">
  <h3><%= t('.title') %></h3>  <!-- posts.post.title -->
  <p><%= t('.excerpt') %></p>   <!-- posts.post.excerpt -->
</div>
```

### Date and Time Localization
```yaml
# config/locales/en.yml
en:
  date:
    formats:
      default: "%Y-%m-%d"
      short: "%b %d"
      long: "%B %d, %Y"
    month_names: [~, January, February, March, April, May, June, July, August, September, October, November, December]
    abbr_month_names: [~, Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]
    day_names: [Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday]
    abbr_day_names: [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
    
  time:
    formats:
      default: "%a, %d %b %Y %H:%M:%S %z"
      short: "%d %b %H:%M"
      long: "%B %d, %Y %H:%M"
    am: "am"
    pm: "pm"

# config/locales/es.yml
es:
  date:
    formats:
      default: "%d/%m/%Y"
      short: "%d de %b"
      long: "%d de %B de %Y"
    month_names: [~, enero, febrero, marzo, abril, mayo, junio, julio, agosto, septiembre, octubre, noviembre, diciembre]
    abbr_month_names: [~, ene, feb, mar, abr, may, jun, jul, ago, sep, oct, nov, dic]
    day_names: [domingo, lunes, martes, miércoles, jueves, viernes, sábado]
    abbr_day_names: [dom, lun, mar, mié, jue, vie, sáb]
```

```ruby
# Usage
I18n.l(Date.current)                    # Localized date
I18n.l(Time.current, format: :short)    # Localized time with format
l(user.created_at, format: :long)       # Helper method in views
```

### Number and Currency Localization
```yaml
# config/locales/en.yml
en:
  number:
    format:
      separator: "."
      delimiter: ","
      precision: 3
    currency:
      format:
        unit: "$"
        precision: 2
        separator: "."
        delimiter: ","
        format: "%u%n"
    percentage:
      format:
        delimiter: ","
    human:
      format:
        delimiter: ","
        precision: 3

# config/locales/es.yml
es:
  number:
    format:
      separator: ","
      delimiter: "."
      precision: 3
    currency:
      format:
        unit: "€"
        precision: 2
        separator: ","
        delimiter: "."
        format: "%n %u"
```

```ruby
# Usage
number_to_currency(1234.56)           # "$1,234.56" (en) / "1.234,56 €" (es)
number_to_percentage(85.5)            # "85.5%" 
number_with_delimiter(1234567)        # "1,234,567" (en) / "1.234.567" (es)
number_to_human_size(1234567890)      # "1.15 GB"
```

## Locale Management

### URL-based Locale Switching
```ruby
# config/routes.rb
Rails.application.routes.draw do
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    root 'home#index'
    resources :posts
    resources :users
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_locale
  
  private
  
  def set_locale
    I18n.locale = params[:locale] if params[:locale].present?
  end
  
  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end

# Helper for generating localized URLs
module ApplicationHelper
  def link_to_locale(locale_name, locale_code)
    link_to locale_name, url_for(locale: locale_code), 
            class: ('active' if I18n.locale.to_s == locale_code.to_s)
  end
end
```

### User Locale Preferences
```ruby
# Migration
class AddLocaleToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :locale, :string, default: 'en'
    add_index :users, :locale
  end
end

# app/models/user.rb
class User < ApplicationRecord
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  
  after_initialize :set_default_locale
  
  private
  
  def set_default_locale
    self.locale ||= I18n.default_locale.to_s
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_locale
  
  private
  
  def set_locale
    I18n.locale = current_user_locale || extract_locale_from_params || I18n.default_locale
  end
  
  def current_user_locale
    current_user&.locale&.to_sym if current_user&.locale.present?
  end
end
```

### Session-based Locale
```ruby
# app/controllers/locales_controller.rb
class LocalesController < ApplicationController
  def update
    if params[:locale].present? && I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
      
      # Update user preference if logged in
      current_user.update(locale: params[:locale]) if current_user
      
      redirect_back(fallback_location: root_path)
    else
      redirect_to root_path, alert: t('errors.invalid_locale')
    end
  end
end

# config/routes.rb
Rails.application.routes.draw do
  patch '/locale', to: 'locales#update', as: :set_locale
end

# Language switcher partial
<!-- app/views/shared/_language_switcher.html.erb -->
<div class="language-switcher">
  <%= form_with url: set_locale_path, method: :patch, local: true do |form| %>
    <%= form.select :locale, 
                    options_for_select(
                      I18n.available_locales.map { |locale| 
                        [t("languages.#{locale}", default: locale.to_s.upcase), locale] 
                      }, 
                      I18n.locale
                    ),
                    {}, 
                    { 
                      onchange: 'this.form.submit();',
                      class: 'form-select'
                    } %>
  <% end %>
</div>
```

## Performance Optimization

### Translation Caching
```ruby
# config/environments/production.rb
Rails.application.configure do
  # Cache translations
  config.i18n.cache_translations = true
end

# Custom translation caching
class CachedTranslations
  def self.translate(key, options = {})
    cache_key = "translation:#{I18n.locale}:#{key}:#{options.hash}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      I18n.translate(key, **options)
    end
  end
end
```

### Lazy Loading
```ruby
# config/initializers/i18n.rb
# Only load translations for current locale
I18n.backend = I18n::Backend::LazyLoadable.new

# Preload frequently used translations
Rails.application.config.after_initialize do
  I18n.backend.load_translations
end
```

## Testing

### Translation Tests
```ruby
# test/models/user_test.rb
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "validates presence with localized message" do
    user = User.new
    user.valid?
    
    expected_message = I18n.t('activerecord.errors.models.user.attributes.name.blank')
    assert_includes user.errors[:name], expected_message
  end
  
  test "displays localized status" do
    user = users(:active_user)
    
    I18n.with_locale(:en) do
      assert_equal "Active", user.status_text
    end
    
    I18n.with_locale(:es) do
      assert_equal "Activo", user.status_text
    end
  end
end

# test/integration/locale_switching_test.rb
class LocaleSwitchingTest < ActionDispatch::IntegrationTest
  test "switches locale via parameter" do
    get root_path(locale: :es)
    assert_response :success
    assert_equal :es, I18n.locale
  end
  
  test "displays content in selected locale" do
    get posts_path(locale: :es)
    assert_select 'h1', 'Publicaciones'  # Spanish translation
  end
  
  test "falls back to default locale for invalid locale" do
    get root_path(locale: :invalid)
    assert_equal :en, I18n.locale
  end
end
```

### Translation Coverage
```ruby
# lib/tasks/i18n.rake
namespace :i18n do
  desc "Check for missing translations"
  task :check_missing => :environment do
    require 'i18n-tasks'
    
    i18n = I18n::Tasks::BaseTask.new
    missing = i18n.missing_keys
    
    if missing.present?
      puts "Missing translations:"
      missing.each do |key|
        puts "  #{key}"
      end
      exit 1
    else
      puts "All translations present!"
    end
  end
  
  desc "Remove unused translations"
  task :remove_unused => :environment do
    require 'i18n-tasks'
    
    i18n = I18n::Tasks::BaseTask.new
    unused = i18n.unused_keys
    
    unused.each do |key|
      puts "Removing unused key: #{key}"
      i18n.data.write_tree(i18n.data.tree - unused)
    end
  end
end
```

## Tools and Gems

### Translation Management
```ruby
# Gemfile
gem 'i18n-tasks'           # Translation management
gem 'rails-i18n'          # Rails translations
gem 'devise-i18n'         # Devise translations
gem 'kaminari-i18n'       # Kaminari pagination translations

# Translation extraction
gem 'gettext_i18n_rails'  # Extract translatable strings
gem 'ruby_parser'         # Required for gettext extraction
```

### Translation Workflow
```bash
# Install i18n-tasks
bundle exec i18n-tasks --help

# Check for missing translations
bundle exec i18n-tasks missing

# Check for unused translations
bundle exec i18n-tasks unused

# Normalize translation files
bundle exec i18n-tasks normalize

# Add missing translations
bundle exec i18n-tasks add-missing

# Interactive translation management
bundle exec i18n-tasks health
```

## References

- [Rails Internationalization Guide](https://guides.rubyonrails.org/i18n.html)
- [I18n API Documentation](https://ruby-i18n.github.io/i18n/)
- [I18n Tasks Gem](https://github.com/glebm/i18n-tasks)
- [Rails I18n Gem](https://github.com/svenfuchs/rails-i18n)