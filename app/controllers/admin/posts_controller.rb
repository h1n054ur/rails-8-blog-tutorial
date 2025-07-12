# ADMIN POSTS CONTROLLER - RESTful CRUD operations for blog post management
#
# RAILS CONCEPT: Controllers handle HTTP requests and coordinate between models and views.
# This controller follows RESTful conventions, providing standard CRUD operations.
#
# CONTROLLER INHERITANCE: Inherits from Admin::BaseController for:
# - Automatic admin authentication (before_action :require_admin_login)
# - Admin-specific helper methods (current_user, etc.)
# - Consistent admin interface behavior
#
# RESTFUL DESIGN: Maps HTTP verbs to controller actions following Rails conventions:
# GET /admin/posts           → index  (list all posts)
# GET /admin/posts/new       → new    (show form for new post)
# POST /admin/posts          → create (process new post form)
# GET /admin/posts/:id       → show   (display specific post)
# GET /admin/posts/:id/edit  → edit   (show form for editing post)
# PATCH/PUT /admin/posts/:id → update (process edit form)
# DELETE /admin/posts/:id    → destroy (delete post)

class Admin::PostsController < Admin::BaseController
  # BEFORE ACTIONS: Code that runs before specific controller actions
  #
  # SECURITY & EFFICIENCY: before_action ensures we:
  # 1. Don't repeat code across multiple actions
  # 2. Always find the correct post for actions that need it
  # 3. Scope posts to current admin user (security)
  #
  # ONLY OPTION: Specifies which actions this before_action applies to
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  
  # INDEX ACTION: Display list of all posts for current admin user
  #
  # RESTFUL CONVENTION: GET /admin/posts
  # PURPOSE: Main dashboard for post management
  #
  # QUERY OPTIMIZATION:
  # - current_user.posts: Only shows posts by logged-in admin (security)
  # - .recent: Orders by newest first (user experience)
  # - .includes(:user): Prevents N+1 queries when displaying author info
  #
  # SECURITY NOTE: Users can only see/manage their own posts
  def index
    # Find all posts belonging to the current admin user
    # includes(:user) prevents N+1 queries if we show author info in views
    # recent scope orders by created_at desc (newest first)
    @posts = current_user.posts.recent.includes(:user)
    
    # PAGINATION CONSIDERATION: For production apps with many posts,
    # consider adding pagination here: @posts.page(params[:page])
  end
  
  # SHOW ACTION: Display individual post (preview functionality)
  #
  # RESTFUL CONVENTION: GET /admin/posts/:id
  # PURPOSE: Preview post content before/after publishing
  #
  # POST LOADING: @post set by before_action :set_post
  # SECURITY: set_post ensures user can only view their own posts
  def show
    # @post is already loaded by set_post before_action
    # This action serves as a preview for the admin
    # Shows how the post will appear when published
  end
  
  # NEW ACTION: Show form for creating new post
  #
  # RESTFUL CONVENTION: GET /admin/posts/new
  # PURPOSE: Display empty form for post creation
  #
  # OBJECT BUILDING: current_user.posts.build creates new post associated with admin
  # FORM BENEFIT: The form will have access to @post for field population and errors
  def new
    # Build new post associated with current admin user
    # This ensures the user_id foreign key is set correctly
    # build() creates new object in memory but doesn't save to database
    @post = current_user.posts.build
  end
  
  # CREATE ACTION: Process new post form submission
  #
  # RESTFUL CONVENTION: POST /admin/posts
  # PURPOSE: Save new post to database or redisplay form with errors
  #
  # STRONG PARAMETERS: post_params filters allowed attributes for security
  # REDIRECT vs RENDER: Success redirects, failure re-renders form with errors
  def create
    # Build new post with filtered parameters and current admin as author
    @post = current_user.posts.build(post_params)
    
    # Attempt to save the post to the database
    if @post.save
      # SUCCESS PATH: Post saved successfully
      # redirect_to: Sends HTTP redirect to browser (prevents double-submission)
      # admin_post_path(@post): Generates URL for show action
      # notice: Flash message for user feedback
      redirect_to admin_post_path(@post), notice: 'Post was successfully created.'
    else
      # FAILURE PATH: Validation errors occurred
      # render :new: Redisplays the new form template
      # @post contains validation errors for display
      # NO redirect: Keeps POST data and error messages
      render :new, status: :unprocessable_entity
    end
  end
  
  # EDIT ACTION: Show form for editing existing post
  #
  # RESTFUL CONVENTION: GET /admin/posts/:id/edit
  # PURPOSE: Display form populated with existing post data
  #
  # POST LOADING: @post set by before_action :set_post
  # FORM REUSE: Uses same form partial as new action
  def edit
    # @post is already loaded by set_post before_action
    # The edit form will populate fields with @post's current values
  end
  
  # UPDATE ACTION: Process edit form submission
  #
  # RESTFUL CONVENTION: PATCH/PUT /admin/posts/:id
  # PURPOSE: Update existing post or redisplay form with errors
  #
  # POST LOADING: @post set by before_action :set_post
  # STRONG PARAMETERS: post_params filters allowed attributes
  def update
    # Attempt to update the post with filtered parameters
    if @post.update(post_params)
      # SUCCESS PATH: Post updated successfully
      redirect_to admin_post_path(@post), notice: 'Post was successfully updated.'
    else
      # FAILURE PATH: Validation errors occurred
      # render :edit: Redisplays the edit form with errors
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DESTROY ACTION: Delete post permanently
  #
  # RESTFUL CONVENTION: DELETE /admin/posts/:id
  # PURPOSE: Remove post from database
  #
  # POST LOADING: @post set by before_action :set_post
  # REDIRECT: Always redirects to index after deletion
  def destroy
    # Delete the post from the database
    @post.destroy
    
    # Redirect back to posts index with confirmation message
    redirect_to admin_posts_path, notice: 'Post was successfully deleted.'
  end
  
  # CUSTOM ACTIONS: Additional functionality beyond standard CRUD
  
  # PUBLISH ACTION: Mark post as published
  #
  # CUSTOM ROUTE: PATCH /admin/posts/:id/publish
  # PURPOSE: Publishing workflow - change draft to published
  def publish
    # Find the post by slug (consistent with other admin actions)
    @post = current_user.posts.find_by_slug!(params[:id])
    
    # Use the publish! method from Post model
    if @post.publish!
      redirect_to admin_post_path(@post), notice: 'Post was successfully published.'
    else
      redirect_to admin_post_path(@post), alert: 'Failed to publish post.'
    end
  end
  
  # UNPUBLISH ACTION: Mark post as unpublished
  #
  # CUSTOM ROUTE: PATCH /admin/posts/:id/unpublish
  # PURPOSE: Publishing workflow - change published to draft
  def unpublish
    # Find the post by slug (consistent with other admin actions)
    @post = current_user.posts.find_by_slug!(params[:id])
    
    # Use the unpublish! method from Post model
    if @post.unpublish!
      redirect_to admin_post_path(@post), notice: 'Post was successfully unpublished.'
    else
      redirect_to admin_post_path(@post), alert: 'Failed to unpublish post.'
    end
  end
  
  private
  
  # SET_POST: Find post belonging to current admin
  #
  # BEFORE ACTION METHOD: Runs before show, edit, update, destroy
  # SECURITY: current_user.posts scope ensures user can only access their posts
  # ERROR HANDLING: Raises ActiveRecord::RecordNotFound if post doesn't exist
  # PARAMETER HANDLING: Uses slug for consistent URL structure across admin and public
  def set_post
    # Find post by slug within current admin's posts (security scoping)
    # This prevents users from accessing/modifying other users' posts
    # Rails will raise RecordNotFound if post doesn't exist or belongs to different user
    # CONSISTENCY: Admin and public interfaces both use slugs for clean URLs
    @post = current_user.posts.find_by_slug!(params[:id])
  end
  
  # POST_PARAMS: Strong parameters for security
  #
  # MASS ASSIGNMENT PROTECTION: Only allows specified attributes
  # SECURITY: Prevents malicious users from setting unauthorized fields
  # PERMITTED FIELDS: Only title, content, excerpt, and published are allowed
  #
  # WHY NOT user_id: Set automatically through current_user.posts association
  # WHY NOT id: ID is set by database, shouldn't be modified
  # WHY NOT timestamps: Rails manages these automatically
  # WHY NOT images: Handled separately by handle_images_parameter
  def post_params
    # Require :post key in params (from form submission)
    # Permit only safe attributes that users should be able to modify
    # SLUG ADDITION: Allow admin to set custom URL slug for SEO-friendly URLs
    # IMAGES ADDITION: Allow images parameter as string (will be JSON)
    params.require(:post).permit(:title, :content, :excerpt, :published, :slug, :images)
  end
end

# WHAT THIS CONTROLLER ACCOMPLISHES:
#
# 1. COMPLETE CRUD: All seven RESTful actions for post management
# 2. SECURITY: Users can only manage their own posts
# 3. VALIDATION HANDLING: Proper error display and form re-rendering
# 4. PUBLISHING WORKFLOW: Custom actions for publish/unpublish
# 5. PERFORMANCE: Query optimization with includes and scoping
# 6. USER FEEDBACK: Flash messages for all operations
# 7. RAILS CONVENTIONS: Follows standard RESTful patterns
#
# WHY THIS DESIGN:
#
# - RESTFUL PATTERNS: Predictable URL structure and action names
# - SECURITY FIRST: All operations scoped to current admin user
# - ERROR HANDLING: Graceful handling of validation failures
# - USER EXPERIENCE: Clear feedback for all operations
# - MAINTAINABILITY: Standard Rails patterns easy to understand and extend
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - RESTful controller design with seven standard actions
# - before_action for DRY code and security
# - Strong parameters for mass assignment protection
# - Association scoping for security (current_user.posts)
# - Query optimization with includes
# - Flash messages for user feedback
# - Redirect vs render for different response types
# - Custom actions extending standard CRUD
#
# BEGINNER LEARNING POINTS:
#
# - Controllers coordinate between models and views
# - RESTful design provides predictable patterns
# - Security requires scoping data to current user
# - Strong parameters prevent malicious data submission
# - before_action eliminates code duplication
# - Flash messages provide user feedback
# - HTTP verbs map to specific controller actions
# - Error handling requires different response strategies
#
# PUBLISHING WORKFLOW ENABLED:
#
# - Admin can create posts as drafts (default)
# - Admin can edit drafts before publishing
# - Admin can publish drafts to make them public
# - Admin can unpublish posts to make them private again
# - All posts remain associated with their author
# - Complete audit trail with timestamps