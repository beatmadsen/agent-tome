module Agent
  module Tome
    module Commands
      class Related
        def initialize(global_id:)
          @global_id = global_id
        end

        def call
          article = Article.find_by(global_id: @global_id)
          raise NotFoundError, "Article not found: #{@global_id}" unless article

          {
            "shared_keywords" => find_shared_keywords(article),
            "references_to" => find_references_to(article),
            "referenced_by" => find_referenced_by(article),
            "consolidated_from" => find_consolidated_from(article),
            "consolidated_into" => find_consolidated_into(article)
          }
        end

        private

        def find_shared_keywords(article)
          keyword_ids = article.keywords.pluck(:id)
          return [] if keyword_ids.empty?

          Article
            .joins(:article_keywords)
            .where(article_keywords: { keyword_id: keyword_ids })
            .where.not(id: article.id)
            .group("articles.id")
            .select("articles.*, COUNT(DISTINCT article_keywords.keyword_id) AS shared_keyword_count")
            .order("shared_keyword_count DESC")
            .limit(100)
            .map { |a| format_article(a, shared_keyword_count: a.shared_keyword_count.to_i) }
        end

        def find_references_to(article)
          ArticleReference
            .where(source_article: article)
            .includes(:target_article)
            .map { |ref| format_article(ref.target_article) }
        end

        def find_referenced_by(article)
          ArticleReference
            .where(target_article: article)
            .includes(:source_article)
            .map { |ref| format_article(ref.source_article) }
        end

        def find_consolidated_from(article)
          ConsolidationLink
            .where(new_article: article)
            .includes(:old_article)
            .map { |link| format_article(link.old_article) }
        end

        def find_consolidated_into(article)
          ConsolidationLink
            .where(old_article: article)
            .includes(:new_article)
            .map { |link| format_article(link.new_article) }
        end

        def format_article(article, extra = {})
          base = {
            "global_id" => article.global_id,
            "description" => article.description,
            "keywords" => article.keywords.pluck(:term).sort,
            "created_at" => article.created_at.iso8601
          }
          base.merge!(extra.transform_keys(&:to_s)) if extra.any?
          base
        end
      end
    end
  end
end
