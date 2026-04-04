module Agent
  module Tome
    module Commands
      class Addend
        def initialize(article_global_id:)
          @article_global_id = article_global_id
        end

        def call(input)
          article = Article.find_by(global_id: @article_global_id)
          raise NotFoundError, "Article not found: #{@article_global_id}" unless article

          validate!(input)

          result = {}

          ActiveRecord::Base.transaction do
            entry = Entry.create!(
              article: article,
              body: input["body"].to_s.strip.empty? ? nil : input["body"],
              created_at: Time.now
            )

            KeywordLinker.call(article, input["keywords"] || [])
            web_source_ids = WebSourceLinker.call(entry, input["web_sources"] || [])
            file_source_ids = FileSourceLinker.call(entry, input["file_sources"] || [])
            RelatedArticleLinker.call(article, input["related_article_ids"] || [])

            result = {
              "entry_global_id" => entry.global_id,
              "web_source_global_ids" => web_source_ids,
              "file_source_global_ids" => file_source_ids
            }
          end

          result
        end

        private

        def validate!(input)
          body = input["body"]
          if body && !body.to_s.strip.empty?
            return
          end

          keywords = input["keywords"] || []
          web_sources = input["web_sources"] || []
          file_sources = input["file_sources"] || []
          related = input["related_article_ids"] || []

          if body.is_a?(String) && body.strip.empty?
            raise ValidationError, "body cannot be blank"
          end

          if keywords.empty? && web_sources.empty? && file_sources.empty? && related.empty?
            raise ValidationError, "At least one field must be substantively present"
          end

          InputValidator.validate_keywords!(keywords) if keywords.any?
          InputValidator.validate_web_sources!(web_sources) if web_sources.any?
          InputValidator.validate_file_sources!(file_sources) if file_sources.any?
          InputValidator.validate_related_ids!(input["related_article_ids"]) if input.key?("related_article_ids")
        end

      end
    end
  end
end
