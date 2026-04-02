require "yaml"

class ServiceDriver
  def initialize(db_path:, config_dir:)
    @db_path = db_path
    @config_dir = config_dir
    setup_connection!
  end

  def disconnect!
    Agent::Tome::Database.disconnect!
  rescue StandardError
    nil
  end

  def create(description: nil, body: :__unset__, keywords: [], web_sources: [], file_sources: [], related_article_ids: [])
    input = build_input(
      "description" => description,
      "body" => (body == :__unset__ ? nil : body),
      "keywords" => keywords,
      "web_sources" => web_sources.map(&method(:stringify_keys)),
      "file_sources" => file_sources.map(&method(:stringify_keys)),
      "related_article_ids" => related_article_ids
    )

    data = Agent::Tome::Commands::Create.new.call(input)
    TomeTest::Result.new(data: data)
  rescue Agent::Tome::ValidationError, Agent::Tome::NotFoundError => e
    TomeTest::Result.new(error_message: e.message, exit_code: 1)
  end

  def addend(article_global_id, body: nil, keywords: [], web_sources: [], file_sources: [], related_article_ids: [])
    input = {}
    input["body"] = body unless body.nil?
    input["keywords"] = keywords
    input["web_sources"] = web_sources.map(&method(:stringify_keys))
    input["file_sources"] = file_sources.map(&method(:stringify_keys))
    input["related_article_ids"] = related_article_ids

    data = Agent::Tome::Commands::Addend.new(article_global_id: article_global_id).call(input)
    TomeTest::Result.new(data: data)
  rescue Agent::Tome::ValidationError, Agent::Tome::NotFoundError => e
    TomeTest::Result.new(error_message: e.message, exit_code: 1)
  end

  def search(keywords, match: "any")
    data = Agent::Tome::Commands::Search.new(keywords: keywords, match: match).call
    TomeTest::Result.new(data: data)
  rescue Agent::Tome::ValidationError => e
    TomeTest::Result.new(error_message: e.message, exit_code: 1)
  end

  def fetch(global_id)
    data = Agent::Tome::Commands::Fetch.new(global_id: global_id).call
    TomeTest::Result.new(data: data)
  rescue Agent::Tome::NotFoundError => e
    TomeTest::Result.new(error_message: e.message, exit_code: 1)
  end

  def consolidate(global_id, body: :__unset__, description: nil)
    input = {}
    input["body"] = body unless body == :__unset__
    input["description"] = description if description
    data = Agent::Tome::Commands::Consolidate.new(global_id: global_id).call(input)
    TomeTest::Result.new(data: data)
  rescue Agent::Tome::ValidationError, Agent::Tome::NotFoundError => e
    TomeTest::Result.new(error_message: e.message, exit_code: 1)
  end

  def related(global_id)
    data = Agent::Tome::Commands::Related.new(global_id: global_id).call
    TomeTest::Result.new(data: data)
  rescue Agent::Tome::NotFoundError => e
    TomeTest::Result.new(error_message: e.message, exit_code: 1)
  end

  def keywords(prefix)
    data = Agent::Tome::Commands::KeywordsList.new(prefix: prefix).call
    TomeTest::Result.new(data: data)
  rescue Agent::Tome::ValidationError => e
    TomeTest::Result.new(error_message: e.message, exit_code: 1)
  end

  def source_search(source, system: nil)
    data = Agent::Tome::Commands::SourceSearch.new(source: source, system: system).call
    TomeTest::Result.new(data: data)
  rescue Agent::Tome::ValidationError => e
    TomeTest::Result.new(error_message: e.message, exit_code: 1)
  end

  private

  def setup_connection!
    config = Agent::Tome::Config.new(config_dir: @config_dir)
    config.load!
    Agent::Tome::Database.connect!(config.db_path)
  end

  def build_input(hash)
    hash.reject { |_, v| v.nil? || (v.is_a?(Array) && v.empty?) }
  end

  def stringify_keys(hash)
    return hash if hash.is_a?(Hash) && hash.keys.all? { |k| k.is_a?(String) }

    hash.transform_keys(&:to_s)
  end
end
