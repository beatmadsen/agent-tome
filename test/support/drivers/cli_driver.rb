require "json"
require "open3"

class CliDriver
  BIN_PATH = File.expand_path("../../../../bin/agent-tome", __FILE__)
  LIB_PATH = File.expand_path("../../../../lib", __FILE__)

  def initialize(db_path:, config_dir:)
    @db_path = db_path
    @config_dir = config_dir
  end

  def disconnect!
    # No-op for CLI driver: each invocation is isolated
  end

  def create(description:, body:, keywords: [], web_sources: [], file_sources: [], related_article_ids: [])
    input = { "description" => description, "body" => body }
    input["keywords"] = keywords unless keywords.empty?
    input["web_sources"] = web_sources.map(&method(:stringify_keys)) unless web_sources.empty?
    input["file_sources"] = file_sources.map(&method(:stringify_keys)) unless file_sources.empty?
    input["related_article_ids"] = related_article_ids unless related_article_ids.empty?

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
    run_command("keywords", prefix)
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
      TomeTest::Result.new(error_message: "Invalid JSON output: #{stdout}", exit_code: exit_code)
    end
  end

  def stringify_keys(hash)
    return hash if hash.is_a?(Hash) && hash.keys.all? { |k| k.is_a?(String) }

    hash.transform_keys(&:to_s)
  end
end
