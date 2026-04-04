module Agent
  module Tome
    module ArticleFormatter
      def self.summary(article, extras = {})
        result = {
          "global_id" => article.global_id,
          "description" => article.description,
          "keywords" => article.keywords.pluck(:term).sort,
          "created_at" => article.created_at.iso8601
        }
        result.merge!(extras) if extras.any?
        result
      end
    end
  end
end
