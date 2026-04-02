module Agent
  module Tome
    class Article < ApplicationRecord
      has_many :entries, dependent: :destroy
      has_many :article_keywords, dependent: :destroy
      has_many :keywords, through: :article_keywords
      has_many :source_references,
               class_name: "Agent::Tome::ArticleReference",
               foreign_key: :source_article_id,
               dependent: :destroy
      has_many :target_references,
               class_name: "Agent::Tome::ArticleReference",
               foreign_key: :target_article_id,
               dependent: :destroy
      has_one :consolidation_as_new,
              class_name: "Agent::Tome::ConsolidationLink",
              foreign_key: :new_article_id
      has_one :consolidation_as_old,
              class_name: "Agent::Tome::ConsolidationLink",
              foreign_key: :old_article_id

      validates :global_id, presence: true, length: { is: 7 }, uniqueness: true
      validates :description, presence: true, length: { maximum: 350 }

      before_validation :assign_global_id, on: :create

      private

      def assign_global_id
        return if global_id.present?

        self.global_id = GlobalId.generate
      end
    end
  end
end
