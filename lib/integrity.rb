if Object.const_defined?(:Encoding) && Encoding.respond_to?(:default_internal=)
  # ruby 1.9
  # Internal encoding is what is used on ruby strings.
  Encoding.default_internal = Encoding::UTF_8
  # External encoding is what is used on pipes used to communicate with
  # launched command runners and is the default encoding used when opening
  # e.g. the log file.
  Encoding.default_external = Encoding::UTF_8
end

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
require "chronic_duration"
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
  autoload :ExplicitBuilder, "integrity/builders/explicit_builder"

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

  def self.datetime_to_utc_time(datetime)
    if datetime.offset != 0
      # This converts to utc
      # borrowed from activesupport DateTime#to_utc
      datetime = datetime.new_offset(0)
    end
    
    # This is what DateTime#to_time does some of the time.
    # Our offset is always 0 and therefore we always produce a Time
    ::Time.utc(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)
  end
  
  # Replace or delete invalid UTF-8 characters from text, which is assumed
  # to be in UTF-8.
  #
  # The text is expected to come from external to Integrity sources such as
  # commit messages or build output.
  #
  # On ruby 1.9, invalid UTF-8 characters are replaced with question marks.
  # On ruby 1.8, if iconv extension is present, invalid UTF-8 characters
  # are removed.
  # On ruby 1.8, if iconv extension is not present, the string is unmodified.
  def self.clean_utf8(text)
    # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
    # http://stackoverflow.com/questions/9126782/how-to-change-deprecated-iconv-to-stringencode-for-invalid-utf8-correction
    if text.respond_to?(:encoding)
      # ruby 1.9
      text = text.force_encoding('utf-8').encode('utf-16', :invalid => :replace, :replace => '?').encode('UTF-8')
    else
      # ruby 1.8
      # As no encoding checks are done, any string will be accepted.
      # But delete invalid utf-8 characters anyway for consistency with 1.9.
      iconv = clean_utf8_iconv
      if iconv
        output = iconv.iconv(text)
      end
    end
    text
  end
  
  def self.clean_utf8_iconv
    unless @iconv_loaded
      begin
        require 'iconv'
      rescue LoadError
        @iconv = nil
      else
        @iconv = Iconv.new('utf-8//translit//ignore', 'utf-8')
      end
      @iconv_loaded = true
    end
    @iconv
  end
end
