if Object.const_defined?(:Encoding) && Encoding.respond_to?(:default_internal=)
  # ruby 1.9
  # Internal encoding is what is used on ruby strings.
  Encoding.default_internal = Encoding::UTF_8
  # External encoding is what is used on pipes used to communicate with
  # launched command runners and is the default encoding used when opening
  # e.g. the log file.
  Encoding.default_external = Encoding::UTF_8
end

require 'yaml'
require 'logger'
require 'logging'
require 'digest/sha1'
require 'timeout'
require 'ostruct'
require 'pathname'
require 'json'
require 'haml'
require 'sass'
require 'slim'
require 'stathat'
require 'ap'
require 'delayed_job'
require 'active_record'
require 'tracker_api'
require 'sendgrid-ruby'

require 'sinatra/base'
require 'sinatra/authorization'

require 'active_support'
require 'active_support/core_ext'
require 'active_support/hash_with_indifferent_access'

require 'dm-core'
require 'dm-validations'
require 'dm-types'
require 'dm-timestamps'
require 'dm-aggregates'
require 'dm-migrations'

require 'coreext/data_mapper/resource'

require 'addressable/uri'
require 'chronic_duration'
require 'bcat/ansi'
require 'rconfig'
require 'i18n'
require 'rest_client'
require 'fleet'
require 'etcd'
require 'octokit'
require 'stathat_wrapper'
require 'tracker_wrapper'
require 'sendgrid_wrapper'

require 'opts/rconfig'

require 'runnable'
require 'docker'

require 'app/app'


require 'integrity/event'
require 'integrity/web_utils'
require 'integrity/configuration'
require 'integrity/bootstrapper'
require 'integrity/project'
require 'integrity/branch'
require 'integrity/project_finder'
require 'integrity/author'
require 'integrity/commit'
require 'integrity/build'
require 'integrity/builder'
require 'integrity/load_utilization'
require 'integrity/notifier'
require 'integrity/notifier/base'
require 'integrity/payload'
require 'integrity/payload_builder'
require 'integrity/checkout'
require 'integrity/command_runner'
require 'integrity/builder'
require 'integrity/instance_manager'
require 'integrity/stats_job'

require 'pancakes'
require 'tracker'

DataMapper::Logger.new(STDOUT, :info)
DataMapper.finalize

Addressable::URI.class_eval do
  def gsub(*args)
    to_s.gsub(*args)
  end
end

module Integrity
  CannotFindEncoding = Class.new(StandardError)

  autoload :ThreadedBuilder, 'integrity/builders/threaded_builder'
  autoload :DelayedBuilder,  'integrity/builders/delayed_builder'
  autoload :ResqueBuilder,   'integrity/builders/resque_builder'
  autoload :ExplicitBuilder, 'integrity/builders/explicit_builder'

  class Repository
    attr_reader :uri, :branch, :name
    def initialize(uri, branch, owner=nil, name=nil)
      @uri, @branch, @owner, @name = uri, branch, owner, name
      parse_uri
    end
    def parse_uri
      @uri &&= ::URI.parse(@uri)
      owner, name = @uri.path.split('/')[1..-1] rescue []
      @owner ||= owner
      @name  ||= name
    end
    def owner
      @owner.presence || Integrity.config.github_account
    end
  end

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
    warn "the base_url setting isn't set" unless config.base_url

    Integrity::App
  end

  def self.builder
    config.builder
  end

  def self.datetime_to_utc_time(datetime)
    # This converts to utc (borrowed from activesupport DateTime#to_utc)
    datetime = datetime.new_offset(0) unless datetime.offset.zero?

    # This is what DateTime#to_time does some of the time.
    # Our offset is always 0 and therefore we always produce a Time
    ::Time.utc(datetime.year, datetime.month, datetime.day, datetime.hour, datetime.min, datetime.sec)
  end

  def self.to_timestamp(time)
    time.is_a?(::Time) ? time.to_i : datetime_to_utc_time(time).to_i
  end

  def self.delta(time1, time2)
    to_timestamp(time1) - to_timestamp(time2)
  end

  def self.human_duration(delta)
    delta > 0 ? ChronicDuration.output(delta, format: :micro) : '0s'
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
      text = text.force_encoding('utf-8').encode(intermediate_encoding, :invalid => :replace, :replace => '?').encode('utf-8')
    else
      # ruby 1.8
      # As no encoding checks are done, any string will be accepted.
      # But delete invalid utf-8 characters anyway for consistency with 1.9.
      iconv, iconv_fallback = clean_utf8_iconv
      if iconv
        begin
          output = iconv.iconv(text)
        rescue Iconv::IllegalSequence
          output = iconv_fallback.iconv(text)
        end
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
        # On some systems (Linux appears to be vulnerable, FreeBSD not)
        # iconv chokes on invalid utf-8 with //translit//ignore.
        @iconv_fallback = Iconv.new('utf-8//ignore', 'utf-8')
      end
      @iconv_loaded = true
    end
    [@iconv, @iconv_fallback]
  end

  # Apparently utf-16 is not available everywhere, in particular not on travis.
  # Try to find a usable encoding.
  def self.intermediate_encoding
    map = {}
    Encoding.list.each do |encoding|
      map[encoding.name.downcase] = true
    end
    %w(utf-16 utf-16be utf-16le utf-7 utf-32 utf-32le utf-32be).each do |candidate|
      if map[candidate]
        return candidate
      end
    end
    raise CannotFindEncoding, 'Cannot find an intermediate encoding for conversion to UTF-8'
  end

  def self.generate_sha1(key = '')
    key = key.presence || timestamp
    Digest::SHA1.hexdigest(key.to_s)
  end

  def self.timestamp
    Time.now.to_i.to_s
  end

  def self.start_service(service)
    unit_fname = "#{service}.service"
    hsh = Pancakes::Fleet::Templating.send(service.to_sym)
    self.cluster.start_template(unit_fname, hsh)
  end

  def self.start_services
    ['logspout', 'metrics'].each {|s| self.start_service(s) }
  end

  def self.max_running_builds
    config.max_running_builds
  end

  def self.root
    File.join(File.dirname(__FILE__), '..')
  end

  def self.base_url
    config.base_url
  end

  def self.logs_url
    config.logs_url
  end

  def self.environment
    config.environment
  end

  def self.environment?(name)
    environment == name
  end

  def self.production?
    environment? :production
  end

  def self.development?
    environment? :development
  end

  def self.private_key
    @private_key ||= %x{cat /var/tmp/environments/etc/keys/id-rsa-honesty}
  end

  def self.sys_logger(name = :integrity, level = :debug)
    return logger unless production?
    name = (name.presence || :integrity).to_s
    @sys_loggers ||= {}
    unless @sys_loggers[name].present?
      syslog = Logging.logger[name]
      syslog.add_appenders Logging.appenders.syslog(name)
      syslog.level = level
      @sys_loggers[name] = syslog
    end
    @sys_loggers[name].level = level
    @sys_loggers[name]
  end

  def self.instance_manager
    InstanceManager.new
  end

  def self.max_run_time
    config.max_run_time
  end

  def self.queue_builds
    Integrity::Event.trigger('build:queue:all')
  end

  def self.cluster
    Pancakes.cluster
  end
end

require 'opts/delayed_job'
