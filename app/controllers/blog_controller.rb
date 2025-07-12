# Blog Controller - Handles public blog post display functionality
#
# RAILS CONCEPT: This controller manages the public-facing blog section where
# visitors can view published blog posts. It's separate from admin functionality
# to maintain clean separation of concerns.
#
# NAMING CONVENTION: 'BlogController' manages blog-related pages. We chose 'blog'
# instead of 'posts' to clearly indicate this is the public interface, while 
# admin functionality will use 'PostsController' later.
#
# PHASE 2 SCOPE: For now, this controller provides structure and placeholder
# functionality. In Phase 3, we'll connect it to the Post model and database.

class BlogController < ApplicationController
  # The 'index' action displays a list of blog posts (or will, in Phase 3)
  #
  # RAILS CONVENTION: 'index' is the standard action for displaying a collection
  # of resources. This will become the main blog listing page.
  #
  # CURRENT STATE: Placeholder implementation for Phase 2 structure
  # FUTURE ENHANCEMENT: Will query published blog posts from database
  def index
    # PHASE 4 IMPLEMENTATION: Query published blog posts from database
    # Using published scope to only show public posts, not drafts
    @posts = Post.published.recent.includes(:user)
    
    # Set up SEO-friendly page metadata for better user experience
    @page_title = "Blog Posts"
    @page_description = "Explore our Rails 8 tutorial blog posts covering modern web development topics."
    
    # BEGINNER NOTE: Instance variables (starting with @) are automatically
    # available in the view template. Local variables would not be accessible.
    #
    # QUERY OPTIMIZATION: 
    # - .published scope filters to only published posts
    # - .recent scope orders by newest first for better UX
    # - .includes(:user) prevents N+1 queries when displaying author names
    
    # RAILS MAGIC: Rails will automatically render app/views/blog/index.html.erb
    # unless we explicitly call render with different options
  end

  # The 'show' action displays a single blog post (will be implemented in Phase 3)
  #
  # RAILS CONVENTION: 'show' is the standard action for displaying a single
  # resource identified by an ID parameter.
  #
  # URL PATTERN: This will handle URLs like /blog/my-awesome-post where my-awesome-post is the slug
  def show
    # SLUG IMPLEMENTATION: Find and display a single published blog post using slug
    @post = Post.published.includes(:user).find_by_slug!(params[:slug])
    
    # Set up SEO-friendly page metadata using post data
    @page_title = @post.title
    @page_description = @post.excerpt_or_content.truncate(160)
    
    # LEARNING POINT: params[:slug] contains the slug from the URL
    # Rails automatically extracts this from routes like /blog/:slug
    #
    # SECURITY NOTE: Using Post.published.find_by_slug! ensures users can only
    # access published posts, not drafts or unpublished content
    #
    # SEO BENEFIT: Slug-based URLs are more descriptive and search-engine friendly
    # Example: /blog/rails-8-tutorial instead of /blog/123
    #
    # QUERY OPTIMIZATION: .includes(:user) prevents N+1 queries when
    # displaying author information
    
  rescue ActiveRecord::RecordNotFound
    # Handle case where post doesn't exist or isn't published
    redirect_to blog_path, alert: 'Blog post not found or no longer available.'
  end

  # PRIVATE METHODS: Helper methods that support the controller actions
  # These methods are not accessible as actions (can't be called via URLs)
  private
  
  # This method will be used in Phase 3 for finding posts securely
  # SECURITY NOTE: Always scope database queries to published posts only
  # in public controllers to prevent unauthorized access to drafts
  def find_published_post
    # FUTURE IMPLEMENTATION: 
    # @post = Post.published.find(params[:id])
    #
    # SECURITY EXPLANATION: Using Post.published.find instead of Post.find
    # ensures users can only access published posts, not drafts or private posts
  end
  
  # This method will handle common blog parameters in Phase 3
  def blog_params
    # FUTURE IMPLEMENTATION:
    # params.permit(:category, :tag, :search, :page)
    #
    # SECURITY NOTE: Always use strong parameters to prevent mass assignment
    # vulnerabilities. Only permit parameters you explicitly want to allow.
  end
end

# WHAT THIS CONTROLLER ACCOMPLISHES:
#
# 1. STRUCTURE: Establishes the foundation for public blog functionality
# 2. CONVENTIONS: Demonstrates Rails RESTful controller patterns
# 3. SEPARATION: Keeps public blog separate from admin functionality
# 4. FUTURE-READY: Prepared for Phase 3 database integration
#
# WHY WE BUILT THIS NOW:
#
# - Completes Phase 2 public interface foundation
# - Provides routes and views for testing navigation
# - Demonstrates Rails controller organization patterns
# - Sets up structure before adding data complexity in Phase 3
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - Controller naming and organization
# - Action naming conventions (index, show)
# - Instance variable usage for view data
# - URL parameter access with params[:id]
# - Private method organization
# - Comments and documentation for learning
#
# BEGINNER LEARNING POINTS:
#
# - Controllers coordinate between routes, models, and views
# - Action names determine which view template gets rendered
# - Instance variables (@variable) pass data from controller to view
# - Private methods organize code but aren't accessible as routes
# - Security considerations start at the controller level