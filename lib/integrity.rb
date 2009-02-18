$:.unshift File.expand_path(File.dirname(__FILE__))

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
require "pathname"

require "integrity/core_ext/object"

require "integrity/project"
require "integrity/author"
require "integrity/commit"
require "integrity/build"
require "integrity/project_builder"
require "integrity/scm"
require "integrity/scm/git"
require "integrity/notifier"

module Integrity
  def self.new(config_file = nil)
    self.config = config_file unless config_file.nil?
    DataMapper.setup(:default, config[:database_uri])
  end

  def self.root
    Pathname.new(File.dirname(__FILE__)).join("..").expand_path
  end

  def self.default_configuration
    @defaults ||= { :database_uri      => "sqlite3::memory:",
                    :export_directory  => root / "exports",
                    :log               => STDOUT,
                    :base_uri          => "http://localhost:8910",
                    :use_basic_auth    => false,
                    :build_all_commits => true,
                    :log_debug_info    => false }.dup
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
    YAML.load_file(Integrity.root.join("VERSION.yml")).values.join(".")
  end

  private

    class LogFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        time.strftime("[%H:%M:%S] ") + msg2str(msg) + "\n"
      end
    end
end
