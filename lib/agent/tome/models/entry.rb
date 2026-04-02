module Agent
  module Tome
    class Entry < ApplicationRecord
      belongs_to :article
      has_many :entry_web_sources, dependent: :destroy
      has_many :web_sources, through: :entry_web_sources
      has_many :entry_file_sources, dependent: :destroy
      has_many :file_sources, through: :entry_file_sources

      validates :global_id, presence: true, length: { is: 7 }, uniqueness: true

      before_validation :assign_global_id, on: :create

      private

      def assign_global_id
        return if global_id.present?

        self.global_id = GlobalId.generate
      end
    end
  end
end
