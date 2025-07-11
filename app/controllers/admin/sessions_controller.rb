# RAILS 8 TUTORIAL BLOG - ADMIN SESSIONS CONTROLLER
#
# PURPOSE: Handles admin user authentication (login/logout) with secure session management
#
# RAILS CONCEPT: This controller manages the authentication workflow using Rails' built-in
# session management. Sessions store user ID in encrypted cookies to maintain login state.
#
# NAMESPACING: Located in Admin:: namespace to separate admin functionality from public
# interface. This follows Rails convention for organizing related controllers.
#
# SECURITY: Uses Rails' session management with secure cookies and CSRF protection.
# Never stores passwords - only encrypted user ID for session identification.

class Admin::SessionsController < ApplicationController
  # LAYOUT: Use application layout for consistent styling with site navigation
  # FUTURE ENHANCEMENT: Could use dedicated admin layout if admin interface expands
  
  # LOGIN FORM DISPLAY
  # GET /admin/login - Shows the login form
  def new
    # RAILS MAGIC: Automatically renders app/views/admin/sessions/new.html.erb
    # No instance variables needed since this is just displaying a form
    
    # REDIRECT LOGIC: If user is already logged in, redirect to avoid confusion
    user = User.find_by(id: session[:user_id]) if session[:user_id]
    if user&.admin?
      # FLASH MESSAGE: Inform user they're already authenticated
      redirect_to admin_dashboard_path, notice: 'You are already logged in'
      return
    end
    
    # BEGINNER TIP: Rails will automatically render the 'new' view template
    # unless we explicitly redirect or render something else
  end
  
  # LOGIN PROCESSING
  # POST /admin/login - Processes login form submission
  def create
    # PARAMETER EXTRACTION: Get email and password from form submission
    # SECURITY: Only extract needed parameters to prevent mass assignment attacks
    email = params[:email]
    password = params[:password]
    
    # INPUT VALIDATION: Check that required fields are present
    if email.blank? || password.blank?
      # FLASH ERROR: Inform user about missing fields
      flash.now[:alert] = 'Email and password are required'
      # RENDER: Show form again with error message
      # 'now' means flash message only shows on current request, not next
      render :new, status: :unprocessable_entity
      return
    end
    
    # USER LOOKUP: Find user by email (case insensitive search)
    # SECURITY: Use find_by instead of find to avoid exceptions with invalid emails
    user = User.find_by(email: email.downcase.strip)
    
    # AUTHENTICATION CHECK: Verify password and admin status
    # RAILS MAGIC: authenticate method provided by has_secure_password
    # SECURITY: authenticate automatically handles password hashing comparison
    if user&.authenticate(password) && user.admin?
      # SUCCESS PATH: Valid admin user found and authenticated
      
      # SESSION CREATION: Store user ID in Rails session
      # SECURITY: Session data is encrypted and signed by Rails
      session[:user_id] = user.id
      
      # FLASH SUCCESS: Provide positive feedback
      flash[:notice] = "Welcome back, #{user.email}!"
      
      # REDIRECT: Send to admin dashboard
      # SECURITY: admin_dashboard_path will be protected by authorization
      redirect_to admin_dashboard_path
    else
      # FAILURE PATH: Invalid credentials or non-admin user
      
      # SECURITY: Generic error message to prevent user enumeration attacks
      # Don't reveal whether email exists or password was wrong
      flash.now[:alert] = 'Invalid email or password'
      
      # RENDER: Show login form again with error
      # STATUS: 401 Unauthorized for proper HTTP semantics
      render :new, status: :unauthorized
    end
  end
  
  # LOGOUT PROCESSING  
  # DELETE /admin/logout - Logs out the current user
  def destroy
    # SESSION CLEANUP: Remove user ID from session
    # SECURITY: This effectively logs out the user
    session[:user_id] = nil
    
    # ALTERNATIVE: session.delete(:user_id) also works
    # RAILS FEATURE: reset_session clears entire session if needed for security
    
    # FLASH MESSAGE: Confirm logout action
    flash[:notice] = 'You have been logged out successfully'
    
    # REDIRECT: Return to public home page
    redirect_to root_path
  end
  
  private
  
  # HELPER METHOD: Get currently logged in user
  # MEMOIZATION: Use ||= to cache database query result
  # SECURITY: Only queries database once per request
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  # RAILS HELPER: Make current_user available in views
  # This allows views to check if user is logged in
  helper_method :current_user
end

# WHAT THIS CONTROLLER ACCOMPLISHES:
#
# 1. LOGIN FORM: Displays secure login form for admin users
# 2. AUTHENTICATION: Verifies admin credentials using Rails' built-in methods
# 3. SESSION MANAGEMENT: Creates and destroys user sessions securely
# 4. ERROR HANDLING: Provides user-friendly feedback for all scenarios
# 5. SECURITY: Follows Rails security best practices throughout
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - Controller actions for authentication workflow
# - Rails session management with secure cookies
# - Flash messages for user feedback
# - Parameter handling and validation
# - Redirection and rendering patterns
# - Helper methods for sharing code with views
#
# SECURITY FEATURES:
#
# - Password verification without storing passwords
# - Generic error messages to prevent user enumeration
# - Session-based authentication (not cookies with passwords)
# - CSRF protection (inherited from ApplicationController)
# - Admin role verification for access control
#
# BEGINNER LEARNING POINTS:
#
# - Sessions persist user login state across requests
# - has_secure_password provides authenticate method
# - Flash messages communicate with users between requests
# - Controller actions coordinate the authentication workflow
# - Namespaced controllers organize related functionality