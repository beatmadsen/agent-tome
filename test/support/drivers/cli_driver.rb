require "json"
require "open3"

class CliDriver
  BIN_PATH = File.expand_path("../../../../exe/agent-tome", __FILE__)
  LIB_PATH = File.expand_path("../../../../lib", __FILE__)

  def initialize(db_path:, config_dir:)
    @db_path = db_path
    @config_dir = config_dir
    setup_connection!
  end

  # Commands run in their own process, but the test still asserts on the store
  # the same way it does under the service driver, so this process needs its
  # own connection to the same database.
  def setup_connection!
    config = Agent::Tome::Config.new(config_dir: @config_dir)
    config.load!
    Agent::Tome::Database.connect!(config.db_path)
  end

  def disconnect!
    Agent::Tome::Database.disconnect!
  rescue StandardError
    nil
  end

  def create(description: nil, body: :__unset__, keywords: [], web_sources: [], file_sources: [],
             related_article_ids: [])
    input = build_input(
      "description" => description,
      "body" => (body == :__unset__ ? nil : body),
      "keywords" => keywords,
      "web_sources" => web_sources.map(&method(:stringify_keys)),
      "file_sources" => file_sources.map(&method(:stringify_keys)),
      "related_article_ids" => related_article_ids
    )

    run_command("create", stdin: JSON.generate(input))
  end

  def addend(article_global_id, body: nil, keywords: [], web_sources: [], file_sources: [], related_article_ids: [])
    input = {}
    input["body"] = body unless body.nil?
    input["keywords"] = keywords
    input["web_sources"] = web_sources.map(&method(:stringify_keys))
    input["file_sources"] = file_sources.map(&method(:stringify_keys))
    input["related_article_ids"] = related_article_ids

    run_command("addend", article_global_id, stdin: JSON.generate(input))
  end

  def search(keywords, match: "any")
    args = keywords + (match == "any" ? [] : ["--match", match])
    run_command("search", *args)
  end

  def fetch(global_id)
    run_command("fetch", global_id)
  end

  def consolidate(global_id, body: :__unset__, description: nil)
    input = {}
    input["body"] = body unless body == :__unset__
    input["description"] = description if description
    run_command("consolidate", global_id, stdin: JSON.generate(input))
  end

  def related(global_id)
    run_command("related", global_id)
  end

  def keywords(prefix)
    prefix.nil? ? run_command("keywords") : run_command("keywords", prefix)
  end

  def source_search(source, system: nil)
    args = [source]
    args += ["--system", system] if system
    run_command("source-search", *args)
  end

  private

  def run_command(*args, stdin: nil)
    env = {
      "AGENT_TOME_CONFIG_DIR" => @config_dir,
      "RUBYLIB" => LIB_PATH
    }

    cmd = [RbConfig.ruby, BIN_PATH] + args

    stdout, stderr, status = Open3.capture3(env, *cmd, stdin_data: stdin || "")
    exit_code = status.exitstatus

    begin
      data = JSON.parse(stdout)
      if exit_code != 0 && data.is_a?(Hash) && data.key?("error")
        TomeTest::Result.new(error_message: data["error"], exit_code: exit_code, data: data)
      else
        TomeTest::Result.new(data: data, exit_code: exit_code)
      end
    rescue JSON::ParserError
      TomeTest::Result.new(error_message: "Invalid JSON output: #{stdout}#{stderr}", exit_code: exit_code)
    end
  end

  def build_input(hash)
    hash.reject { |_, v| v.nil? || (v.is_a?(Array) && v.empty?) }
  end

  def stringify_keys(hash)
    return hash if hash.is_a?(Hash) && hash.keys.all? { |k| k.is_a?(String) }

    hash.transform_keys(&:to_s)
  end
end
