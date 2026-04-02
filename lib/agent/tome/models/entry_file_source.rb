module Agent
  module Tome
    class EntryFileSource < ApplicationRecord
      belongs_to :entry
      belongs_to :file_source

      validates :entry_id, uniqueness: { scope: :file_source_id }
    end
  end
end
