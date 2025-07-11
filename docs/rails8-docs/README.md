# Rails 8 Documentation Suite

Welcome to your local Rails 8 documentation reference. This comprehensive guide covers all core Rails features and Rails 8-specific enhancements, designed to serve as an offline reference for developers and AI agents.

## Rails Philosophy

Rails follows the principle of "build features first, then style." The framework emphasizes:
- Convention over Configuration
- Don't Repeat Yourself (DRY)
- Optimizing for programmer happiness
- Full-stack development with sensible defaults

## How to Use These Docs

Each feature is documented in its own markdown file with:
- Clear overviews and use cases
- Generic examples with placeholders (`ModelName`, `Resource`)
- Scaffolding commands and generators
- Configuration tips and production deployment guidance
- Links to official Rails Guides for deeper exploration

Browse the files directly or use your editor's search functionality to find specific topics.

## Core Rails Features

### Foundation & Setup
- [Project Setup & Initial Scaffolding](./project-setup.md)
- [MVC Architecture](./mvc-architecture.md)
- [Routing & ActionController](./routing-action-controller.md)

### Data Layer
- [ActiveRecord: Models, Validations, Associations](./active-record.md)
- [Migrations & Schema Management](./migrations-schema.md)

### View Layer
- [Views, Layouts & Partials](./views-layouts-partials.md)
- [Asset Pipeline & JavaScript Bundling](./asset-pipeline-javascript.md)

### Background Processing & Communication
- [ActiveJob & Background Processing](./active-job.md)
- [ActionMailer & Email Delivery](./action-mailer.md)
- [ActionCable (WebSockets)](./action-cable.md)

### File Handling & APIs
- [ActiveStorage & File Uploads](./active-storage.md)
- [API Mode & JSON Serialization](./api-mode-json.md)

### Security & Configuration
- [Security (CSRF, CORS, Encryption)](./security.md)
- [Credentials & Encrypted Secrets](./credentials-secrets.md)

### Testing & Quality
- [Testing (Minitest & RSpec)](./testing.md)
- [Error Handling & Custom Exceptions](./error-handling.md)

### Performance & Production
- [Caching & Performance Tuning](./caching-performance.md)
- [Logging & Monitoring](./logging-monitoring.md)
- [Deployment Strategies (Kamal, Capistrano)](./deployment-strategies.md)

### Internationalization & Maintenance
- [Internationalization (I18n)](./internationalization.md)
- [Upgrading Rails Versions](./upgrading-rails.md)
- [Plugins & Engines](./plugins-engines.md)

### Rails 8 Specific
- [New Rails 8 Features](./rails8-new-features.md)

## Quick Reference

### Common Commands
```bash
# New Rails 8 app
rails new MyApp --skip-git

# Generate scaffold
rails generate scaffold Resource name:string description:text

# Run migrations
rails db:migrate

# Start server
rails server

# Run tests
rails test

# Deploy with Kamal
kamal setup
kamal deploy
```

### Official Documentation
For the most up-to-date information, refer to the [Official Rails Guides](https://guides.rubyonrails.org).

## Contributing

These docs are meant to be living documentation. Update them as Rails evolves and as your understanding deepens.