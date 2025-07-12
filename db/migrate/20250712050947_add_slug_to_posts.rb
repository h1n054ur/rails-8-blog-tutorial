# ADD SLUG TO POSTS MIGRATION - Adds user-defined URL slug functionality
#
# RAILS CONCEPT: This migration adds slug field to enable custom URLs for blog posts
# instead of using arbitrary numeric IDs (/blog/my-awesome-post vs /blog/123)
#
# SLUG PURPOSE:
# - SEO-friendly URLs that describe the content
# - User-controlled URL structure for better branding
# - Persistent URLs that don't change if post ID changes
# - More memorable and shareable links

class AddSlugToPosts < ActiveRecord::Migration[8.0]
  def change
    # SLUG FIELD: User-defined URL identifier for blog posts
    #
    # FIELD DESIGN:
    # - string type: Variable length text suitable for URLs
    # - Used in URL paths like /blog/my-first-post
    # - Replaces numeric ID in public-facing URLs
    #
    # WHY STRING: Slugs are typically short URL-safe strings
    # UNIQUENESS: Handled by unique index below for URL uniqueness
    add_column :posts, :slug, :string
    
    # UNIQUE INDEX: Ensures no duplicate slugs exist
    #
    # INDEX PURPOSE:
    # - unique: true: Prevents duplicate slugs across all posts
    # - Performance: Fast lookup when finding posts by slug
    # - Data integrity: Each post must have unique URL
    #
    # WHY UNIQUE: URLs must be unique to avoid routing conflicts
    # WHY INDEX: Common to query "find post by slug" - needs to be fast
    add_index :posts, :slug, unique: true
  end
end

# WHAT THIS MIGRATION ACCOMPLISHES:
#
# 1. CUSTOM URLS: Enables user-defined URLs instead of numeric IDs
# 2. SEO IMPROVEMENT: URLs describe content instead of arbitrary numbers
# 3. URL PERSISTENCE: Post URLs won't change if database IDs change
# 4. PERFORMANCE: Index ensures fast slug-based lookups
# 5. DATA INTEGRITY: Unique constraint prevents URL conflicts
#
# URL TRANSFORMATION EXAMPLES:
# Before: /blog/123 (arbitrary, meaningless)
# After:  /blog/my-first-rails-app (descriptive, SEO-friendly)
#
# RAILS CONCEPTS DEMONSTRATED:
# - Adding columns to existing tables
# - Creating unique indexes for data integrity
# - Performance optimization for common queries
# - Migration comments for educational purposes
