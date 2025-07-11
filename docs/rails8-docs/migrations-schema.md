# Migrations & Schema Management

## Overview

Rails migrations provide a version-controlled way to evolve your database schema over time. They allow you to create, modify, and delete database tables and columns using Ruby code that can be executed and reversed.

## Creating Migrations

### Generate Migration Files
```bash
# Create table migration
rails generate migration CreateUsers name:string email:string age:integer

# Add column migration
rails generate migration AddPhoneToUsers phone:string

# Remove column migration
rails generate migration RemoveAgeFromUsers age:integer

# Add index migration
rails generate migration AddIndexToUsersEmail

# Add foreign key migration
rails generate migration AddUserToArticles user:references
```

### Migration File Structure
```ruby
# db/migrate/20231201120000_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.integer :age
      t.boolean :active, default: true
      t.text :bio
      t.decimal :salary, precision: 10, scale: 2
      t.datetime :last_login_at
      
      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, [:name, :age]
  end
end
```

## Migration Methods

### Table Operations
```ruby
class ExampleMigration < ActiveRecord::Migration[7.1]
  def change
    # Create table
    create_table :products do |t|
      t.string :name, null: false, limit: 100
      t.text :description
      t.decimal :price, precision: 8, scale: 2
      t.integer :quantity, default: 0
      t.references :category, foreign_key: true
      t.timestamps
    end
    
    # Drop table
    drop_table :old_products
    
    # Rename table
    rename_table :products, :items
  end
end
```

### Column Operations
```ruby
class ModifyColumns < ActiveRecord::Migration[7.1]
  def change
    # Add columns
    add_column :users, :phone, :string
    add_column :users, :preferences, :json, default: {}
    
    # Remove columns
    remove_column :users, :age, :integer
    
    # Rename columns
    rename_column :users, :bio, :biography
    
    # Change column type
    change_column :users, :phone, :string, limit: 15
    
    # Change column default
    change_column_default :users, :active, from: nil, to: true
    
    # Add/remove null constraint
    change_column_null :users, :email, false
  end
end
```

### Index Operations
```ruby
class ManageIndexes < ActiveRecord::Migration[7.1]
  def change
    # Add indexes
    add_index :users, :email, unique: true
    add_index :users, [:name, :age], name: 'idx_users_name_age'
    add_index :posts, :title, using: 'gin'
    add_index :posts, :created_at, order: { created_at: :desc }
    
    # Remove indexes
    remove_index :users, :phone
    remove_index :users, name: 'idx_users_name_age'
    
    # Check if index exists
    if index_exists?(:users, :email)
      remove_index :users, :email
    end
  end
end
```

### Foreign Key Operations
```ruby
class ManageForeignKeys < ActiveRecord::Migration[7.1]
  def change
    # Add foreign key
    add_foreign_key :posts, :users
    add_foreign_key :posts, :categories, on_delete: :cascade
    add_foreign_key :comments, :posts, column: :article_id
    
    # Remove foreign key
    remove_foreign_key :posts, :users
    remove_foreign_key :comments, column: :article_id
    
    # Check if foreign key exists
    if foreign_key_exists?(:posts, :users)
      remove_foreign_key :posts, :users
    end
  end
end
```

## Column Types and Options

### Available Column Types
```ruby
create_table :examples do |t|
  # String types
  t.string :short_text, limit: 255
  t.text :long_text
  
  # Numeric types
  t.integer :count
  t.bigint :large_number
  t.decimal :price, precision: 10, scale: 2
  t.float :rating
  
  # Boolean
  t.boolean :active, default: false
  
  # Date and time
  t.date :birth_date
  t.time :start_time
  t.datetime :created_at
  t.timestamp :updated_at
  
  # JSON (PostgreSQL)
  t.json :metadata
  t.jsonb :settings
  
  # Binary
  t.binary :file_data
  
  # UUID (PostgreSQL)
  t.uuid :external_id
  
  # References
  t.references :user, null: false, foreign_key: true
  t.belongs_to :category, foreign_key: { on_delete: :cascade }
end
```

### Column Options
```ruby
create_table :users do |t|
  t.string :name, null: false, limit: 100
  t.string :email, null: false, default: '', index: { unique: true }
  t.integer :age, null: true, default: 0
  t.text :bio, comment: 'User biography'
  
  t.timestamps null: false
end
```

## Advanced Migration Techniques

### Reversible Migrations
```ruby
class ComplexMigration < ActiveRecord::Migration[7.1]
  def up
    create_table :new_table do |t|
      t.string :name
      t.timestamps
    end
    
    # Complex data transformation
    execute "INSERT INTO new_table (name) SELECT name FROM old_table"
  end
  
  def down
    drop_table :new_table
  end
end

# Using reversible block
class AnotherMigration < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        # Forward migration code
        execute "UPDATE users SET status = 'active' WHERE status IS NULL"
      end
      
      dir.down do
        # Reverse migration code
        execute "UPDATE users SET status = NULL WHERE status = 'active'"
      end
    end
  end
end
```

### Data Migrations
```ruby
class MigrateUserData < ActiveRecord::Migration[7.1]
  def up
    # Disable model loading to avoid issues
    User.reset_column_information
    
    User.find_each do |user|
      # Transform data
      user.update_column(:full_name, "#{user.first_name} #{user.last_name}")
    end
  end
  
  def down
    User.update_all(full_name: nil)
  end
end
```

### Safe Migrations for Production
```ruby
class SafeMigration < ActiveRecord::Migration[7.1]
  # Prevent migration from running in production
  disable_ddl_transaction!
  
  def change
    # Add column with default (safe)
    add_column :users, :new_field, :string, default: 'default_value'
    
    # Add index concurrently (PostgreSQL)
    add_index :users, :email, algorithm: :concurrently
  end
end
```

## Running Migrations

### Basic Commands
```bash
# Run pending migrations
rails db:migrate

# Migrate to specific version
rails db:migrate VERSION=20231201120000

# Rollback last migration
rails db:rollback

# Rollback multiple migrations
rails db:rollback STEP=3

# Rollback to specific version
rails db:migrate:down VERSION=20231201120000

# Re-run specific migration
rails db:migrate:redo VERSION=20231201120000

# Check migration status
rails db:migrate:status
```

### Environment-Specific Migrations
```bash
# Run migrations in specific environment
rails db:migrate RAILS_ENV=production

# Reset database (development only)
rails db:reset

# Drop, create, migrate, and seed
rails db:setup

# Recreate database from schema
rails db:schema:load
```

## Schema Management

### Schema File
```ruby
# db/schema.rb (auto-generated)
ActiveRecord::Schema[7.1].define(version: 2023_12_01_120000) do
  enable_extension "plpgsql"
  
  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "age"
    t.boolean "active", default: true
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end
  
  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end
  
  add_foreign_key "posts", "users"
end
```

### Structure vs Schema
```bash
# Use SQL structure file instead of schema.rb
# config/application.rb
config.active_record.schema_format = :sql

# This creates db/structure.sql instead of db/schema.rb
rails db:migrate
```

## Database-Specific Features

### PostgreSQL Features
```ruby
class PostgreSQLFeatures < ActiveRecord::Migration[7.1]
  def change
    # Enable extensions
    enable_extension 'uuid-ossp'
    enable_extension 'hstore'
    
    create_table :posts, id: :uuid do |t|
      t.string :title
      t.text :content
      t.hstore :metadata
      t.jsonb :settings
      t.tsvector :search_vector
      t.timestamps
    end
    
    # GIN index for full-text search
    add_index :posts, :search_vector, using: 'gin'
    
    # Partial index
    add_index :posts, :title, where: "published = true"
    
    # Expression index
    add_index :posts, "lower(title)"
  end
end
```

### MySQL Features
```ruby
class MySQLFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :posts, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.string :title, limit: 191  # For utf8mb4 unique index
      t.text :content, limit: 16777215  # MEDIUMTEXT
      t.timestamps
    end
    
    # Full-text index
    add_index :posts, [:title, :content], type: :fulltext
  end
end
```

## Best Practices

### Migration Guidelines
```ruby
class GoodMigration < ActiveRecord::Migration[7.1]
  # 1. Always provide null constraints and defaults
  def change
    create_table :users do |t|
      t.string :name, null: false, default: ''
      t.string :email, null: false
      t.boolean :active, null: false, default: true
      t.timestamps null: false
    end
    
    # 2. Add indexes for foreign keys and commonly queried columns
    add_index :users, :email, unique: true
  end
end

# 3. Use reversible migrations for complex operations
class DataMigration < ActiveRecord::Migration[7.1]
  def up
    # Forward operation
    User.where(status: nil).update_all(status: 'active')
  end
  
  def down
    # Reverse operation (if possible)
    User.where(status: 'active').update_all(status: nil)
  end
end
```

### Safe Production Migrations
```ruby
# Bad - can lock table
class BadMigration < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :phone, :string, null: false, default: ''
  end
end

# Good - safe for large tables
class GoodMigration < ActiveRecord::Migration[7.1]
  def change
    # Step 1: Add column as nullable
    add_column :users, :phone, :string
    
    # Step 2: Backfill data (do this in separate migration)
    # User.in_batches.update_all(phone: '')
    
    # Step 3: Add constraint (do this in separate migration)
    # change_column_null :users, :phone, false
  end
end
```

## Troubleshooting

### Common Issues
```bash
# Migration stuck
rails db:migrate:status
rails db:migrate VERSION=specific_version

# Schema out of sync
rails db:schema:load

# Rollback failed migration
rails db:rollback
# Fix the migration file
rails db:migrate

# Reset migration version
rails runner "ActiveRecord::SchemaMigration.find_by(version: 'version_number').delete"
```

### Debug Migration Problems
```ruby
class DebugMigration < ActiveRecord::Migration[7.1]
  def change
    # Check current state
    puts "Current columns: #{User.column_names}"
    
    # Check if column exists before adding
    unless column_exists?(:users, :phone)
      add_column :users, :phone, :string
    end
    
    # Check if index exists before adding
    unless index_exists?(:users, :email)
      add_index :users, :email
    end
  end
end
```

## References

- [Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html)
- [Rails Database Migrations](https://edgeguides.rubyonrails.org/active_record_migrations.html)
- [Schema Dumper](https://guides.rubyonrails.org/active_record_migrations.html#schema-dumping-and-you)