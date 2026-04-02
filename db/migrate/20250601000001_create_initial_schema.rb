class CreateInitialSchema < ActiveRecord::Migration[7.1]
  def change
    create_table :articles do |t|
      t.string :global_id, limit: 7, null: false
      t.text :description, null: false
      t.datetime :created_at, null: false
    end
    add_index :articles, :global_id, unique: true

    create_table :entries do |t|
      t.string :global_id, limit: 7, null: false
      t.references :article, null: false, foreign_key: true
      t.text :body
      t.datetime :created_at, null: false
    end
    add_index :entries, :global_id, unique: true

    create_table :keywords do |t|
      t.string :term, null: false
      t.datetime :created_at, null: false
    end
    add_index :keywords, :term, unique: true

    create_table :article_keywords do |t|
      t.references :article, null: false, foreign_key: true
      t.references :keyword, null: false, foreign_key: true
      t.datetime :created_at, null: false
    end
    add_index :article_keywords, [:article_id, :keyword_id], unique: true

    create_table :web_sources do |t|
      t.string :global_id, limit: 7, null: false
      t.text :url, null: false
      t.string :title
      t.datetime :fetched_at
      t.datetime :created_at, null: false
    end
    add_index :web_sources, :global_id, unique: true
    add_index :web_sources, :url, unique: true

    create_table :file_sources do |t|
      t.string :global_id, limit: 7, null: false
      t.text :path, null: false
      t.string :system_name, null: false
      t.datetime :created_at, null: false
    end
    add_index :file_sources, :global_id, unique: true
    add_index :file_sources, [:path, :system_name], unique: true

    create_table :entry_web_sources do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :web_source, null: false, foreign_key: true
      t.datetime :created_at, null: false
    end
    add_index :entry_web_sources, [:entry_id, :web_source_id], unique: true

    create_table :entry_file_sources do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :file_source, null: false, foreign_key: true
      t.datetime :created_at, null: false
    end
    add_index :entry_file_sources, [:entry_id, :file_source_id], unique: true

    create_table :article_references do |t|
      t.bigint :source_article_id, null: false
      t.bigint :target_article_id, null: false
      t.datetime :created_at, null: false
    end
    add_index :article_references, :source_article_id
    add_index :article_references, :target_article_id
    add_index :article_references, [:source_article_id, :target_article_id], unique: true, name: "idx_article_refs_unique"
    add_foreign_key :article_references, :articles, column: :source_article_id
    add_foreign_key :article_references, :articles, column: :target_article_id

    create_table :consolidation_links do |t|
      t.bigint :new_article_id, null: false
      t.bigint :old_article_id, null: false
      t.datetime :created_at, null: false
    end
    add_index :consolidation_links, :new_article_id
    add_index :consolidation_links, :old_article_id
    add_foreign_key :consolidation_links, :articles, column: :new_article_id
    add_foreign_key :consolidation_links, :articles, column: :old_article_id
  end
end
