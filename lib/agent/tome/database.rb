require "active_record"
require "fileutils"

module Agent
  module Tome
    module Database
      MIGRATIONS_PATH = File.expand_path("../../../../db/migrate", __FILE__)

      def self.connect!(db_path)
        db_dir = File.dirname(db_path)

        unless File.directory?(db_dir)
          begin
            FileUtils.mkdir_p(db_dir)
          rescue Errno::EACCES, Errno::EPERM => e
            raise DatabaseError, "Database path is not writable: #{db_path} (#{e.message})"
          end
        end

        unless writable_path?(db_path)
          raise DatabaseError, "Database path is not writable: #{db_path}"
        end

        ActiveRecord::Base.logger = nil

        ActiveRecord::Base.establish_connection(
          adapter: "sqlite3",
          database: db_path
        )

        ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")

        run_migrations!
      rescue Errno::EACCES, Errno::EPERM => e
        raise DatabaseError, "Database path is not writable: #{db_path} (#{e.message})"
      end

      def self.disconnect!
        ActiveRecord::Base.remove_connection
      rescue StandardError
        nil
      end

      def self.run_migrations!
        context = ActiveRecord::MigrationContext.new(MIGRATIONS_PATH)
        context.migrate
      end

      def self.writable_path?(path)
        if File.exist?(path)
          File.writable?(path)
        else
          dir = File.dirname(path)
          File.directory?(dir) && File.writable?(dir)
        end
      end
      private_class_method :writable_path?
    end

    class DatabaseError < StandardError; end
  end
end
