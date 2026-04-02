module Agent
  module Tome
    class Keyword < ApplicationRecord
      has_many :article_keywords, dependent: :destroy
      has_many :articles, through: :article_keywords

      validates :term, presence: true, uniqueness: true
    end
  end
end
