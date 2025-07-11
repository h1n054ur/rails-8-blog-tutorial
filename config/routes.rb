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
  # WHY CUSTOM ROUTES HERE: 
  # Later in Phase 4, we'll add resourceful routes for admin:
  # namespace :admin do
  #   resources :posts  # Full CRUD for admin
  # end
  #
  # This separation keeps public and admin interfaces distinct and secure.
end
