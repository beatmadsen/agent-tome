module Agent
  module Tome
    class ArticleKeyword < ApplicationRecord
      belongs_to :article
      belongs_to :keyword

      validates :article_id, uniqueness: { scope: :keyword_id }
    end
  end
end
