require "addressable/uri"
require "sinatra/base"
require "sinatra/authorization"
require "json"
require "haml"
require "sass"
require "sass/plugin/rack"
require "dm-core"
require "dm-validations"
require "dm-types"
require "dm-timestamps"
require "dm-aggregates"
require "dm-migrations"

require "yaml"
require "logger"
require "digest/sha1"
require "timeout"
require "ostruct"
require "pathname"
require "forwardable"
require "bcat/ansi"

require "integrity/core_ext/object"

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
require "integrity/buildable_payload"
require "integrity/helpers"
require "integrity/app"
require "integrity/checkout"
require "integrity/command_runner"
require "integrity/builder"
require "integrity/builder/threaded"

# TODO
Addressable::URI.class_eval { def gsub(*a); to_s.gsub(*a); end }

module Integrity
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
    # TODO
    warn "the base_url setting isn't set" unless config.instance_variable_get(:@base_url)
    Integrity::App
  end
end
