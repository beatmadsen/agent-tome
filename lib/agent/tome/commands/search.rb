module Agent
  module Tome
    module Commands
      class Search
        def initialize(keywords:, match: "any")
          @keywords = keywords
          @match = match
        end

        MATCH_MODES = %w[any all].freeze

        def call
          raise ValidationError, "At least one keyword is required" if @keywords.empty?
          raise ValidationError, "--match must be 'any' or 'all'" unless MATCH_MODES.include?(@match)

          normalized = @keywords.map { |kw| KeywordNormalizer.call(kw) }
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
            base = base.having("COUNT(DISTINCT article_keywords.keyword_id) = ?", normalized_terms.uniq.length)
          end

          base.limit(1000)
        end

        def format_result(article)
          ArticleFormatter.summary(article, "matching_keyword_count" => article.matching_keyword_count.to_i)
        end

      end
    end
  end
end
