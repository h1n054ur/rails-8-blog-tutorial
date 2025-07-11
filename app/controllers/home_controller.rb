# Home Controller - Handles the main landing page of our tutorial blog
#
# RAILS CONCEPT: Controllers in Rails handle HTTP requests and coordinate between
# models (data) and views (presentation). This controller manages the home page.
#
# NAMING CONVENTION: Rails controllers are named with "Controller" suffix and use
# CamelCase. The file name uses snake_case (home_controller.rb).
#
# INHERITANCE: All controllers inherit from ApplicationController, which provides
# common functionality like authentication, error handling, and security features.

class HomeController < ApplicationController
  # The 'index' action handles GET requests to the root URL (/)
  # 
  # RAILS CONVENTION: 'index' is the standard action name for displaying
  # a list or main page of a resource. Even though we're not listing anything
  # here, 'index' is conventional for the main page of a controller.
  #
  # IMPLICIT RENDERING: Rails automatically renders app/views/home/index.html.erb
  # when this action completes, unless we explicitly render something else.
  def index
    # For now, this action doesn't need to do anything except render the view.
    # Later, we might add data like featured blog posts or recent activity.
    
    # BEGINNER NOTE: Instance variables (starting with @) are automatically
    # available in the view template. We don't have any data to pass yet,
    # but this is where we would set variables like:
    # @featured_posts = Post.featured.limit(3)
  end
end

# WHAT THIS CONTROLLER DOES:
# 1. Responds to requests to the home page
# 2. Renders the welcome message and site navigation
# 3. Provides entry point to the blog application
#
# WHY WE CREATED THIS:
# - Separates home page logic from other controllers (Single Responsibility)
# - Follows Rails RESTful conventions
# - Provides foundation for future home page features
#
# RAILS MAGIC EXPLAINED:
# - Rails automatically maps this controller to routes starting with '/home'
# - The class name determines the route prefix (HomeController → /home)
# - Action names become the final part of the URL (index → /home or /)