__DIR__ = File.dirname(__FILE__)
$:.unshift "#{__DIR__}/integrity", *Dir["#{__DIR__}/../vendor/**/lib"].to_a

require "rubygems"
require "json"
require "dm-core"
require "dm-validations"
require "dm-types"
require "dm-timestamps"
require "dm-aggregates"

require "yaml"
require "logger"
require "digest/sha1"
require "timeout"
require "ostruct"
require "fileutils"

require "core_ext/object"
require "core_ext/string"

require "project"
require "author"
require "commit"
require "build"
require "project_builder"
require "scm"
require "scm/git"
require "notifier"

module Integrity
  def self.new(config_file = nil)
    self.config = config_file unless config_file.nil?
    DataMapper.logger = self.logger if config[:log_debug_info]
    DataMapper.setup(:default, config[:database_uri])
  end

  def self.root
    File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  def self.default_configuration
    @defaults ||= { :database_uri      => "sqlite3::memory:",
                    :export_directory  => root / "exports",
                    :log               => STDOUT,
                    :base_uri          => "http://localhost:8910",
                    :use_basic_auth    => false,
                    :build_all_commits => true,
                    :log_debug_info    => false }
  end

  def self.config
    @config ||= default_configuration
  end

  def self.config=(file)
    @config = default_configuration.merge(YAML.load_file(file))
  end

  def self.log(message, &block)
    logger.info(message, &block)
  end

  def self.logger
    @logger ||= Logger.new(config[:log], "daily").tap do |logger|
      logger.formatter = LogFormatter.new
    end
  end

  def self.version
    @version ||= begin
      file = YAML.load_file(Integrity.root / "VERSION.yml")
      "#{file['major']}.#{file['minor']}.#{file['patch']}"
    end
  end

  private

    class LogFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        time.strftime("[%H:%M:%S] ") + msg2str(msg) + "\n"
      end
    end
end
