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
  get '/blog/:slug', to: 'blog#show', as: 'blog_post'
  
  # ROUTE HELPER EXAMPLES: These routes create these helpers:
  # - blog_path → "/blog" (for linking to blog index)
  # - blog_post_path("my-post-slug") → "/blog/my-post-slug" (for linking to specific post)
  # - blog_url → "http://domain.com/blog" (full URL version)
  # 
  # SLUG ROUTING: Updated to use slug parameter instead of numeric ID
  # SEO BENEFIT: URLs like /blog/my-awesome-post instead of /blog/123
  # PARAMETER: :slug captures the post's slug for lookup
  #
  
  # ADMIN NAMESPACE: All admin functionality grouped under /admin path
  #
  # NAMESPACE BENEFITS:
  # - Clean URL structure (/admin/login, /admin/posts, etc.)
  # - Separate admin controllers from public controllers
  # - Admin-specific layout and authentication can be applied consistently
  # - Clear separation of concerns between public and admin interfaces
  namespace :admin do
    # AUTHENTICATION ROUTES: Login and logout functionality
    get 'login', to: 'sessions#new'      # Display login form
    post 'login', to: 'sessions#create'  # Process login submission
    delete 'logout', to: 'sessions#destroy'  # Process logout
    
    # POSTS RESOURCE: RESTful routes for blog post management
    #
    # RAILS RESOURCE MAGIC: `resources :posts` automatically creates:
    # GET    /admin/posts           → posts#index   (list all posts)
    # GET    /admin/posts/new       → posts#new     (show form for new post)
    # POST   /admin/posts           → posts#create  (process new post form)
    # GET    /admin/posts/:id       → posts#show    (display specific post)
    # GET    /admin/posts/:id/edit  → posts#edit    (show form for editing)
    # PATCH  /admin/posts/:id       → posts#update  (process edit form)
    # DELETE /admin/posts/:id       → posts#destroy (delete post)
    #
    # MEMBER ROUTES: Custom actions that operate on individual posts
    # - member: adds routes that include the post ID
    # - patch: HTTP verb for modifying existing resources
    resources :posts do
      member do
        patch :publish    # PATCH /admin/posts/:id/publish
        patch :unpublish  # PATCH /admin/posts/:id/unpublish
      end
    end
    
    # ADMIN ROOT: Dashboard as the admin home page
    # When admin visits /admin, they see the dashboard
    root 'dashboard#index'
  end
  
  # WHY CUSTOM ROUTES HERE: 
  # - Clear, readable URLs that match user expectations
  # - Separation between public blog reading and admin management
  # - Security through clear admin namespace
  # - Foundation for Phase 4 admin functionality expansion
end
