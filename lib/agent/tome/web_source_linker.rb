module Agent
  module Tome
    module WebSourceLinker
      def self.call(entry, sources)
        sources.map do |src|
          normalized_url = UrlNormalizer.normalize(src["url"])
          ws = WebSource.find_or_create_by!(url: normalized_url) do |w|
            w.global_id = GlobalId.generate
            w.title = src["title"]
            w.fetched_at = src["fetched_at"] ? Time.parse(src["fetched_at"]) : nil
            w.created_at = Time.now
          end
          EntryWebSource.find_or_create_by!(entry: entry, web_source: ws) do |ews|
            ews.created_at = Time.now
          end
          ws.global_id
        end
      end
    end
  end
end
