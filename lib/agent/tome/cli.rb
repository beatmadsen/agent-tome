require "json"
require "optparse"

module Agent
  module Tome
    class CLI
      def self.run(argv)
        new(argv).run
      end

      def initialize(argv)
        @argv = argv.dup
      end

      def run
        command = @argv.shift

        if command.nil?
          output_error("No command provided")
          exit 1
        end

        config = Config.new
        begin
          config.load!
        rescue ConfigError => e
          output_error(e.message)
          exit 1
        end

        begin
          Database.connect!(config.db_path)
        rescue DatabaseError => e
          output_error(e.message)
          exit 1
        end

        dispatch(command)
      rescue ValidationError => e
        output_error(e.message)
        exit 1
      rescue NotFoundError => e
        output_error(e.message)
        exit 1
      rescue => e
        output_error(e.message)
        exit 1
      end

      private

      def dispatch(command)
        case command
        when "create"
          input = read_stdin_json
          result = Commands::Create.new.call(input)
          puts JSON.generate(result)
        when "addend"
          article_id = @argv.shift
          raise ValidationError, "article_global_id is required" if article_id.nil? || article_id.strip.empty?

          input = read_stdin_json
          result = Commands::Addend.new(article_global_id: article_id).call(input)
          puts JSON.generate(result)
        when "search"
          keywords, match = parse_search_args
          result = Commands::Search.new(keywords: keywords, match: match).call
          puts JSON.generate(result)
        when "fetch"
          global_id = @argv.shift
          raise ValidationError, "global_id is required" if global_id.nil? || global_id.strip.empty?

          result = Commands::Fetch.new(global_id: global_id).call
          puts JSON.generate(result)
        when "consolidate"
          global_id = @argv.shift
          raise ValidationError, "global_id is required" if global_id.nil? || global_id.strip.empty?

          input = read_stdin_json
          result = Commands::Consolidate.new(global_id: global_id).call(input)
          puts JSON.generate(result)
        when "related"
          global_id = @argv.shift
          raise ValidationError, "global_id is required" if global_id.nil? || global_id.strip.empty?

          result = Commands::Related.new(global_id: global_id).call
          puts JSON.generate(result)
        when "keywords"
          prefix = @argv.shift
          result = Commands::KeywordsList.new(prefix: prefix).call
          puts JSON.generate(result)
        when "source-search"
          source, system = parse_source_search_args
          result = Commands::SourceSearch.new(source: source, system: system).call
          puts JSON.generate(result)
        else
          output_error("Unknown command: #{command}")
          exit 1
        end

        exit 0
      end

      def read_stdin_json
        raw = $stdin.read
        raise ValidationError, "Empty input" if raw.nil? || raw.strip.empty?

        JSON.parse(raw)
      rescue JSON::ParserError => e
        raise ValidationError, "Invalid JSON input: #{e.message}"
      end

      def parse_search_args
        match = "any"
        keywords = []

        i = 0
        while i < @argv.length
          if @argv[i] == "--match" && i + 1 < @argv.length
            match = @argv[i + 1]
            i += 2
          else
            keywords << @argv[i]
            i += 1
          end
        end

        [keywords, match]
      end

      def parse_source_search_args
        source = @argv.shift
        system = nil

        if @argv[0] == "--system" && @argv[1]
          @argv.shift
          system = @argv.shift
        end

        [source, system]
      end

      def output_error(message)
        puts JSON.generate({ "error" => message })
      end
    end
  end
end
