# Asset Pipeline & JavaScript Bundling

## Overview

Rails 8 introduces Propshaft as the default asset pipeline, replacing Sprockets for improved performance and simplicity. The asset pipeline manages static assets like CSS, JavaScript, and images, while modern JavaScript bundling is handled by esbuild, webpack, or other bundlers.

## Propshaft Asset Pipeline (Rails 8)

### Propshaft Overview
Propshaft is Rails 8's new asset pipeline that focuses on simplicity and performance over the complexity of Sprockets.

### Basic Configuration
```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Propshaft is enabled by default in Rails 8
    config.assets.pipeline = :propshaft
    
    # Asset configuration
    config.assets.paths = [
      Rails.root.join('app/assets/stylesheets'),
      Rails.root.join('app/assets/javascript'),
      Rails.root.join('app/assets/images'),
      Rails.root.join('vendor/assets')
    ]
    
    # Precompiled assets
    config.assets.precompile += %w[
      admin.css
      admin.js
      print.css
    ]
  end
end
```

### Asset Organization
```
app/assets/
├── stylesheets/
│   ├── application.css
│   ├── components/
│   │   ├── buttons.css
│   │   ├── forms.css
│   │   └── navigation.css
│   └── pages/
│       ├── home.css
│       └── posts.css
├── javascript/
│   ├── application.js
│   ├── controllers/
│   │   ├── hello_controller.js
│   │   └── toggle_controller.js
│   └── lib/
│       ├── utils.js
│       └── api.js
└── images/
    ├── logo.png
    ├── icons/
    └── backgrounds/
```

### Asset Compilation
```bash
# Precompile assets for production
rails assets:precompile

# Clean compiled assets
rails assets:clean

# Remove all compiled assets
rails assets:clobber

# Environment-specific compilation
RAILS_ENV=production rails assets:precompile
```

### Asset Helpers in Views
```erb
<!-- Stylesheets -->
<%= stylesheet_link_tag "application" %>
<%= stylesheet_link_tag "admin", media: "screen" %>
<%= stylesheet_link_tag "print", media: "print" %>

<!-- JavaScript -->
<%= javascript_include_tag "application", defer: true %>
<%= javascript_include_tag "admin", type: "module" %>

<!-- Images -->
<%= image_tag "logo.png", alt: "Company Logo", class: "logo" %>
<%= image_tag "icons/user.svg", alt: "User Icon", class: "icon" %>

<!-- Asset paths -->
<%= asset_path "logo.png" %>
<%= asset_url "logo.png" %>

<!-- Preloading assets -->
<%= preload_link_tag asset_path("hero-image.jpg"), as: :image %>
<%= preload_link_tag asset_path("fonts/custom.woff2"), as: :font, crossorigin: true %>
```

## JavaScript Bundling

### esbuild (Default in Rails 8)
```bash
# Install esbuild
./bin/bundle add jsbundling-rails
./bin/rails javascript:install:esbuild

# Build JavaScript
yarn build

# Build and watch for changes
yarn build --watch
```

```json
// package.json
{
  "scripts": {
    "build": "esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds --public-path=/assets",
    "build:watch": "yarn build --watch"
  },
  "devDependencies": {
    "esbuild": "^0.19.0"
  }
}
```

### JavaScript Structure
```javascript
// app/javascript/application.js
import "./controllers"
import "bootstrap"

// Import custom modules
import { initializeApp } from "./lib/app"
import { setupEventListeners } from "./lib/events"

document.addEventListener("DOMContentLoaded", () => {
  initializeApp()
  setupEventListeners()
})

// Global error handling
window.addEventListener("error", (event) => {
  console.error("JavaScript error:", event.error)
  // Send to error tracking service
})
```

```javascript
// app/javascript/lib/app.js
export function initializeApp() {
  console.log("Application initialized")
  
  // Initialize third-party libraries
  initializeTooltips()
  initializeModals()
  setupAjaxDefaults()
}

function initializeTooltips() {
  // Bootstrap tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
}

function setupAjaxDefaults() {
  // Set CSRF token for AJAX requests
  const token = document.querySelector("meta[name='csrf-token']").getAttribute("content")
  
  // Fetch defaults
  const originalFetch = window.fetch
  window.fetch = function(url, options = {}) {
    options.headers = {
      'X-CSRF-Token': token,
      'Content-Type': 'application/json',
      ...options.headers
    }
    return originalFetch(url, options)
  }
}
```

### Stimulus Integration
```javascript
// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

window.Stimulus = Application.start()
const context = require.context("./", true, /\.js$/)
Stimulus.load(definitionsFromContext(context))

// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button"]
  static classes = ["hidden"]
  static values = { expanded: Boolean }
  
  connect() {
    this.update()
  }
  
  toggle() {
    this.expandedValue = !this.expandedValue
  }
  
  expandedValueChanged() {
    this.update()
  }
  
  update() {
    if (this.expandedValue) {
      this.contentTarget.classList.remove(this.hiddenClass)
      this.buttonTarget.textContent = "Hide"
    } else {
      this.contentTarget.classList.add(this.hiddenClass)
      this.buttonTarget.textContent = "Show"
    }
  }
}
```

### Turbo Integration
```javascript
// app/javascript/turbo.js
import { Turbo } from "@hotwired/turbo-rails"

// Configure Turbo
Turbo.session.drive = true

// Turbo event listeners
document.addEventListener("turbo:load", () => {
  console.log("Page loaded via Turbo")
  initializePageSpecificCode()
})

document.addEventListener("turbo:before-cache", () => {
  // Clean up before page is cached
  clearTimers()
  removeEventListeners()
})

document.addEventListener("turbo:submit-start", (event) => {
  const form = event.target
  const submitButton = form.querySelector('[type="submit"]')
  
  // Disable submit button
  if (submitButton) {
    submitButton.disabled = true
    submitButton.textContent = "Processing..."
  }
})

document.addEventListener("turbo:submit-end", (event) => {
  const form = event.target
  const submitButton = form.querySelector('[type="submit"]')
  
  // Re-enable submit button
  if (submitButton) {
    submitButton.disabled = false
    submitButton.textContent = submitButton.dataset.originalText || "Submit"
  }
})
```

## CSS and Styling

### CSS Organization
```css
/* app/assets/stylesheets/application.css */

/*
 *= require_tree ./components
 *= require_tree ./pages
 *= require_self
 */

:root {
  --primary-color: #3b82f6;
  --secondary-color: #64748b;
  --success-color: #10b981;
  --danger-color: #ef4444;
  --warning-color: #f59e0b;
  
  --font-family-sans: system-ui, -apple-system, sans-serif;
  --font-family-mono: 'SF Mono', Monaco, monospace;
  
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
}

/* Base styles */
* {
  box-sizing: border-box;
}

body {
  font-family: var(--font-family-sans);
  line-height: 1.6;
  color: #374151;
  margin: 0;
  padding: 0;
}

/* Utility classes */
.hidden { display: none !important; }
.sr-only { 
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.text-center { text-align: center; }
.text-right { text-align: right; }
.text-left { text-align: left; }

.mt-1 { margin-top: var(--spacing-xs); }
.mt-2 { margin-top: var(--spacing-sm); }
.mt-3 { margin-top: var(--spacing-md); }
.mt-4 { margin-top: var(--spacing-lg); }
.mt-5 { margin-top: var(--spacing-xl); }
```

```css
/* app/assets/stylesheets/components/buttons.css */
.btn {
  display: inline-block;
  padding: 0.5rem 1rem;
  font-size: 1rem;
  font-weight: 500;
  text-decoration: none;
  border: 1px solid transparent;
  border-radius: 0.375rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn:hover {
  text-decoration: none;
}

.btn:focus {
  outline: 2px solid transparent;
  outline-offset: 2px;
  box-shadow: 0 0 0 2px var(--primary-color);
}

.btn-primary {
  background-color: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.btn-primary:hover {
  background-color: #2563eb;
  border-color: #2563eb;
}

.btn-secondary {
  background-color: var(--secondary-color);
  color: white;
  border-color: var(--secondary-color);
}

.btn-outline {
  background-color: transparent;
  color: var(--primary-color);
  border-color: var(--primary-color);
}

.btn-outline:hover {
  background-color: var(--primary-color);
  color: white;
}

.btn-sm {
  padding: 0.25rem 0.5rem;
  font-size: 0.875rem;
}

.btn-lg {
  padding: 0.75rem 1.5rem;
  font-size: 1.125rem;
}
```

### Sass/SCSS Support
```bash
# Add Sass support
./bin/bundle add sassc-rails

# Use .scss files
mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss
```

```scss
// app/assets/stylesheets/application.scss
@import "variables";
@import "mixins";
@import "components/**/*";
@import "pages/**/*";

// Variables
$primary-color: #3b82f6;
$secondary-color: #64748b;
$font-stack: system-ui, -apple-system, sans-serif;

// Mixins
@mixin button-style($bg-color, $text-color: white) {
  background-color: $bg-color;
  color: $text-color;
  border: 1px solid $bg-color;
  
  &:hover {
    background-color: darken($bg-color, 10%);
    border-color: darken($bg-color, 10%);
  }
}

// Components
.btn-primary {
  @include button-style($primary-color);
}

.btn-secondary {
  @include button-style($secondary-color);
}
```

### CSS Frameworks Integration

#### Tailwind CSS
```bash
# Install Tailwind CSS
./bin/bundle add tailwindcss-rails
./bin/rails tailwindcss:install
```

```css
/* app/assets/stylesheets/application.tailwind.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .btn {
    @apply inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm;
  }
  
  .btn-primary {
    @apply text-white bg-blue-600 hover:bg-blue-700 focus:ring-2 focus:ring-offset-2 focus:ring-blue-500;
  }
  
  .btn-secondary {
    @apply text-gray-700 bg-white border-gray-300 hover:bg-gray-50 focus:ring-2 focus:ring-offset-2 focus:ring-blue-500;
  }
}
```

#### Bootstrap
```bash
# Install Bootstrap
yarn add bootstrap @popperjs/core
```

```javascript
// app/javascript/application.js
import "bootstrap"

// Import Bootstrap CSS
import "bootstrap/dist/css/bootstrap.min.css"

// Or use Sass
// @import "bootstrap";
```

## Image and Font Management

### Image Optimization
```ruby
# config/environments/production.rb
Rails.application.configure do
  # Enable image optimization
  config.assets.image_optim = {
    pngout: false,
    svgo: false,
    gifsicle: { interlace: false },
    jpegoptim: { strip: :all, max_quality: 80 },
    optipng: { level: 6, interlace: false }
  }
end
```

### Responsive Images
```erb
<!-- Responsive images with srcset -->
<%= image_tag "hero.jpg", 
    srcset: "#{asset_path('hero-small.jpg')} 480w, #{asset_path('hero-medium.jpg')} 768w, #{asset_path('hero-large.jpg')} 1200w",
    sizes: "(max-width: 480px) 480px, (max-width: 768px) 768px, 1200px",
    alt: "Hero image" %>

<!-- Picture element for different formats -->
<picture>
  <source srcset="<%= asset_path('hero.webp') %>" type="image/webp">
  <source srcset="<%= asset_path('hero.jpg') %>" type="image/jpeg">
  <%= image_tag "hero.jpg", alt: "Hero image" %>
</picture>
```

### Web Fonts
```css
/* app/assets/stylesheets/fonts.css */
@font-face {
  font-family: 'Custom Font';
  src: url(font-path('custom-font.woff2')) format('woff2'),
       url(font-path('custom-font.woff')) format('woff');
  font-weight: normal;
  font-style: normal;
  font-display: swap; /* Improves loading performance */
}

body {
  font-family: 'Custom Font', system-ui, -apple-system, sans-serif;
}
```

## Performance Optimization

### Asset Compression
```ruby
# config/environments/production.rb
Rails.application.configure do
  # Compress CSS and JavaScript
  config.assets.css_compressor = :sass
  config.assets.js_compressor = :terser
  
  # Enable gzip compression
  config.middleware.use Rack::Deflater
  
  # Asset fingerprinting
  config.assets.digest = true
  
  # CDN configuration
  config.asset_host = ENV['CDN_HOST']
end
```

### Critical CSS
```erb
<!-- app/views/layouts/application.html.erb -->
<head>
  <!-- Inline critical CSS -->
  <style>
    <%= Rails.application.assets["critical.css"].to_s.html_safe %>
  </style>
  
  <!-- Preload non-critical CSS -->
  <%= preload_link_tag asset_path("application.css"), as: :style, onload: "this.onload=null;this.rel='stylesheet'" %>
  <noscript><%= stylesheet_link_tag "application" %></noscript>
</head>
```

### Lazy Loading
```javascript
// app/javascript/lib/lazy-loading.js
export function initializeLazyLoading() {
  if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const img = entry.target
          img.src = img.dataset.src
          img.classList.remove('lazy')
          imageObserver.unobserve(img)
        }
      })
    })
    
    document.querySelectorAll('img[data-src]').forEach(img => {
      imageObserver.observe(img)
    })
  }
}
```

```erb
<!-- Lazy loaded images -->
<%= image_tag "", 
    data: { src: asset_path("large-image.jpg") },
    class: "lazy",
    alt: "Large image" %>
```

## Development Tools

### Source Maps
```javascript
// esbuild configuration for source maps
// package.json
{
  "scripts": {
    "build": "esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds",
    "build:production": "esbuild app/javascript/*.* --bundle --minify --outdir=app/assets/builds"
  }
}
```

### Live Reload
```ruby
# Gemfile (development group)
gem 'listen'
gem 'web-console'

# config/environments/development.rb
Rails.application.configure do
  # Enable file watching
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  
  # Live reload for assets
  config.assets.live_reload = true
end
```

### Asset Debugging
```ruby
# config/environments/development.rb
Rails.application.configure do
  # Serve individual asset files
  config.assets.debug = true
  
  # Expand asset paths in logs
  config.assets.logger = Logger.new(STDOUT)
end
```

## Testing Assets

### Asset Tests
```ruby
# test/integration/assets_test.rb
require 'test_helper'

class AssetsTest < ActionDispatch::IntegrationTest
  test "application.js is available" do
    get asset_path("application.js")
    assert_response :success
    assert_equal "text/javascript", response.content_type
  end
  
  test "application.css is available" do
    get asset_path("application.css")
    assert_response :success
    assert_equal "text/css", response.content_type
  end
  
  test "images are served correctly" do
    get asset_path("logo.png")
    assert_response :success
    assert_equal "image/png", response.content_type
  end
end
```

### JavaScript Testing
```bash
# Add testing framework
yarn add --dev jest
yarn add --dev @testing-library/dom
```

```javascript
// app/javascript/test/controllers/toggle_controller.test.js
import { Application } from "@hotwired/stimulus"
import ToggleController from "../controllers/toggle_controller"

describe("ToggleController", () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="toggle" data-toggle-expanded-value="false">
        <button data-toggle-target="button" data-action="click->toggle#toggle">Toggle</button>
        <div data-toggle-target="content" class="hidden">Content</div>
      </div>
    `
    
    const application = Application.start()
    application.register("toggle", ToggleController)
  })
  
  test("toggles content visibility", () => {
    const button = document.querySelector("[data-toggle-target='button']")
    const content = document.querySelector("[data-toggle-target='content']")
    
    expect(content.classList.contains("hidden")).toBe(true)
    
    button.click()
    
    expect(content.classList.contains("hidden")).toBe(false)
  })
})
```

## References

- [Asset Pipeline Guide](https://guides.rubyonrails.org/asset_pipeline.html)
- [Propshaft Documentation](https://github.com/rails/propshaft)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Turbo Reference](https://turbo.hotwired.dev/reference/attributes)
- [esbuild Documentation](https://esbuild.github.io/)