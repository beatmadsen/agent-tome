require "active_record"
require "active_support"
require "active_support/core_ext/string/inflections"
require "fileutils"
require "yaml"
require "uri"
require "json"
require "time"

require_relative "tome/version"
require_relative "tome/config"
require_relative "tome/database"
require_relative "tome/global_id"
require_relative "tome/url_normalizer"
require_relative "tome/keyword_normalizer"
require_relative "tome/keyword_linker"
require_relative "tome/web_source_linker"
require_relative "tome/file_source_linker"
require_relative "tome/related_article_linker"
require_relative "tome/input_validator"

module Agent
  module Tome
    def self.table_name_prefix
      ""
    end

    class ValidationError < StandardError; end
    class NotFoundError < StandardError; end
  end
end

require_relative "tome/models/application_record"
require_relative "tome/models/article"
require_relative "tome/models/entry"
require_relative "tome/models/keyword"
require_relative "tome/models/article_keyword"
require_relative "tome/models/web_source"
require_relative "tome/models/file_source"
require_relative "tome/models/entry_web_source"
require_relative "tome/models/entry_file_source"
require_relative "tome/models/article_reference"
require_relative "tome/models/consolidation_link"
require_relative "tome/commands/create"
require_relative "tome/commands/addend"
require_relative "tome/commands/search"
require_relative "tome/commands/fetch"
require_relative "tome/commands/consolidate"
require_relative "tome/commands/related"
require_relative "tome/commands/keywords_list"
require_relative "tome/commands/source_search"
require_relative "tome/cli"
