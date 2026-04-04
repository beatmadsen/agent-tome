require "test_helper"

class FileSourceLinkerTest < Minitest::Test
  def test_creates_file_source_and_links_to_entry
    entry = Object.new
    fake_global_id = "xyz7890"
    fs_record = Struct.new(:global_id).new(fake_global_id)

    created_sources = []
    linked_pairs = []

    find_or_create_fs = lambda { |path:, system_name:, **|
      created_sources << { path: path, system_name: system_name }
      fs_record
    }

    find_or_create_link = lambda { |entry:, file_source:, **|
      linked_pairs << { entry: entry, file_source: file_source }
    }

    result = Agent::Tome::FileSource.stub(:find_or_create_by!, find_or_create_fs) do
      Agent::Tome::EntryFileSource.stub(:find_or_create_by!, find_or_create_link) do
        Agent::Tome::FileSourceLinker.call(entry, [{ "path" => "/tmp/notes.md", "system_name" => "local" }])
      end
    end

    assert_equal [{ path: "/tmp/notes.md", system_name: "local" }], created_sources
    assert_equal [fake_global_id], result
    assert_equal 1, linked_pairs.size
    assert_equal entry, linked_pairs.first[:entry]
    assert_equal fs_record, linked_pairs.first[:file_source]
  end
end
