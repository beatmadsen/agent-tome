module Agent
  module Tome
    module Commands
      class KeywordsList
        def initialize(prefix:)
          @prefix = prefix
        end

        def call
          raise ValidationError, "A prefix/substring argument is required" if @prefix.nil? || @prefix.strip.empty?

          terms = Keyword
            .where("LOWER(term) LIKE ? ESCAPE '\\'", "%#{Keyword.sanitize_sql_like(@prefix.downcase)}%")
            .order(:term)
            .pluck(:term)

          { "keywords" => terms }
        end
      end
    end
  end
end
