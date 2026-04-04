module Agent
  module Tome
    module FileSourceLinker
      def self.call(entry, sources)
        sources.map do |src|
          fs = FileSource.find_or_create_by!(path: src["path"], system_name: src["system_name"]) do |f|
            f.global_id = GlobalId.generate
            f.created_at = Time.now
          end
          EntryFileSource.find_or_create_by!(entry: entry, file_source: fs) do |efs|
            efs.created_at = Time.now
          end
          fs.global_id
        end
      end
    end
  end
end
