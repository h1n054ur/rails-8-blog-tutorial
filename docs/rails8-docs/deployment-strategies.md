# Deployment Strategies (Kamal, Capistrano)

## Overview

Rails applications can be deployed using various strategies. Rails 8 introduces Kamal as the default deployment tool, while Capistrano remains a popular choice for more complex deployments. This guide covers both approaches along with other deployment options.

## Kamal Deployment (Rails 8 Default)

### Kamal Overview
Kamal is a simple deployment tool that uses Docker containers and SSH to deploy Rails applications without requiring complex orchestration platforms.

### Initial Setup
```bash
# Kamal is included by default in Rails 8
# For existing apps, add to Gemfile:
gem 'kamal', require: false

# Initialize Kamal
kamal init

# This creates:
# - config/deploy.yml
# - .kamal/secrets (gitignored)
```

### Basic Configuration
```yaml
# config/deploy.yml
service: myapp
image: myapp

servers:
  web:
    - 192.168.1.100
    - 192.168.1.101
  job:
    - 192.168.1.102

registry:
  username: myuser
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_LOG_LEVEL: info
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - REDIS_URL

accessories:
  db:
    image: postgres:15
    host: 192.168.1.103
    env:
      clear:
        POSTGRES_DB: myapp_production
      secret:
        - POSTGRES_PASSWORD
    files:
      - config/init.sql:/docker-entrypoint-initdb.d/setup.sql
    directories:
      - data:/var/lib/postgresql/data

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt/acme.json:/letsencrypt/acme.json"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: "admin@example.com"
```

### Environment-Specific Configuration
```yaml
# config/deploy.production.yml
service: myapp-production
image: myapp-production

servers:
  web:
    - production-1.example.com
    - production-2.example.com
  job:
    - worker-1.example.com

env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_LEVEL: warn
    WEB_CONCURRENCY: 3
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - REDIS_URL
    - SECRET_KEY_BASE

# config/deploy.staging.yml
service: myapp-staging
image: myapp-staging

servers:
  web:
    - staging.example.com

env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_LEVEL: debug
```

### Docker Configuration
```dockerfile
# Dockerfile
FROM ruby:3.2

WORKDIR /rails

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y nodejs npm yarn postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Expose port
EXPOSE 3000

# Start the server
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
```

### Kamal Commands
```bash
# Initial setup on servers
kamal setup

# Deploy application
kamal deploy

# Deploy to specific environment
kamal deploy -d production
kamal deploy -d staging

# Deploy specific roles
kamal deploy --roles=web
kamal deploy --roles=job

# Execute commands
kamal app exec "bin/rails console"
kamal app exec --interactive "bin/rails console"
kamal app exec "bin/rails db:migrate"

# View logs
kamal app logs
kamal app logs --follow
kamal app logs --since 1h

# Scale services
kamal scale web=5
kamal scale job=2

# Restart services
kamal app restart
kamal app restart --roles=web

# Stop and remove
kamal app stop
kamal remove
```

### Advanced Kamal Features
```yaml
# config/deploy.yml
service: myapp

# Health checks
healthcheck:
  path: /health
  port: 3000
  interval: 30s
  timeout: 10s
  retries: 3

# Zero-downtime deployment
rolling_deploy: true

# Custom commands
commands:
  pre-deploy:
    - docker system prune -f
  post-deploy:
    - kamal app exec "bin/rails db:migrate"
    - kamal app exec "bin/rails db:seed"

# Asset volume mounting
volumes:
  - "/host/assets:/rails/public/assets"

# Custom labels for containers
labels:
  traefik.http.routers.myapp.rule: "Host(`myapp.com`)"
  traefik.http.routers.myapp.tls.certresolver: "letsencrypt"

# SSH configuration
ssh:
  user: deploy
  port: 22
  proxy: bastion.example.com
  log_level: debug
```

### Background Jobs with Kamal
```yaml
# config/deploy.yml
accessories:
  redis:
    image: redis:7
    host: 192.168.1.104
    directories:
      - data:/data

servers:
  job:
    hosts:
      - worker-1.example.com
      - worker-2.example.com
    cmd: bundle exec sidekiq
    env:
      clear:
        RAILS_ENV: production
        WORKER_PROCESSES: 5
```

## Capistrano Deployment

### Capistrano Setup
```ruby
# Gemfile
group :development do
  gem 'capistrano', '~> 3.17'
  gem 'capistrano-rails', '~> 1.6'
  gem 'capistrano-passenger', '~> 0.2'
  gem 'capistrano-rbenv', '~> 2.2'
  gem 'capistrano-bundler', '~> 2.0'
end
```

```bash
# Initialize Capistrano
bundle exec cap install
```

### Capistrano Configuration
```ruby
# config/deploy.rb
lock "~> 3.17.0"

set :application, "myapp"
set :repo_url, "git@github.com:username/myapp.git"

set :deploy_to, "/var/www/myapp"
set :scm, :git

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

set :linked_files, %w{config/database.yml config/master.key}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads}

set :keep_releases, 5

# Passenger restart
set :passenger_restart_with_touch, true

# Asset compilation
set :assets_roles, [:app]

namespace :deploy do
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        execute :rake, 'cache:clear'
      end
    end
  end
  
  before :starting, :check_revision do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{fetch(:branch)}`
      puts "WARNING: HEAD is not the same as origin/#{fetch(:branch)}"
      puts "Run `git push` to sync changes."
      exit
    end
  end
end
```

### Environment-Specific Configuration
```ruby
# config/deploy/production.rb
server "production-1.example.com", 
       user: "deploy", 
       roles: %w{app db web}

server "production-2.example.com",
       user: "deploy",
       roles: %w{app web}

set :rails_env, "production"
set :branch, "main"

# SSH options
set :ssh_options, {
  keys: %w(/home/deploy/.ssh/id_rsa),
  forward_agent: false,
  auth_methods: %w(publickey password)
}

# config/deploy/staging.rb
server "staging.example.com",
       user: "deploy",
       roles: %w{app db web}

set :rails_env, "production"
set :branch, "develop"
```

### Custom Capistrano Tasks
```ruby
# lib/capistrano/tasks/custom.rake
namespace :deploy do
  desc "Seed the database"
  task :seed do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:seed'
        end
      end
    end
  end
  
  desc "Restart background jobs"
  task :restart_workers do
    on roles(:job) do
      execute :sudo, 'systemctl restart sidekiq'
    end
  end
  
  desc "Upload configuration files"
  task :upload_configs do
    on roles(:app) do
      upload! "config/database.yml.production", "#{shared_path}/config/database.yml"
      upload! "config/master.key", "#{shared_path}/config/master.key"
    end
  end
  
  before :starting, :upload_configs
  after :publishing, :seed
  after :finished, :restart_workers
end

# Backup task
namespace :backup do
  desc "Backup database"
  task :db do
    on roles(:db) do
      execute :pg_dump, 
              "-h localhost",
              "-U #{fetch(:db_user)}",
              "-d #{fetch(:db_name)}",
              "> #{shared_path}/backups/db_#{Time.now.strftime('%Y%m%d_%H%M%S')}.sql"
    end
  end
end
```

### Capistrano Commands
```bash
# Deploy to production
cap production deploy

# Deploy to staging
cap staging deploy

# Check deployment status
cap production deploy:check

# Rollback to previous release
cap production deploy:rollback

# Run custom tasks
cap production deploy:seed
cap production backup:db

# Upload files
cap production deploy:upload_configs

# Start/stop services
cap production deploy:start
cap production deploy:stop
cap production deploy:restart
```

## Platform-as-a-Service (PaaS) Deployment

### Heroku Deployment
```bash
# Install Heroku CLI
# Create Heroku app
heroku create myapp-production

# Add buildpacks
heroku buildpacks:add heroku/ruby

# Set environment variables
heroku config:set RAILS_MASTER_KEY=your_master_key
heroku config:set RAILS_ENV=production

# Add database
heroku addons:create heroku-postgresql:mini

# Deploy
git push heroku main

# Run migrations
heroku run rails db:migrate

# Scale dynos
heroku ps:scale web=2 worker=1
```

```ruby
# Procfile
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq
release: bundle exec rails db:migrate
```

### Railway Deployment
```yaml
# railway.yml
build:
  command: bundle install && rails assets:precompile
start:
  command: bundle exec rails server -b 0.0.0.0 -p $PORT

environments:
  production:
    variables:
      RAILS_ENV: production
      NODE_ENV: production
```

### Render Deployment
```yaml
# render.yaml
services:
  - type: web
    name: myapp
    env: ruby
    buildCommand: "./bin/render-build.sh"
    startCommand: "bundle exec puma -C config/puma.rb"
    envVars:
      - key: RAILS_MASTER_KEY
        sync: false
      - key: DATABASE_URL
        fromDatabase:
          name: myapp-db
          property: connectionString

databases:
  - name: myapp-db
    databaseName: myapp_production
    user: myapp
```

```bash
#!/usr/bin/env bash
# bin/render-build.sh
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
```

## Docker-Based Deployment

### Docker Compose for Production
```yaml
# docker-compose.production.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp_production
      - REDIS_URL=redis://redis:6379/0
    volumes:
      - ./storage:/rails/storage
    depends_on:
      - db
      - redis
    restart: unless-stopped

  worker:
    build: .
    command: bundle exec sidekiq
    environment:
      - RAILS_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp_production
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=myapp_production
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7
    volumes:
      - redis_data:/data
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes Deployment
```yaml
# k8s/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 3000
        env:
        - name: RAILS_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-url
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"

---
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
```

## Deployment Best Practices

### Environment Variables
```bash
# .env.production (not committed)
RAILS_MASTER_KEY=your_master_key
DATABASE_URL=postgresql://user:pass@host:5432/dbname
REDIS_URL=redis://host:6379/0
SECRET_KEY_BASE=your_secret_key
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### Database Migrations
```ruby
# Migration strategy for zero-downtime deployments
class SafeAddColumnMigration < ActiveRecord::Migration[7.0]
  def up
    # Step 1: Add column as nullable
    add_column :users, :new_field, :string
    
    # Step 2: Backfill data (in separate deployment)
    # User.in_batches.update_all(new_field: 'default_value')
    
    # Step 3: Add constraint (in separate deployment)
    # change_column_null :users, :new_field, false
  end
  
  def down
    remove_column :users, :new_field
  end
end
```

### Asset Compilation
```ruby
# config/environments/production.rb
Rails.application.configure do
  # Compile assets during build, not at runtime
  config.assets.compile = false
  
  # Use a CDN for assets
  config.asset_host = 'https://cdn.example.com'
  
  # Enable gzip compression
  config.middleware.use Rack::Deflater
end
```

### Health Checks
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def show
    checks = {
      database: database_check,
      redis: redis_check,
      storage: storage_check
    }
    
    if checks.values.all?
      render json: { status: 'ok', checks: checks }
    else
      render json: { status: 'error', checks: checks }, status: 503
    end
  end
  
  private
  
  def database_check
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue
    false
  end
  
  def redis_check
    Redis.current.ping == 'PONG'
  rescue
    false
  end
  
  def storage_check
    ActiveStorage::Blob.service.exist?('health_check')
  rescue
    false
  end
end
```

### Monitoring and Logging
```ruby
# config/environments/production.rb
Rails.application.configure do
  # Use structured logging
  config.log_formatter = Logger::Formatter.new
  config.logger = ActiveSupport::Logger.new(STDOUT)
  
  # Enable performance monitoring
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path =~ /health/ } } }
end
```

## Deployment Checklist

### Pre-Deployment
- [ ] Run tests locally
- [ ] Check environment variables
- [ ] Review database migrations
- [ ] Verify asset compilation
- [ ] Check dependencies and versions
- [ ] Backup production database

### Deployment Process
- [ ] Deploy to staging first
- [ ] Run smoke tests on staging
- [ ] Deploy to production
- [ ] Monitor application logs
- [ ] Check application health endpoints
- [ ] Verify core functionality

### Post-Deployment
- [ ] Monitor error rates
- [ ] Check performance metrics
- [ ] Verify background jobs
- [ ] Test critical user flows
- [ ] Document any issues

## References

- [Kamal Documentation](https://kamal-deploy.org/)
- [Capistrano Documentation](https://capistranorb.com/)
- [Deploying Rails](https://guides.rubyonrails.org/deployment.html)
- [Docker for Rails](https://docs.docker.com/samples/rails/)
- [Kubernetes Rails Guide](https://kubernetes.io/docs/tutorials/stateful-application/)