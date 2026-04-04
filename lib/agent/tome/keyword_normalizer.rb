module Agent
  module Tome
    module KeywordNormalizer
      def self.call(keyword)
        words = keyword.downcase.split("-")
        words[-1] = ActiveSupport::Inflector.singularize(words[-1])
        words.join("-")
      end
    end
  end
end
