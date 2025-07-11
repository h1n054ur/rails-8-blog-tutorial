Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # ROOT ROUTE - Defines what happens when someone visits the main URL of our site
  #
  # WHAT THIS DOES: When someone visits our domain (like tutorialblog.com or localhost:3000),
  # Rails will send the request to the HomeController's index action.
  #
  # SYNTAX EXPLANATION: 
  # - 'root' is a special Rails routing method for the main page
  # - 'home#index' means "HomeController, index action"
  # - Rails automatically finds app/controllers/home_controller.rb
  # - The index action renders app/views/home/index.html.erb
  #
  # WHY WE CHOSE HOME CONTROLLER:
  # - Clear separation of concerns (home page vs blog content)
  # - Follows Rails convention of having dedicated controllers for different purposes
  # - Makes it easy to add home page specific features later
  #
  # BEGINNER TIP: The root route is special - it handles requests to "/" and ""
  # This is different from other routes which need explicit paths like "/about"
  root 'home#index'

  # BLOG ROUTES - Public blog section for viewing published posts
  #
  # WHAT THESE ROUTES DO: Create URLs for the public blog interface
  # - GET /blog → blog#index (list all published posts)
  # - GET /blog/:id → blog#show (display specific post)
  #
  # ROUTING DECISION: We use custom routes instead of 'resources :blog' because:
  # 1. Blog is not a typical RESTful resource (it's a collection interface)
  # 2. We only need read-only public access (index and show)
  # 3. Creates cleaner URLs like /blog instead of /blogs
  # 4. Avoids confusion with admin post management routes
  #
  # RAILS CONVENTION EXPLANATION:
  # - 'blog#index' means "BlogController, index action"
  # - ':id' in the path captures the post ID as params[:id]
  # - 'as:' option creates named route helpers (blog_path, blog_post_path)
  #
  # BEGINNER LEARNING: These routes demonstrate:
  # - Custom route patterns vs. resourceful routes
  # - Parameter capture with :id
  # - Named route helpers for cleaner code
  get '/blog', to: 'blog#index', as: 'blog'
  get '/blog/:id', to: 'blog#show', as: 'blog_post'
  
  # ROUTE HELPER EXAMPLES: These routes create these helpers:
  # - blog_path → "/blog" (for linking to blog index)
  # - blog_post_path(123) → "/blog/123" (for linking to specific post)
  # - blog_url → "http://domain.com/blog" (full URL version)
  #
  # ADMIN AUTHENTICATION ROUTES - Secure admin panel access
  #
  # WHAT THESE ROUTES DO: Handle admin user login/logout workflow
  # - GET /admin/login → admin/sessions#new (display login form)  
  # - POST /admin/login → admin/sessions#create (process login)
  # - DELETE /admin/logout → admin/sessions#destroy (logout user)
  #
  # ROUTING DESIGN DECISIONS:
  # 1. NAMESPACE: All admin routes under /admin/ for clear separation
  # 2. SESSIONS: Login/logout is session management, not user management
  # 3. RESTful PATTERN: new/create/destroy actions follow Rails conventions
  # 4. SECURITY: Admin routes separate from public interface
  #
  # RAILS CONCEPTS DEMONSTRATED:
  # - Custom routes for authentication workflow
  # - Descriptive URL patterns (/admin/login vs /sessions/new)
  # - Named route helpers for clean controllers and views
  # - HTTP method mapping (GET for forms, POST for submission, DELETE for logout)
  #
  # BEGINNER EXPLANATION:
  # - GET requests are for displaying pages (login form)
  # - POST requests are for submitting data (login credentials)
  # - DELETE requests are for removing something (user session)
  # - 'as:' creates helper methods for generating these URLs
  #
  # ROUTE HELPERS CREATED:
  # - admin_login_path → "/admin/login" (GET - show login form)
  # - admin_login_path → "/admin/login" (POST - process login)
  # - admin_logout_path → "/admin/logout" (DELETE - logout user)
  get '/admin/login', to: 'admin/sessions#new', as: 'admin_login'
  post '/admin/login', to: 'admin/sessions#create'
  delete '/admin/logout', to: 'admin/sessions#destroy', as: 'admin_logout'
  
  # ADMIN DASHBOARD ROUTE - Main admin interface
  #
  # WHAT THIS ROUTE DOES: Provides main admin panel interface
  # - GET /admin → admin/dashboard#index (admin overview page)
  #
  # DESIGN DECISION: Simple admin root rather than complex nested routes
  # This creates a clear entry point for admin functionality
  #
  # FUTURE EXPANSION: In Phase 4, we'll add:
  # namespace :admin do
  #   resources :posts  # Full CRUD for blog posts
  #   root 'dashboard#index'  # Could use this syntax instead
  # end
  get '/admin', to: 'admin/dashboard#index', as: 'admin_dashboard'
  
  # WHY CUSTOM ROUTES HERE: 
  # - Clear, readable URLs that match user expectations
  # - Separation between public blog reading and admin management
  # - Security through clear admin namespace
  # - Foundation for Phase 4 admin functionality expansion
end
