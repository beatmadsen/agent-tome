require "yaml"
require "fileutils"

module Agent
  module Tome
    class Config
      DEFAULT_CONFIG_DIR = File.expand_path("~/.agent-tome")

      attr_reader :db_path, :config_dir

      def initialize(config_dir: nil)
        @config_dir = config_dir || ENV.fetch("AGENT_TOME_CONFIG_DIR", DEFAULT_CONFIG_DIR)
      end

      def load!
        if File.directory?(@config_dir)
          read_config!
        else
          bootstrap!
          read_config!
        end
        self
      end

      private

      def bootstrap!
        FileUtils.mkdir_p(@config_dir)
        default_db = File.join(@config_dir, "tome.db")
        File.write(config_file_path, YAML.dump("db_path" => default_db))
      end

      def config_file_path
        File.join(@config_dir, "config.yml")
      end

      def read_config!
        raise ConfigError, "Config file not found: #{config_file_path}" unless File.exist?(config_file_path)

        data = YAML.load_file(config_file_path)

        unless data.is_a?(Hash) && data.key?("db_path") && !data["db_path"].to_s.strip.empty?
          raise ConfigError, "db_path is not configured in #{config_file_path}"
        end

        @db_path = data["db_path"]
      end
    end

    class ConfigError < StandardError; end
  end
end
