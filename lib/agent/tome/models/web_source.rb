module Agent
  module Tome
    class WebSource < ApplicationRecord
      has_many :entry_web_sources, dependent: :destroy
      has_many :entries, through: :entry_web_sources

      validates :global_id, presence: true, length: { is: 7 }, uniqueness: true
      validates :url, presence: true, uniqueness: true

      before_validation :assign_global_id, on: :create

      private

      def assign_global_id
        return if global_id.present?

        self.global_id = GlobalId.generate
      end
    end
  end
end
