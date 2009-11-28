require "addressable/uri"
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
require "integrity/buildable_project"
require "integrity/author"
require "integrity/commit"
require "integrity/build"
require "integrity/builder"
require "integrity/notifier"
require "integrity/notifier/base"
require "integrity/helpers"
require "integrity/app"
require "integrity/scm"
require "integrity/scm/abstract"
require "integrity/builder"
require "integrity/builder/threaded"

module Integrity
  def self.configure(&block)
    @config ||= Configurator.new(&block)
    @config.tap { |c| block.call(c) if block }
  end

  class << self
    alias_method :config, :configure
  end

  def self.log(message, &block)
    config.logger.info(message, &block)
  end

  def self.app
    Rack::Builder.new {
      config = Integrity.config

      map "/push/#{config.push.last}" do
        use config.push.first do ! Integrity.config.build_all? end
        run Bobette.new(Integrity::BuildableProject)
      end

      map "/" do run Integrity::App end
    }
  end
end
