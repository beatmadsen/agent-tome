module Agent
  module Tome
    class EntryWebSource < ApplicationRecord
      belongs_to :entry
      belongs_to :web_source

      validates :entry_id, uniqueness: { scope: :web_source_id }
    end
  end
end
