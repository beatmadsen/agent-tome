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

          result = {}

          ActiveRecord::Base.transaction do
            original_global_id = article.global_id
            new_description = input["description"] || article.description

            # Assign old article a new global_id
            old_global_id = GlobalId.generate
            article.update_columns(global_id: old_global_id)

            # Create the new consolidated article with the original global_id
            new_article = Article.create!(
              global_id: original_global_id,
              description: new_description,
              created_at: Time.now
            )

            # Create the first (and only) entry for the consolidated article
            Entry.create!(
              article: new_article,
              body: input["body"],
              created_at: Time.now
            )

            # Copy keywords from old article to new article
            article.keywords.each do |keyword|
              ArticleKeyword.find_or_create_by!(article: new_article, keyword: keyword) do |ak|
                ak.created_at = Time.now
              end
            end

            # Create consolidation link
            ConsolidationLink.create!(
              new_article: new_article,
              old_article: article,
              created_at: Time.now
            )

            result = {
              "new_article_global_id" => new_article.global_id,
              "old_article_global_id" => article.global_id
            }
          end

          result
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
      end
    end
  end
end
