module Agent
  module Tome
    module KeywordLinker
      def self.call(article, keywords)
        keywords.each do |kw|
          normalized = KeywordNormalizer.call(kw)
          keyword = Keyword.find_or_create_by!(term: normalized) do |k|
            k.created_at = Time.now
          end
          ArticleKeyword.find_or_create_by!(article: article, keyword: keyword) do |ak|
            ak.created_at = Time.now
          end
        end
      end
    end
  end
end
