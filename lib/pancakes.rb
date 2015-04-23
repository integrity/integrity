######
#     #    ##    #    #   ####     ##    #    #  ######   ####
#     #   #  #   ##   #  #    #   #  #   #   #   #       #
######   #    #  # #  #  #       #    #  ####    #####    ####
#        ######  #  # #  #       ######  #  #    #            #
#        #    #  #   ##  #    #  #    #  #   #   #       #    #
#        #    #  #    #   ####   #    #  #    #  ######   ####
###############################################################
#
# @author Alex Bird <bird@grandrounds.com>
# @date   2015-02-18
#
# Environment vars
# ================
#
# required:
# - FLEETCTL_ENDPOINT (eg. 'http://1.2.3.4:5678')
# optional:
# - PANCAKES_DRY_RUN (eg. true)
# - PANCAKES_LOG_LEVEL (eg. debug, 2)

module Pancakes

  NAMESPACE = 'pancakes'
  CODEBASES = %i[jarvis frick tim]
  SHA_REGEX = /[0-9a-f]{40}/i

  #def self.log_appender
    #@appender ||= Logging.appenders.stdout(layout: ::Logging::Layouts::Pattern.new(pattern: "%.1l %d %h %c: %m\n"))
  #end

  def self.log_level
    if ll = ENV['PANCAKES_LOG_LEVEL']
      ll =~ /\A\d+\z/ ? ll.to_i : ll.to_sym
    else
     :debug
    end
  end

  def self.cluster
    @cluster ||= Pancakes::Fleet::Cluster.new(dry_run: ENV['PANCAKES_DRY_RUN'] || false)
  end

  def self.docker
    @docker ||= Pancakes::Docker.new
  end

  def self.logger
    return @__lgr if @__lgr

    #Logging.logger[self].appenders = log_appender
    Logging.logger[self].level = Pancakes.log_level
    @__lgr = Logging.logger[self]
  end

  def self.setup

    Octokit.configure do |c|
      c.access_token = ENV['GITHUB_READ_TOKEN']
      c.auto_paginate = true
    end

    logger()
    cluster()
    docker()
  end


  #     #
  #     #  ######  #       #####   ######  #####    ####
  #     #  #       #       #    #  #       #    #  #
  #######  #####   #       #    #  #####   #    #   ####
  #     #  #       #       #####   #       #####        #
  #     #  #       #       #       #       #   #   #    #
  #     #  ######  ######  #       ######  #    #   ####
  #####################################################

  def self.repo_name(codebase)
    return nil unless codebase
    codebase.to_sym == :jarvis ? 'consultingmd/consultingmd' : "consultingmd/#{codebase}"
  end

  def self.codebase_name(repo)
    return nil unless repo
    repo = repo.split('/').last if repo['/']
    repo = repo.downcase
    repo == 'consultingmd' ? 'jarvis' : repo
  end

  def self.validate_codebase(codebase)
    CODEBASES.include?(codebase.to_sym)
  end

  def self.heads_str(branch_name)
    "heads/#{branch_name}"
  end

  # @param values [Array] if an instance of Class, class of the result of calling :method will
  #   be compared with the value. Otherwise, == comparison is done.
  # @return the value that was found, or nil of there was a timeout.
  def self.block_until_values(values:, timeout:, obj: nil, method: nil, args: [], raise_on_timeout: false)
    raise "must pass a method or block" if !method && !block_given?
    raise_on_timeout = false if raise_on_timeout.nil?

    poll_interval = 1
    start         = Time.now
    values        = Array(values)
    args          = Array(args)
    callee_str    = method ? "#<#{obj.class.name}##{method}(#{args.map(&:to_s).join(', ')})" : "<block>"
    values_str    = values.inspect

    while (remaining = (Time.now - start)) <= timeout do
      logger.debug format("polling %s for %s (timeout in %.0fs)", callee_str, values_str, timeout - remaining)

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
          logger.debug "#{callee_str} value #{curr} reached"
          return curr
        end
      end

      sleep(poll_interval)
    end

    msg = "timeout of #{timeout}s reached calling #{callee_str} for values #{values_str}"
    logger.warn(msg)
    raise Pancakes::TimeoutError, msg if raise_on_timeout
    return nil
  end

  def self.branch_info_from_push_event(push_event_hash)
    repo_name = push_event_hash['repository']['name'].downcase
    branch_name = push_event_hash['ref'].sub('refs/heads/', '')
    { Pancakes.codebase_name(repo_name) => branch_name }
  end
end

require 'sequel'
require 'sequel/plugins/serialization'
Logging.logger['pancakes-db'].level = Pancakes.log_level
#Logging.logger['pancakes-db'].level = 2
Sequel.default_timezone = :utc
#Sequel.database_timezone = :utc
#Sequel.application_timezone = :local
#Sequel.typecast_timezone = :local

Sequel::Plugins::Serialization.register_format(:symbolize,
                                                lambda{|v| v.to_s},
                                                lambda{|v| v.to_sym})
Sequel.connect(ENV['DATABASE_URL'], logger: Logging.logger['pancakes-db'])

require 'json'
require 'digest/sha1'
require 'net/ssh'

require 'stathat_wrapper'

require 'pancakes/errors'

require 'pancakes/fleet'
require 'pancakes/fleet/cluster'
require 'pancakes/fleet/templating'

require 'pancakes/commit'
require 'pancakes/docker'
require 'pancakes/freezer'
require 'pancakes/services'
require 'pancakes/stack'
require 'pancakes/unit'

require 'pancakes/background'

Pancakes.setup
