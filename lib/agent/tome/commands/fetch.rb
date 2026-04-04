module Agent
  module Tome
    module Commands
      class Fetch
        def initialize(global_id:)
          @global_id = global_id
        end

        def call
          article = Article.find_by(global_id: @global_id)
          raise NotFoundError, "Article not found: #{@global_id}" unless article

          result = ArticleFormatter.summary(article, "entries" => format_entries(article))

          if (link = article.consolidation_as_new)
            old = link.old_article
            result["consolidated_from"] = {
              "global_id" => old.global_id,
              "description" => old.description
            }
          end

          result
        end

        private

        def format_entries(article)
          article.entries.order(:created_at).map do |entry|
            {
              "global_id" => entry.global_id,
              "body" => entry.body,
              "created_at" => entry.created_at.iso8601,
              "web_sources" => format_web_sources(entry),
              "file_sources" => format_file_sources(entry)
            }
          end
        end

        def format_web_sources(entry)
          entry.web_sources.map do |ws|
            {
              "global_id" => ws.global_id,
              "url" => ws.url,
              "title" => ws.title,
              "fetched_at" => ws.fetched_at&.iso8601
            }
          end
        end

        def format_file_sources(entry)
          entry.file_sources.map do |fs|
            {
              "global_id" => fs.global_id,
              "path" => fs.path,
              "system_name" => fs.system_name
            }
          end
        end
      end
    end
  end
end
