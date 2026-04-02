module Agent
  module Tome
    module Commands
      class SourceSearch
        def initialize(source:, system: nil)
          @source = source
          @system = system
        end

        def call
          articles = if url?(@source)
            search_by_url
          else
            search_by_path
          end

          {
            "results" => articles.map { |a| format_article(a) }
          }
        end

        private

        def url?(str)
          str.start_with?("http://", "https://")
        end

        def search_by_url
          normalized = UrlNormalizer.normalize(@source)
          ws = WebSource.find_by(url: normalized)
          return [] unless ws

          Article
            .joins(entries: :web_sources)
            .where(web_sources: { id: ws.id })
            .distinct
        end

        def search_by_path
          scope = Article
            .joins(entries: :file_sources)
            .where(file_sources: { path: @source })

          scope = scope.where(file_sources: { system_name: @system }) if @system

          scope.distinct
        end

        def format_article(article)
          {
            "global_id" => article.global_id,
            "description" => article.description,
            "keywords" => article.keywords.pluck(:term).sort,
            "created_at" => article.created_at.iso8601
          }
        end
      end
    end
  end
end
