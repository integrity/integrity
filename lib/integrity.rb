require "addressable/uri"
require "sinatra/base"
require "sinatra/url_for"
require "sinatra/authorization"
require "json"
require "haml"
require "sass"
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
require "forwardable"

require "integrity/core_ext/object"

require "integrity/configurator"
require "integrity/project"
require "integrity/buildable_project"
require "integrity/author"
require "integrity/commit"
require "integrity/build"
require "integrity/builder"
require "integrity/notifier"
require "integrity/notifier/base"
require "integrity/helpers"
require "integrity/app"
require "integrity/repository"
require "integrity/builder"
require "integrity/builder/threaded"

module Integrity
  def self.configure(&block)
    @config ||= Configurator.new(&block)
    @config.tap { |c| block.call(c) if block }
  end

  class << self
    attr_accessor :builder, :directory, :base_uri, :logger
    alias_method :config, :configure
  end

  def self.log(message, &block)
    logger.info(message, &block)
  end

  def self.app
    Integrity::App
  end
end
