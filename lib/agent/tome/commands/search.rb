require "active_support/core_ext/string/inflections"

module Agent
  module Tome
    module Commands
      class Search
        def initialize(keywords:, match: "any")
          @keywords = keywords
          @match = match
        end

        def call
          raise ValidationError, "At least one keyword is required" if @keywords.empty?

          normalized = @keywords.map { |kw| normalize_keyword(kw) }
          keyword_ids = Keyword.where(term: normalized).pluck(:id)

          return { "results" => [] } if keyword_ids.empty?

          articles = find_matching_articles(keyword_ids, normalized)

          {
            "results" => articles.first(1000).map { |row| format_result(row) }
          }
        end

        private

        def find_matching_articles(keyword_ids, normalized_terms)
          base = Article
            .joins(:article_keywords)
            .where(article_keywords: { keyword_id: keyword_ids })
            .group("articles.id")
            .select("articles.*, COUNT(DISTINCT article_keywords.keyword_id) AS matching_keyword_count")
            .order("matching_keyword_count DESC")

          if @match == "all"
            base = base.having("COUNT(DISTINCT article_keywords.keyword_id) = ?", keyword_ids.length)
          end

          base.limit(1000)
        end

        def format_result(article)
          {
            "global_id" => article.global_id,
            "description" => article.description,
            "keywords" => article.keywords.pluck(:term).sort,
            "matching_keyword_count" => article.matching_keyword_count.to_i,
            "created_at" => article.created_at.iso8601
          }
        end

        def normalize_keyword(kw)
          words = kw.downcase.split("-")
          words[-1] = ActiveSupport::Inflector.singularize(words[-1])
          words.join("-")
        end
      end
    end
  end
end
