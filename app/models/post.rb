# POST MODEL - Represents blog posts in the application
#
# RAILS CONCEPT: Models are Ruby classes that represent data and business logic.
# They inherit from ApplicationRecord, which provides database functionality.
#
# MODEL RESPONSIBILITIES:
# - Define relationships with other models (associations)
# - Validate data before saving to database
# - Provide query methods (scopes) for common data access patterns
# - Contain business logic specific to blog posts
#
# WHY SEPARATE MODEL from DATABASE: Models add Ruby behavior to database records

class Post < ApplicationRecord
  # ASSOCIATION: Each post belongs to one user (the author)
  #
  # RAILS ASSOCIATION MAGIC:
  # - belongs_to creates a user method on post instances
  # - Expects user_id foreign key in posts table (created in migration)
  # - Enables: post.user to get the author
  # - Rails automatically handles the database join
  #
  # RELATIONSHIP EXPLANATION for beginners:
  # - A blog post has exactly one author (user)
  # - The database stores user_id to link post to its author
  # - Rails makes this relationship feel like objects in Ruby
  belongs_to :user
  
  # VALIDATIONS: Ensure data quality before saving to database
  #
  # VALIDATION PHILOSOPHY:
  # - Database constraints (in migration) prevent invalid data storage
  # - Model validations provide user-friendly error messages
  # - Both work together for comprehensive data integrity
  
  # TITLE VALIDATION: Ensure every post has a meaningful title
  #
  # VALIDATION RULES:
  # - presence: true: Title cannot be blank or nil
  # - length: { maximum: 200 }: Prevent extremely long titles (SEO + UI)
  #
  # WHY 200 CHARACTERS: Good balance for SEO, database efficiency, UI display
  # WHY PRESENCE: Title is essential for post identification and navigation
  validates :title, presence: true, length: { maximum: 200 }
  
  # CONTENT VALIDATION: Ensure every post has actual content
  #
  # VALIDATION RULES:
  # - presence: true: Content cannot be blank or nil
  # - No length limit: Blog posts can be any length
  #
  # WHY PRESENCE: Content is the core value of a blog post
  # WHY NO MAX LENGTH: Blog posts should not be artificially limited
  validates :content, presence: true
  
  # SLUG VALIDATION: User-defined URL identifier with strict requirements
  #
  # VALIDATION RULES:
  # - presence: true: Every post must have a slug for URL generation
  # - uniqueness: true: Prevents URL conflicts between posts
  # - format: Only URL-safe characters (letters, numbers, hyphens)
  #
  # SLUG REQUIREMENTS for SEO and usability:
  # - Lowercase letters and numbers only
  # - Hyphens for word separation (not underscores)
  # - No special characters that break URLs
  # - No spaces (replaced with hyphens)
  validates :slug, presence: true, 
                   uniqueness: true,
                   format: { with: /\A[a-z0-9-]+\z/, 
                            message: "must contain only lowercase letters, numbers, and hyphens" }
  
  # EXCERPT VALIDATION: Optional but with reasonable limits
  #
  # VALIDATION RULES:
  # - length: { maximum: 500 }: Excerpts should be brief summaries
  # - No presence validation: Excerpts are optional
  #
  # WHY 500 CHARACTERS: Long enough for good summary, short enough for previews
  # WHY OPTIONAL: Authors might not always provide custom excerpts
  validates :excerpt, length: { maximum: 500 }, allow_blank: true
  
  # IMAGES FIELD: JSON array of image objects with metadata
  #
  # CUSTOM SERIALIZATION: Manual JSON handling for Rails 8 compatibility
  # STRUCTURE: Array of hashes with src, alt, caption, position keys
  #
  # EXAMPLE USAGE:
  # post.images = [{ src: "data:image/png;base64,...", alt: "Screenshot", caption: "My image" }]
  # post.images.each { |img| puts img['alt'] }
  
  # Custom getter for images field
  def images
    return [] if read_attribute(:images).blank?
    JSON.parse(read_attribute(:images))
  rescue JSON::ParserError
    []
  end
  
  # Custom setter for images field
  def images=(value)
    case value
    when String
      # Handle JSON string from form submission
      begin
        parsed_value = JSON.parse(value)
        write_attribute(:images, parsed_value.to_json)
      rescue JSON::ParserError
        write_attribute(:images, [].to_json)
      end
    when Array
      # Handle array assignment
      write_attribute(:images, value.to_json)
    else
      # Handle nil or other values
      write_attribute(:images, [].to_json)
    end
  end
  
  # SCOPES: Reusable query methods for common data access patterns
  #
  # SCOPE PHILOSOPHY:
  # - Encapsulate common queries in the model
  # - Make controller code more readable
  # - Provide chainable, composable query building
  # - Keep SQL knowledge in the model layer
  
  # PUBLISHED SCOPE: Find only published posts
  #
  # USAGE: Post.published returns all published posts
  # QUERY: WHERE published = true
  #
  # WHY USEFUL: Public blog should only show published posts
  # HOW IT WORKS: Lambda syntax creates reusable query method
  scope :published, -> { where(published: true) }
  
  # RECENT SCOPE: Order posts by newest first
  #
  # USAGE: Post.recent returns posts ordered by creation date
  # QUERY: ORDER BY created_at DESC
  #
  # WHY USEFUL: Blog typically shows newest posts first
  # CHAINABLE: Can combine with other scopes like Post.published.recent
  scope :recent, -> { order(created_at: :desc) }
  
  # PUBLISHED_RECENT SCOPE: Combine published and recent for public blog
  #
  # USAGE: Post.published_recent returns published posts, newest first
  # QUERY: WHERE published = true ORDER BY created_at DESC
  #
  # WHY USEFUL: Most common query for public blog display
  # COMPOSITION: Shows how scopes can build on each other
  scope :published_recent, -> { published.recent }
  
  # INSTANCE METHODS: Behavior specific to individual post objects
  
  # PUBLISHED? METHOD: Check if a post is published
  #
  # USAGE: post.published? returns true/false
  # RAILS MAGIC: Boolean fields automatically get ? methods
  #
  # WHY USEFUL: More readable than checking post.published == true
  # ALREADY EXISTS: Rails creates this automatically for boolean fields
  # (This comment documents the automatic method for educational purposes)
  
  # EXCERPT_OR_CONTENT METHOD: Get excerpt if available, otherwise truncated content
  #
  # BUSINESS LOGIC: Provide fallback for displaying post previews
  # USAGE: post.excerpt_or_content(limit: 150)
  #
  # WHY NEEDED: Some posts have custom excerpts, others need auto-generated ones
  # FLEXIBILITY: Allows customization of truncation length
  def excerpt_or_content(limit: 150)
    # If excerpt exists and is not blank, use it
    if excerpt.present?
      excerpt
    else
      # Otherwise, create excerpt from content with specified limit
      # truncate() is a Rails helper that safely cuts text and adds "..."
      content.truncate(limit)
    end
  end
  
  # AUTHOR_NAME METHOD: Get the author's name for display
  #
  # ASSOCIATION HELPER: Simplify view code for showing author
  # USAGE: post.author_name instead of post.user.email
  #
  # WHY USEFUL: Cleaner view code, handles missing user gracefully
  # DEFENSIVE CODING: Uses safe navigation (&.) to prevent errors
  def author_name
    # Safe navigation operator (&.) prevents errors if user is nil
    # For now, uses email since we don't have separate name fields
    user&.email || "Unknown Author"
  end
  
  # PUBLICATION METHODS: Handle publishing workflow
  
  # PUBLISH! METHOD: Mark post as published with timestamp
  #
  # WORKFLOW METHOD: Handles the publishing action
  # USAGE: post.publish! sets published and published_at
  #
  # WHY SEPARATE METHOD: Ensures published_at is set correctly
  # EXCLAMATION MARK: Indicates method modifies the object and saves it
  def publish!
    update!(published: true, published_at: Time.current)
  end
  
  # UNPUBLISH! METHOD: Mark post as unpublished
  #
  # WORKFLOW METHOD: Handles the unpublishing action
  # USAGE: post.unpublish! sets published to false
  #
  # WHY KEEP published_at: Preserves publication history
  # BUSINESS LOGIC: Allows re-publishing without losing original timestamp
  def unpublish!
    update!(published: false)
  end
  
  # CLASS METHODS: Behavior for the Post class as a whole
  
  # FIND_BY_SLUG METHOD: Find post using slug instead of ID
  #
  # SLUG LOOKUP: Enables friendly URLs like /blog/my-post-title
  # USAGE: Post.find_by_slug("my-post-title")
  #
  # WHY SEPARATE METHOD: Makes intent clear and consistent across app
  # RAILS MAGIC: find_by_slug could use Rails' dynamic finder, but explicit is clearer
  def self.find_by_slug(slug)
    find_by(slug: slug)
  end
  
  # FIND_BY_SLUG! METHOD: Find post by slug or raise error
  #
  # ERROR HANDLING: Raises ActiveRecord::RecordNotFound if slug doesn't exist
  # USAGE: Post.find_by_slug!("my-post-title")
  #
  # WHY EXCLAMATION: Convention for methods that raise errors on failure
  # CONTROLLER USE: Perfect for controller actions that need 404 errors
  def self.find_by_slug!(slug)
    find_by!(slug: slug)
  end
  
  # SEARCH METHOD: Find posts matching a search term
  #
  # SEARCH FUNCTIONALITY: Basic text search across title and content
  # USAGE: Post.search("rails") finds posts containing "rails"
  #
  # WHY ILIKE: Case-insensitive search that works across databases
  # FUTURE ENHANCEMENT: Could be replaced with full-text search
  def self.search(term)
    return none if term.blank?
    
    where("title ILIKE ? OR content ILIKE ?", "%#{term}%", "%#{term}%")
  end
  
  # SLUG HELPER METHODS: Utilities for working with slugs
  
  # GENERATE_SLUG_FROM_TITLE: Create URL-safe slug from post title
  #
  # SLUG GENERATION: Converts title to URL-friendly format
  # USAGE: post.generate_slug_from_title
  #
  # TRANSFORMATION STEPS:
  # 1. Convert to lowercase
  # 2. Replace spaces and special chars with hyphens
  # 3. Remove multiple consecutive hyphens
  # 4. Remove leading/trailing hyphens
  #
  # EXAMPLES:
  # "My First Blog Post!" → "my-first-blog-post"
  # "Rails 8: New Features" → "rails-8-new-features"
  def generate_slug_from_title
    return "" if title.blank?
    
    title.downcase
         .gsub(/[^a-z0-9\s-]/, '') # Remove special characters except spaces and hyphens
         .gsub(/\s+/, '-')         # Replace spaces with hyphens
         .gsub(/-+/, '-')          # Replace multiple hyphens with single hyphen
         .strip                    # Remove leading/trailing whitespace
         .gsub(/^-+|-+$/, '')      # Remove leading/trailing hyphens
  end
  
  # ENSURE_UNIQUE_SLUG: Make slug unique if it already exists
  #
  # COLLISION HANDLING: Appends number to slug if duplicate exists
  # USAGE: post.ensure_unique_slug("my-post") → "my-post-2"
  #
  # UNIQUENESS STRATEGY: Increment number until unique slug found
  # WHY NEEDED: Multiple posts might have similar titles
  def ensure_unique_slug(base_slug)
    slug = base_slug
    counter = 1
    
    # Keep checking if slug exists and incrementing counter
    # Exclude current record from uniqueness check (for updates)
    while self.class.where(slug: slug).where.not(id: self.id).exists?
      counter += 1
      slug = "#{base_slug}-#{counter}"
    end
    
    slug
  end
  
  # TO_PARAM: Rails method for URL generation
  #
  # RAILS CONVENTION: to_param determines what appears in URLs
  # DEFAULT: Rails uses ID, we override to use slug
  # USAGE: Automatic when using link helpers like post_path(@post)
  #
  # URL GENERATION: post_path(@post) → "/blog/my-post-slug"
  # WHY OVERRIDE: Makes URLs use slug instead of ID automatically
  def to_param
    slug.presence || id.to_s
  end
  
  # IMAGE HELPER METHODS: Utilities for working with post images
  
  # HAS_IMAGES? METHOD: Check if post contains any images
  #
  # CONVENIENCE METHOD: Quick check for template logic
  # USAGE: post.has_images? → true/false
  #
  # WHY NEEDED: Templates need to know whether to show image sections
  def has_images?
    images.present? && images.any?
  end
  
  # IMAGE_COUNT METHOD: Get total number of images in post
  #
  # UTILITY METHOD: Count images for display or validation
  # USAGE: post.image_count → integer
  def image_count
    images&.length || 0
  end
  
  # ADD_IMAGE METHOD: Add new image to post
  #
  # CONVENIENCE METHOD: Simplifies adding images programmatically
  # USAGE: post.add_image(src: "data:...", alt: "Description", caption: "Caption")
  def add_image(image_data)
    self.images ||= []
    self.images << image_data.stringify_keys
  end
  
  # REMOVE_IMAGE METHOD: Remove image by index
  #
  # MANAGEMENT METHOD: Remove specific image from post
  # USAGE: post.remove_image(0) removes first image
  def remove_image(index)
    return unless images.present? && index >= 0 && index < images.length
    images.delete_at(index)
  end
  
  # CLEAR_IMAGES METHOD: Remove all images from post
  #
  # UTILITY METHOD: Clear all images at once
  # USAGE: post.clear_images
  def clear_images
    self.images = []
  end
  
  # POSITION-SPECIFIC IMAGE METHODS: Get images by their position
  
  # HERO_IMAGE METHOD: Get the hero image for the post
  #
  # HERO DISPLAY: Main image shown at top of blog post
  # USAGE: post.hero_image → hash or nil
  def hero_image
    images.find { |img| img['position'] == 'hero' }
  end
  
  # HAS_HERO_IMAGE? METHOD: Check if post has a hero image
  #
  # CONVENIENCE METHOD: Quick check for template logic
  # USAGE: post.has_hero_image? → true/false
  def has_hero_image?
    hero_image.present?
  end
  
  # GET_IMAGE_BY_INDEX METHOD: Get image by index position
  #
  # INDEX DISPLAY: Get image for specific placement in content
  # USAGE: post.get_image_by_index(1) → hash or nil
  def get_image_by_index(index)
    images.find { |img| img['position'] == "index-#{index}" }
  end
  
  # INDEXED_IMAGES METHOD: Get all indexed images sorted by index
  #
  # CONTENT DISPLAY: Get all images meant for content placement
  # USAGE: post.indexed_images → array of hashes
  def indexed_images
    images.select { |img| img['position']&.start_with?('index-') }
          .sort_by { |img| img['position'].split('-').last.to_i }
  end
end

# WHAT THIS MODEL ACCOMPLISHES:
#
# 1. DATA RELATIONSHIPS: Connects posts to their authors via belongs_to
# 2. DATA VALIDATION: Ensures all posts have required fields with quality constraints
# 3. QUERY INTERFACE: Provides scopes for common data access patterns
# 4. BUSINESS LOGIC: Contains post-specific behavior like publishing workflow
# 5. HELPER METHODS: Simplifies view code with convenient display methods
# 6. SEARCH CAPABILITY: Enables basic content search functionality
#
# WHY THIS DESIGN:
#
# - SINGLE RESPONSIBILITY: Model handles data and business logic, not presentation
# - RAILS CONVENTIONS: Uses standard Rails patterns (scopes, validations, associations)
# - EXTENSIBILITY: Structure supports future enhancements (comments, tags, etc.)
# - READABILITY: Clear method names and logical organization
# - DEFENSIVE CODING: Handles edge cases gracefully
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - Model associations (belongs_to) with foreign keys
# - Data validation with presence, length, and custom rules
# - Scopes for reusable query methods
# - Instance methods for object-specific behavior
# - Class methods for collection-level functionality
# - Rails time handling with Time.current
# - Safe navigation operator (&.) for nil handling
#
# BEGINNER LEARNING POINTS:
#
# - Models represent business entities and contain their logic
# - Associations make object relationships feel natural in Ruby
# - Validations provide user-friendly error handling
# - Scopes keep common queries organized and reusable
# - Instance methods add behavior to individual records
# - Defensive coding prevents errors in edge cases
# - Rails provides many helpful methods for common tasks