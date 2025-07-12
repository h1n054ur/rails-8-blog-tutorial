# POST TABLE MIGRATION - Creates the posts table for blog functionality
#
# RAILS CONCEPT: This migration creates the core data structure for blog posts,
# demonstrating model associations, database relationships, and content management.
#
# NAMING CONVENTION: 
# - Timestamp prefix (20250711174001) ensures migrations run in correct order
# - CreatePosts describes the migration's purpose clearly
#
# ACTIVERECORD MIGRATION: Inherits from ActiveRecord::Migration[8.0]
# The version number ensures compatibility with Rails 8 migration features

class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    # CREATE_TABLE: Defines the blog posts table structure
    #
    # DESIGN DECISIONS for posts table:
    # - Content-focused fields for blog functionality
    # - User association for authorship tracking
    # - Publishing workflow with status and timestamps
    # - SEO-friendly with title and excerpt separation
    create_table :posts do |t|
      # TITLE FIELD: The blog post headline
      #
      # FIELD DESIGN:
      # - string type: Variable length text (up to 255 characters)
      # - null: false: Every post must have a title
      # - Used for SEO, navigation, and user experience
      #
      # WHY STRING vs TEXT: Titles are typically short, string is more efficient
      # WHY NOT NULL: Title is essential for post identification and display
      t.string :title, null: false
      
      # CONTENT FIELD: The main blog post content
      #
      # FIELD DESIGN:
      # - text type: Unlimited length for full blog post content
      # - null: false: Every post must have content
      # - Stores the complete article/blog post text
      #
      # WHY TEXT: Blog posts can be very long, need unlimited length
      # WHY NOT NULL: Content is the core value of a blog post
      t.text :content, null: false
      
      # EXCERPT FIELD: Brief summary for blog listing pages
      #
      # FIELD DESIGN:
      # - text type: Allows longer excerpts than string would permit
      # - nullable: Excerpt is optional, can be auto-generated from content
      # - Used for blog index pages, SEO meta descriptions, social sharing
      #
      # WHY SEPARATE from CONTENT: Allows manual control over preview text
      # WHY NULLABLE: Authors might not always provide custom excerpts
      t.text :excerpt
      
      # PUBLISHED FIELD: Controls post visibility
      #
      # FIELD DESIGN:
      # - boolean type: Simple true/false for publication status
      # - default: false: New posts start as drafts (safer default)
      # - null: false: Status must always be explicitly set
      #
      # PUBLISHING WORKFLOW: Draft -> Published -> (optional) Unpublished
      # WHY DEFAULT FALSE: Prevents accidental publishing of incomplete posts
      t.boolean :published, default: false, null: false
      
      # PUBLISHED_AT FIELD: Timestamp for publication tracking
      #
      # FIELD DESIGN:
      # - datetime type: Precise timestamp with date and time
      # - nullable: Only set when post is actually published
      # - Used for sorting published posts chronologically
      #
      # WHY SEPARATE from PUBLISHED: Allows scheduling, publication history
      # WHY NULLABLE: Unpublished posts don't have publication timestamp
      t.datetime :published_at
      
      # USER ASSOCIATION: Links each post to its author
      #
      # RAILS ASSOCIATION MAGIC:
      # - references: Creates user_id foreign key column
      # - null: false: Every post must have an author
      # - foreign_key: true: Database constraint ensures user exists
      # - index: true: Automatically creates index for efficient queries
      #
      # RELATIONSHIP: post belongs_to user, user has_many posts
      # WHY FOREIGN KEY: Maintains referential integrity at database level
      # WHY INDEX: Common to query "all posts by user" - needs to be fast
      t.references :user, null: false, foreign_key: true, index: true
      
      # TIMESTAMPS: Rails convention for tracking record lifecycle
      #
      # AUTOMATIC FIELDS: Rails creates these columns automatically:
      # - created_at: When the post was first saved
      # - updated_at: When the post was last modified
      #
      # CONTENT MANAGEMENT USE CASES:
      # - Track when posts were originally created
      # - Show "last modified" information to readers
      # - Sort posts by creation or modification date
      t.timestamps
    end
    
    # PERFORMANCE OPTIMIZATION: Additional indexes for common queries
    #
    # PUBLISHED POSTS INDEX: Optimizes public blog queries
    # Most common query: "Show all published posts, newest first"
    # Compound index on [published, published_at] handles this efficiently
    add_index :posts, [:published, :published_at], name: 'index_posts_on_published_and_published_at'
    
    # USER POSTS INDEX: Already created by references above
    # This optimizes: "Show all posts by specific user"
    # The foreign key reference automatically creates: add_index :posts, :user_id
    
    # TITLE INDEX: For search functionality (future enhancement)
    # If we implement post search, this would speed up title searches
    # add_index :posts, :title  # Uncomment if implementing search
  end
  
  # MIGRATION REVERSIBILITY:
  #
  # Rails automatically handles reversibility because:
  # - create_table can be reversed with drop_table
  # - add_index can be reversed with remove_index
  # - All constraints and references are automatically reversible
  #
  # The foreign key constraint will be properly cleaned up on rollback
end

# WHAT THIS MIGRATION ACCOMPLISHES:
#
# 1. BLOG POST STORAGE: Complete structure for blog content
# 2. CONTENT MANAGEMENT: Draft/published workflow support
# 3. USER RELATIONSHIPS: Proper author tracking via foreign key
# 4. PERFORMANCE: Indexes for common query patterns
# 5. DATA INTEGRITY: Constraints ensure required fields exist
# 6. SEO FOUNDATION: Separate title/excerpt for search optimization
#
# WHY THIS DESIGN:
#
# - CONTENT FLEXIBILITY: Supports various blog post lengths and styles
# - PUBLISHING WORKFLOW: Enables draft/published state management
# - RELATIONSHIP CLARITY: Clear author attribution for each post
# - QUERY EFFICIENCY: Indexes support fast public blog display
# - EXTENSIBILITY: Structure supports future enhancements (tags, categories)
#
# RAILS CONCEPTS DEMONSTRATED:
#
# - Foreign key relationships between models
# - Compound database indexes for query optimization
# - Boolean fields with sensible defaults
# - Optional vs required fields (nullable vs not null)
# - String vs text field type selection
# - Migration naming and organization conventions
#
# BEGINNER LEARNING POINTS:
#
# - Model associations start with database foreign keys
# - Performance considerations guide index creation
# - Content management requires workflow state fields
# - Default values provide safer system behavior
# - Database constraints complement model validations
# - Migration design impacts application functionality