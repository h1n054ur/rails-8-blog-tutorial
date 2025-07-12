# RAILS 8 TUTORIAL BLOG - ADMIN DASHBOARD CONTROLLER
#
# PURPOSE: Main admin interface providing overview of blog management functionality
#
# RAILS CONCEPT: This controller inherits from Admin::BaseController which provides
# authentication, authorization, and shared admin functionality automatically.
#
# INHERITANCE: Gets authentication checking, current_user helper, and admin authorization
# without having to reimplement these features.

class Admin::DashboardController < Admin::BaseController
  # INHERITED BEHAVIOR: 
  # - before_action :require_admin_authentication (from Admin::BaseController)
  # - helper_method :current_user (from Admin::BaseController)
  # - Admin role verification happens automatically
  
  # DASHBOARD INDEX: Main admin overview page
  # GET /admin - The main admin panel interface
  def index
    # INSTANCE VARIABLES: Pass data to the view template
    # These will be available in app/views/admin/dashboard/index.html.erb
    
    # PAGE METADATA: Set custom title for admin dashboard
    @page_title = "Admin Dashboard"
    @page_description = "Manage your Rails 8 Tutorial Blog"
    
    # USER CONTEXT: Current admin user information
    # SECURITY: current_user is guaranteed to be admin due to base controller
    @current_admin = current_user
    
    # STATISTICS: Basic blog statistics for dashboard overview
    # FUTURE ENHANCEMENT: These will become dynamic when we add posts in Phase 4
    @total_users = User.count
    @admin_users = User.admin.count
    
    # PHASE 4 COMPLETION: Real blog post statistics
    # POST STATISTICS: Calculate actual post counts from database
    @total_posts = Post.count  # Total posts in database
    @published_posts = Post.published.count  # Published posts visible to public
    @draft_posts = Post.where(published: false).count  # Draft posts not yet published
    
    # DASHBOARD STATUS: Track tutorial progress
    @tutorial_phase = "Phase 4: Blog Post Management"
    @next_phase = "Phase 5: Tutorial Documentation"
    
    # RAILS CONCEPT: Instance variables set here are automatically available
    # in the view template. Rails "magic" makes @variable available as variable in ERB.
  end
  
  # FUTURE ACTIONS: Phase 4 will add methods like:
  # def posts
  #   @posts = Post.recent.limit(10)
  # end
  #
  # def users  
  #   @users = User.recent.limit(10)
  # end
end

# WHAT THIS CONTROLLER ACCOMPLISHES:
#
# 1. ADMIN DASHBOARD: Central admin interface with overview information
# 2. SECURITY INHERITANCE: Automatic admin authentication via base controller
# 3. DATA PREPARATION: Gathers statistics and information for dashboard display
# 4. PHASE TRACKING: Shows tutorial progress and next steps
# 5. FOUNDATION: Ready for Phase 4 blog post management features
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - Controller inheritance for shared functionality
# - Instance variables for passing data to views
# - Database queries with ActiveRecord (User.count, User.admin)
# - RESTful controller actions (index action for main page)
#
# INHERITANCE BENEFITS:
#
# - Automatic authentication checking (no need to implement)
# - Access to current_user helper method
# - Admin role verification handled automatically
# - Consistent error handling and redirection
# - Shared helper methods available in views
#
# BEGINNER LEARNING POINTS:
#
# - Controllers inherit functionality from parent controllers
# - Instance variables (@variable) pass data from controller to view
# - ActiveRecord provides database query methods (count, admin scope)
# - RESTful actions follow Rails naming conventions
# - Authentication and authorization can be handled in parent controllers