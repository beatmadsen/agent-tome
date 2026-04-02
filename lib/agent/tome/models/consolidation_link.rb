module Agent
  module Tome
    class ConsolidationLink < ApplicationRecord
      belongs_to :new_article, class_name: "Agent::Tome::Article"
      belongs_to :old_article, class_name: "Agent::Tome::Article"
    end
  end
end
