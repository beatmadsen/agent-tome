module Agent
  module Tome
    class FileSource < ApplicationRecord
      has_many :entry_file_sources, dependent: :destroy
      has_many :entries, through: :entry_file_sources

      validates :global_id, presence: true, length: { is: 7 }, uniqueness: true
      validates :path, presence: true
      validates :system_name, presence: true
      validates :path, uniqueness: { scope: :system_name }

      before_validation :assign_global_id, on: :create

      private

      def assign_global_id
        return if global_id.present?

        self.global_id = GlobalId.generate
      end
    end
  end
end
