require "test_helper"

class WebSourceLinkerTest < Minitest::Test
  def test_normalizes_url_creates_web_source_and_links_to_entry
    entry = Object.new
    fake_global_id = "abc1234"
    ws_record = Struct.new(:global_id).new(fake_global_id)

    normalized_urls = []
    linked_pairs = []

    find_or_create_ws = lambda { |url:, **|
      normalized_urls << url
      ws_record
    }

    find_or_create_link = lambda { |entry:, web_source:, **|
      linked_pairs << { entry: entry, web_source: web_source }
    }

    result = Agent::Tome::UrlNormalizer.stub(:normalize, "http://example.com") do
      Agent::Tome::WebSource.stub(:find_or_create_by!, find_or_create_ws) do
        Agent::Tome::EntryWebSource.stub(:find_or_create_by!, find_or_create_link) do
          Agent::Tome::WebSourceLinker.call(entry, [{ "url" => "http://example.com?fbclid=123", "title" => "Example" }])
        end
      end
    end

    assert_equal ["http://example.com"], normalized_urls
    assert_equal [fake_global_id], result
    assert_equal 1, linked_pairs.size
    assert_equal entry, linked_pairs.first[:entry]
    assert_equal ws_record, linked_pairs.first[:web_source]
  end
end
