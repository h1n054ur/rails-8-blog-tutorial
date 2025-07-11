# Project Setup & Initial Scaffolding

## Overview

Rails project setup involves creating a new application with sensible defaults, configuring the database, and setting up the basic structure for development and deployment.

## Creating a New Rails 8 Application

### Basic Setup
```bash
# Install Rails 8
gem install rails

# Create new application
rails new MyAppName

# With specific options
rails new MyAppName --database=postgresql --skip-git --css=tailwind

# API-only application
rails new MyApiApp --api
```

### Common Options
- `--database=postgresql|mysql|sqlite3` - Database adapter
- `--skip-git` - Don't initialize git repository
- `--css=bootstrap|bulma|tailwind|sass` - CSS framework
- `--javascript=webpack|esbuild|rollup` - JavaScript bundler
- `--api` - API-only mode
- `--skip-test` - Skip test framework setup

## Initial Configuration

### Database Setup
```bash
# Configure database
rails db:setup

# Or create, migrate, and seed separately
rails db:create
rails db:migrate
rails db:seed
```

### Environment Configuration
```bash
# Generate credentials
rails credentials:edit

# Set up environment files
touch .env.development
touch .env.production
```

## Scaffolding Resources

### Generate Complete Resource
```bash
# Full scaffold with views
rails generate scaffold Post title:string content:text author:string published:boolean

# API scaffold (JSON only)
rails generate scaffold Post title:string content:text --api

# Run migration
rails db:migrate
```

### Individual Generators
```bash
# Model only
rails generate model User name:string email:string

# Controller only
rails generate controller Posts index show new create edit update destroy

# Migration only
rails generate migration AddPublishedToPosts published:boolean
```

## Kamal Integration for Deployment

### Initial Kamal Setup
```bash
# Add to Gemfile
echo 'gem "kamal", require: false' >> Gemfile
bundle install

# Initialize Kamal configuration
kamal init

# Setup servers
kamal setup

# Deploy application
kamal deploy
```

### Kamal Configuration Example
```yaml
# config/deploy.yml
service: myapp
image: myapp
servers:
  - 192.168.1.100

registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
```

### Background Jobs with Kamal
```bash
# Configure job processing
kamal app exec --interactive --reuse "bin/rails console"

# Deploy with job workers
kamal deploy --roles=web,job
```

## Directory Structure

```
MyAppName/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   ├── jobs/
│   ├── mailers/
│   └── assets/
├── config/
│   ├── environments/
│   ├── initializers/
│   └── routes.rb
├── db/
│   ├── migrate/
│   └── seeds.rb
├── test/ (or spec/)
├── Gemfile
└── config.ru
```

## Production Considerations

### Essential Gems for Production
```ruby
# Gemfile
gem 'pg' # PostgreSQL
gem 'redis' # Caching and jobs
gem 'image_processing' # ActiveStorage
gem 'kamal' # Deployment
gem 'bootsnap', require: false # Boot performance
```

### Environment Variables
```bash
# .env.production
DATABASE_URL=postgresql://user:pass@localhost/myapp_production
REDIS_URL=redis://localhost:6379/0
SECRET_KEY_BASE=your_secret_key
```

## Development Workflow

### Daily Commands
```bash
# Start development server
rails server

# Start console
rails console

# Run tests
rails test

# Check routes
rails routes

# Database operations
rails db:rollback
rails db:reset
rails db:seed
```

### Code Generation Workflow
```bash
# 1. Generate resource
rails generate scaffold ModelName field1:type field2:type

# 2. Review and edit migration
# Edit db/migrate/xxx_create_model_names.rb

# 3. Run migration
rails db:migrate

# 4. Customize model, controller, views
# 5. Add routes if needed
# 6. Test functionality
```

## References

- [Getting Started with Rails](https://guides.rubyonrails.org/getting_started.html)
- [Rails Command Line](https://guides.rubyonrails.org/command_line.html)
- [Kamal Documentation](https://kamal-deploy.org/)
- [Rails Application Templates](https://guides.rubyonrails.org/rails_application_templates.html)