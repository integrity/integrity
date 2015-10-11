######
#     #    ##    #    #   ####     ##    #    #  ######   ####
#     #   #  #   ##   #  #    #   #  #   #   #   #       #
######   #    #  # #  #  #       #    #  ####    #####    ####
#        ######  #  # #  #       ######  #  #    #            #
#        #    #  #   ##  #    #  #    #  #   #   #       #    #
#        #    #  #    #   ####   #    #  #    #  ######   ####
#
#
# author Alex Bird <bird@grandrounds.com>
# date   2015-02-18
#
# Environment vars
# ================
#
# required:
# - FLEETCTL_ENDPOINT (eg. 'http://1.2.3.4:5678')
# optional:
# - PANCAKES_DRY_RUN   (eg. true)
# - PANCAKES_LOG_LEVEL (eg. debug, 2)
# - TIMBERLAND_BRANCH    (eg. pancakes-develop)
# - TIMBERLAND_DEBUG     (eg. true)

module Pancakes
  extend self

  NAMESPACE = 'pancakes'
  SHA_REGEX = /[0-9a-f]{40}/i

  @@config =
    Hashie::Mash.new(
      freezer: Hashie::Mash.new(
        namespace: nil,
      ),
      templating: Hashie::Mash.new(
        timberland_branch: nil,
      ),
    )

  def log_level
    if ll = ENV['PANCAKES_LOG_LEVEL']
      ll =~ /\A\d+\z/ ? ll.to_i : ll.to_sym
    else
     :debug
    end
  end

  def cluster
    @cluster ||= Pancakes::Fleet::Cluster.new(dry_run: ENV['PANCAKES_DRY_RUN'] || false)
  end

  def docker
    @docker ||= Pancakes::Docker.new
  end

  def logger
    return @__lgr if @__lgr
    #Logging.logger[self].appenders = log_appender
    Logging.logger[self].level = Pancakes.log_level
    @__lgr = Logging.logger[self]
  end

  def config
    @@config
  end

  def configure
    yield @@config

    # validate pancakes config
    [
      %w[freezer namespace],
      %w[templating timberland_branch],
    ].each{|keys| !keys.reduce(@@config){|memo,key| memo && memo[key] }.nil? || raise("Pancakes.config.#{keys.join('.')} is required") }


    Octokit.configure do |c|
      c.access_token = ENV['GITHUB_READ_TOKEN']
      c.auto_paginate = true
    end

    Aws.config.update({
      region: 'us-east-1',
    })

    Pancakes::Fleet::Templating.configure do |c|
      c.timberland_branch = @@config.templating.timberland_branch
      Pancakes.logger.info "TIMBERLAND_BRANCH=#{@@config.templating.timberland_branch}"
    end
  end


  #     #
  #     #  ######  #       #####   ######  #####    ####
  #     #  #       #       #    #  #       #    #  #
  #######  #####   #       #    #  #####   #    #   ####
  #     #  #       #       #####   #       #####        #
  #     #  #       #       #       #       #   #   #    #
  #     #  ######  ######  #       ######  #    #   ####
  #####################################################

  def repo_name(codebase)
    return nil unless codebase
    codebase.to_sym == :jarvis ? 'consultingmd/consultingmd' : "consultingmd/#{codebase}"
  end

  def codebase_name(repo)
    return nil unless repo
    repo = repo.split('/').last if repo['/']
    repo = repo.downcase
    repo == 'consultingmd' ? 'jarvis' : repo
  end

  def heads_str(branch_name)
    "heads/#{branch_name}"
  end

  # this will not kill blocks which do their own sleeping
  def loop_with_timeout(timeout:, sleep_for: nil)
    start = Time.now
    while (elapsed = (Time.now - start)) < timeout do
      yield(timeout - elapsed)
      sleep(sleep_for) if sleep_for
    end
    raise Pancakes::TimeoutError, "timeout of #{timeout}s reached after #{Time.now - start}s"
  end

  # Polls the &block or :obj.:method(:args) for any element of :values. If :values is not an Array
  # it will be wrapped in one.
  #
  # @param values [Array] if an element is an instance of Class, then the class of the return value of :method will
  #   be compared with :values. Otherwise, == comparison is done.
  # @return the value that was found, or nil of there was a timeout, or raise a Pancakes::TimeoutError if :raise_on_timeout is true
  def block_until_values(values:, timeout:, obj: nil, method: nil, args: [], raise_on_timeout: false)
    raise "must pass a method or block" if !method && !block_given?
    raise_on_timeout = false if raise_on_timeout.nil?

    poll_interval = 1
    start         = Time.now
    values        = Array(values)
    args          = Array(args)
    callee_str    = method ? "#<#{obj.class.name}##{method}(#{args.map(&:to_s).join(', ')})" : "<block>"
    values_str    = values.inspect

    loop_with_timeout(timeout: timeout, sleep_for: poll_interval) do |remaining|
      logger.debug format("polling %s for %s (timeout in %.0fs)", callee_str, values_str, remaining)

      curr = if block_given?
        yield
      else
        obj.send(method, *args)
      end

      values.each do |value|
        if value.class == Class && curr.is_a?(value)
          logger.debug "#{callee_str} value.class #{curr.class} reached"
          return curr
        elsif value == curr
          logger.debug "#{callee_str} value #{curr.inspect} reached"
          return curr
        end
      end
    end
  rescue Pancakes::TimeoutError => e
    msg = "#{e.message} calling #{callee_str} for values #{values_str}"
    logger.warn(msg)
    raise Pancakes::TimeoutError, msg if raise_on_timeout
    return nil
  end

  def branch_info_from_push_event(repo_name, branch_name)
    { Pancakes.codebase_name(repo_name.downcase) => branch_name }
  end

  def gh_read_token
    ENV['GITHUB_READ_TOKEN'] || raise('GITHUB_READ_TOKEN not set')
  end

  def timberland_debug?
    !!ENV['TIMBERLAND_DEBUG']
  end

  def db
    @db
  end

  def db=(foo)
    @db = foo
  end

  def db_disconnect
    Pancakes.db && Pancakes.db.disconnect
  end

  def db_connect
    Pancakes.db = Sequel.connect(ENV['DATABASE_URL'], logger: Logging.logger['pancakes-db'])
  end
end

module ClassLogger
  def logger_name
    self
  end

  def logger
    return @__lgr if @__lgr
    #Logging.logger[lg_name].appenders = Pancakes.log_appender
    #Logging.logger[lg_name].level = Pancakes.log_level
    @__lgr = Logging.logger[logger_name]
  end

  # Use this method when the stack's name changes to get a new logger with the new name.
  def refresh_logger
    @__lgr = nil
  end
end

require 'sequel'
require 'sequel/plugins/serialization'
#Logging.logger['pancakes-db'].level = Pancakes.log_level
Logging.logger['pancakes-db'].level = 2
Sequel.default_timezone = :utc
#Sequel.database_timezone = :utc
#Sequel.application_timezone = :local
#Sequel.typecast_timezone = :local

Sequel::Plugins::Serialization.register_format(:symbolize,
                                                lambda{|v| v.to_s},
                                                lambda{|v| v.to_sym})
Pancakes.db_connect

require 'json'
require 'digest/sha1'
require 'net/ssh'
require 'aws-sdk'

require 'stathat_wrapper'

require 'honesty_cluster'

require 'pancakes/errors'

require 'pancakes/fleet'
require 'pancakes/fleet/machine'
require 'pancakes/fleet/etcd'
require 'pancakes/fleet/cluster'

require 'pancakes/fleet/templating/helpers'
require 'pancakes/fleet/templating/partials'
require 'pancakes/fleet/templating/honesty_builds'
require 'pancakes/fleet/templating'

require 'pancakes/commit'
require 'pancakes/docker'
require 'pancakes/freezer'
require 'pancakes/services'
require 'pancakes/stack'
require 'pancakes/unit'

require 'pancakes/background'
