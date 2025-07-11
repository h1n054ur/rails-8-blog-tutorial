# RAILS 8 TUTORIAL BLOG - ADMIN BASE CONTROLLER
#
# PURPOSE: Shared functionality for all admin controllers with authorization
#
# RAILS CONCEPT: Base controllers provide common functionality that multiple controllers
# can inherit. This follows DRY principle and ensures consistent behavior.
#
# INHERITANCE PATTERN: Admin controllers inherit from this instead of ApplicationController
# to get admin-specific features like authentication checks.
#
# SECURITY: All admin functionality requires authentication and admin role verification

class Admin::BaseController < ApplicationController
  # BEFORE ACTION: Run authorization check before any admin controller action
  # RAILS CONCEPT: before_action runs specified method before every action
  # SECURITY: This ensures no admin functionality is accessible without proper authentication
  before_action :require_admin_authentication
  
  # HELPER METHODS: Make authentication methods available to views
  # RAILS CONCEPT: helper_method makes controller methods available in templates
  # This allows views to check authentication state and display appropriate content
  helper_method :current_user, :admin_authenticated?
  
  private
  
  # AUTHENTICATION REQUIREMENT: Verify admin access for all admin actions
  # SECURITY: Combines authentication (is user logged in?) and authorization (is user admin?)
  def require_admin_authentication
    # CHECK 1: Is there a current user logged in?
    # CHECK 2: Is the current user an admin?
    # SECURITY: Both conditions must be true for access
    unless current_user&.admin?
      # FLASH MESSAGE: Inform user why access was denied
      # SECURITY: Generic message doesn't reveal admin user existence
      flash[:alert] = 'Access denied. Admin authentication required.'
      
      # REDIRECT: Send to login page for authentication
      # SECURITY: Prevents unauthorized access to admin functionality
      redirect_to admin_login_path
      return
    end
    
    # SUCCESS: User is authenticated admin, allow action to proceed
    # RAILS CONCEPT: If we don't redirect, Rails continues to the requested action
  end
  
  # CURRENT USER HELPER: Get the currently logged in user
  # MEMOIZATION: Use ||= to cache database query result within request
  # PERFORMANCE: Only queries database once per request, even with multiple calls
  def current_user
    # RAILS SESSION: session[:user_id] contains logged in user's ID
    # SECURITY: Session data is encrypted and signed by Rails
    # DATABASE QUERY: Find user by ID, returns nil if session is invalid
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  
  # AUTHENTICATION STATUS: Simple boolean check for admin authentication
  # CONVENIENCE METHOD: Cleaner than calling current_user&.admin? everywhere
  def admin_authenticated?
    # BOOLEAN LOGIC: Returns true only if user exists and is admin
    # SAFE NAVIGATION: &. prevents errors if current_user is nil
    current_user&.admin?
  end
  
  # LOGOUT HELPER: Clear user session (for use in emergency logout scenarios)
  # SECURITY: Provides way to clear session if needed
  def logout_current_user
    # SESSION CLEANUP: Remove user ID from session
    session[:user_id] = nil
    # INSTANCE VARIABLE CLEANUP: Clear cached user
    @current_user = nil
  end
end

# WHAT THIS BASE CONTROLLER ACCOMPLISHES:
#
# 1. AUTHORIZATION ENFORCEMENT: All admin controllers automatically require admin auth
# 2. SHARED HELPERS: Common authentication methods available to all admin controllers  
# 3. SECURITY CENTRALIZATION: Single place to manage admin security requirements
# 4. DRY PRINCIPLE: Avoid repeating authentication code in every admin controller
# 5. CONSISTENT BEHAVIOR: All admin areas behave the same way for authentication
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - Controller inheritance for shared functionality
# - before_action for running code before controller actions
# - helper_method for making controller methods available in views
# - Memoization with ||= for performance optimization
# - Session management for user authentication
# - Safe navigation (&.) for nil-safe method calls
#
# SECURITY FEATURES:
#
# - Authentication verification before any admin action
# - Admin role verification (not just any logged in user)
# - Session-based authentication with Rails security
# - Generic error messages to prevent information disclosure
# - Automatic redirection to login for unauthorized access
#
# INHERITANCE PATTERN:
#
# Admin controllers inherit from this controller like:
# class Admin::DashboardController < Admin::BaseController
#   # Automatically gets authentication, current_user, etc.
# end
#
# BEGINNER LEARNING POINTS:
#
# - Base controllers share functionality across multiple controllers
# - before_action runs before every action in the controller
# - Sessions maintain user state across HTTP requests
# - Authentication (who are you?) vs Authorization (what can you do?)
# - Helper methods make controller functionality available in views