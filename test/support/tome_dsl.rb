require "fileutils"
require "tmpdir"
require "yaml"

module TomeDsl
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test")
    @db_path = File.join(@tmp_dir, "test.db")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    File.write(File.join(@config_dir, "config.yml"), YAML.dump("db_path" => @db_path))
    @tome_driver = build_driver
    super
  end

  def teardown
    super
    @tome_driver&.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def tome
    @tome_driver
  end

  private

  def build_driver
    driver_class = ENV.fetch("TOME_DRIVER", "service") == "cli" ? CliDriver : ServiceDriver
    driver_class.new(db_path: @db_path, config_dir: @config_dir)
  end
end
