module Agent
  module Tome
    module Commands
      class Consolidate
        def initialize(global_id:)
          @global_id = global_id
        end

        def call(input)
          article = Article.find_by(global_id: @global_id)
          raise NotFoundError, "Article not found: #{@global_id}" unless article

          validate!(input)

          ActiveRecord::Base.transaction do
            original_global_id = swap_global_id!(article)
            new_article = create_consolidated_article(original_global_id, article, input)
            new_entry = create_consolidated_entry(new_article, input)
            copy_sources!(article, new_entry)
            copy_keywords!(article, new_article)
            ConsolidationLink.create!(new_article: new_article, old_article: article, created_at: Time.now)

            {
              "new_article_global_id" => new_article.global_id,
              "old_article_global_id" => article.global_id
            }
          end
        end

        private

        def validate!(input)
          raise ValidationError, "body is required" unless input.key?("body")

          body = input["body"]
          raise ValidationError, "body must be a string" unless body.is_a?(String)
          raise ValidationError, "body cannot be blank" if body.strip.empty?

          if input.key?("description")
            desc = input["description"]
            raise ValidationError, "description must be a string" unless desc.is_a?(String)
            raise ValidationError, "description must be 350 characters or fewer" if desc.length > 350
          end
        end

        def swap_global_id!(article)
          original_global_id = article.global_id
          article.update_columns(global_id: GlobalId.generate)
          original_global_id
        end

        def create_consolidated_article(original_global_id, old_article, input)
          Article.create!(
            global_id: original_global_id,
            description: input["description"] || old_article.description,
            created_at: Time.now
          )
        end

        def create_consolidated_entry(article, input)
          Entry.create!(article: article, body: input["body"], created_at: Time.now)
        end

        def copy_sources!(old_article, new_entry)
          old_article.entries.each do |old_entry|
            old_entry.web_sources.each do |ws|
              EntryWebSource.find_or_create_by!(entry: new_entry, web_source: ws)
            end
            old_entry.file_sources.each do |fs|
              EntryFileSource.find_or_create_by!(entry: new_entry, file_source: fs)
            end
          end
        end

        def copy_keywords!(old_article, new_article)
          old_article.keywords.each do |keyword|
            ArticleKeyword.find_or_create_by!(article: new_article, keyword: keyword) do |ak|
              ak.created_at = Time.now
            end
          end
        end
      end
    end
  end
end
