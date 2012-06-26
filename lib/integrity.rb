require "yaml"
require "logger"
require "digest/sha1"
require "timeout"
require "ostruct"
require "pathname"

require "sinatra/base"
require "sinatra/authorization"
require "json"
require "haml"
require "sass"
require "dm-core"
require "dm-validations"
require "dm-types"
require "dm-timestamps"
require "dm-aggregates"
require "dm-migrations"
require "addressable/uri"
require "bcat/ansi"

require "app/app"

require "integrity/configuration"
require "integrity/bootstrapper"
require "integrity/project"
require "integrity/project_finder"
require "integrity/author"
require "integrity/commit"
require "integrity/build"
require "integrity/builder"
require "integrity/notifier"
require "integrity/notifier/base"
require "integrity/payload"
require "integrity/payload_builder"
require "integrity/checkout"
require "integrity/command_runner"
require "integrity/builder"


DataMapper.finalize

# TODO
Addressable::URI.class_eval { def gsub(*a); to_s.gsub(*a); end }

module Integrity
  autoload :ThreadedBuilder, "integrity/builders/threaded_builder"
  autoload :DelayedBuilder,  "integrity/builders/delayed_builder"
  autoload :ResqueBuilder,   "integrity/builders/resque_builder"

  Repository = Struct.new(:uri, :branch)

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield(config)
  end

  def self.bootstrap(&block)
    Bootstrapper.new(&block)
  end

  def self.logger
    config.logger
  end

  def self.app
    unless config.base_url
      warn "the base_url setting isn't set"
    end

    Integrity::App
  end
end
