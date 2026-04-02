module Agent
  module Tome
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
      self.table_name_prefix = ""
    end
  end
end
