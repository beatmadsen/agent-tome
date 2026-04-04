module Agent
  module Tome
    module Commands
      class Create
        def call(input)
          validate!(input)

          result = {}

          ActiveRecord::Base.transaction do
            article = Article.create!(
              description: input["description"],
              created_at: Time.now
            )

            entry = Entry.create!(
              article: article,
              body: input["body"],
              created_at: Time.now
            )

            KeywordLinker.call(article, input["keywords"] || [])
            web_source_ids = WebSourceLinker.call(entry, input["web_sources"] || [])
            file_source_ids = FileSourceLinker.call(entry, input["file_sources"] || [])
            RelatedArticleLinker.call(article, input["related_article_ids"] || [])

            result = {
              "article_global_id" => article.global_id,
              "entry_global_id" => entry.global_id,
              "web_source_global_ids" => web_source_ids,
              "file_source_global_ids" => file_source_ids
            }
          end

          result
        end

        private

        def validate!(input)
          raise ValidationError, "Missing description" unless input.key?("description")
          raise ValidationError, "Missing body" unless input.key?("body")

          desc = input["description"]
          raise ValidationError, "description must be a string" unless desc.is_a?(String)
          raise ValidationError, "description cannot be blank" if desc.strip.empty?
          raise ValidationError, "description must be 350 characters or fewer" if desc.length > 350

          body = input["body"]
          raise ValidationError, "body must be a string" unless body.is_a?(String)
          raise ValidationError, "body cannot be blank" if body.strip.empty?

          InputValidator.validate_keywords!(input["keywords"]) if input.key?("keywords")
          InputValidator.validate_web_sources!(input["web_sources"]) if input.key?("web_sources")
          InputValidator.validate_file_sources!(input["file_sources"]) if input.key?("file_sources")
          InputValidator.validate_related_ids!(input["related_article_ids"]) if input.key?("related_article_ids")
        end

      end
    end
  end
end
