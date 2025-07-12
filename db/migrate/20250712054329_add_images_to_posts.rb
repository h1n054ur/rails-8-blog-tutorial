# ADD IMAGES TO POSTS MIGRATION - Adds image management functionality to blog posts
#
# RAILS CONCEPT: This migration adds image storage capability to blog posts,
# enabling rich media content within posts for better user experience
#
# IMAGE STORAGE APPROACH:
# - Stores image data as JSON array in text field
# - Each image has: filename, alt_text, position, caption
# - Allows multiple images per post with fine-tuned placement
# - Future enhancement: Could move to separate images table for scalability

class AddImagesToPosts < ActiveRecord::Migration[8.0]
  def change
    # IMAGES FIELD: JSON array storing image metadata and content
    #
    # FIELD DESIGN:
    # - text type: Allows large JSON data for multiple images
    # - Stores array of image objects with metadata
    # - Each image object contains: src, alt, caption, position
    #
    # WHY JSON IN TEXT: Simple implementation for image metadata
    # FUTURE ENHANCEMENT: Separate images table with has_many association
    add_column :posts, :images, :text
  end
end

# WHAT THIS MIGRATION ACCOMPLISHES:
#
# 1. IMAGE SUPPORT: Enables rich media content in blog posts
# 2. MULTIPLE IMAGES: Allows multiple images per post
# 3. METADATA STORAGE: Stores alt text, captions, positioning
# 4. PLACEMENT CONTROL: Admin can fine-tune image placement
# 5. ACCESSIBILITY: Alt text support for screen readers
#
# IMAGE DATA STRUCTURE EXAMPLE:
# [
#   {
#     "src": "data:image/jpeg;base64,/9j/4AAQ...",
#     "alt": "Screenshot of Rails application",
#     "caption": "The admin dashboard showing post management",
#     "position": "center"
#   }
# ]
#
# RAILS CONCEPTS DEMONSTRATED:
# - JSON data storage in text fields
# - Rich media content management
# - Accessibility considerations (alt text)
# - Image metadata organization
