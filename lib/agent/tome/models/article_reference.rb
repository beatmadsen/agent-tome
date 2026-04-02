module Agent
  module Tome
    class ArticleReference < ApplicationRecord
      belongs_to :source_article, class_name: "Agent::Tome::Article"
      belongs_to :target_article, class_name: "Agent::Tome::Article"

      validates :source_article_id, uniqueness: { scope: :target_article_id }
      validate :not_self_referencing

      private

      def not_self_referencing
        return unless source_article_id && target_article_id
        return unless source_article_id == target_article_id

        errors.add(:base, "An article cannot reference itself")
      end
    end
  end
end
