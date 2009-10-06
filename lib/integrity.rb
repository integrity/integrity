$:.unshift File.expand_path(File.dirname(__FILE__))

require "bob"
require "bobette"
require "bobette/github"
require "sinatra/base"
require "sinatra/url_for"
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
require "integrity/author"
require "integrity/commit"
require "integrity/build"
require "integrity/builder"
require "integrity/notifier"
require "integrity/helpers"
require "integrity/app"

module Integrity
  def self.configure(&block)
    @config ||= Configurator.new(&block)
  end

  class << self
    alias_method :config, :configure
  end

  def self.log(message, &block)
    config.logger.info(message, &block)
  end
end
