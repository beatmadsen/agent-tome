require "test_helper"

# AT-5.2: Fetch article with multiple entries
class FetchMultipleEntriesTest < Minitest::Test
  include TomeDsl

  def test_entries_returned_in_chronological_order
    create_result = create_article!(
      description: "Ruby GC internals",
      body: "Mark and sweep is the base algorithm."
    )
    article_id = create_result.article_global_id
    first_entry_id = create_result.entry_global_id

    addend1 = tome.addend(article_id, body: "Generational GC was added in Ruby 2.1.")
    assert_success addend1, "First addend failed: #{addend1.error_message}"
    second_entry_id = addend1.entry_global_id

    addend2 = tome.addend(article_id, body: "Incremental GC was added in Ruby 2.2.")
    assert_success addend2, "Second addend failed: #{addend2.error_message}"
    third_entry_id = addend2.entry_global_id

    result = tome.fetch(article_id)

    assert_success result, "Fetch failed: #{result.error_message}"
    entries = result.entries
    assert_equal 3, entries.length

    assert_equal first_entry_id, entries[0]["global_id"]
    assert_equal "Mark and sweep is the base algorithm.", entries[0]["body"]

    assert_equal second_entry_id, entries[1]["global_id"]
    assert_equal "Generational GC was added in Ruby 2.1.", entries[1]["body"]

    assert_equal third_entry_id, entries[2]["global_id"]
    assert_equal "Incremental GC was added in Ruby 2.2.", entries[2]["body"]

    # Verify chronological order via created_at timestamps
    times = entries.map { |e| Time.iso8601(e["created_at"]) }
    assert_equal times.sort, times, "Entries should be in chronological order"
  end
end
