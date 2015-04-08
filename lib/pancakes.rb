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

  def self.log_appender
    @appender ||= Logging.appenders.stdout(layout: ::Logging::Layouts::Pattern.new(pattern: "%.1l %d %h %c: %m\n"))
  end

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

    Logging.logger[self].appenders = log_appender
    Logging.logger[self].level = Pancakes.log_level
    @__lgr = Logging.logger[self]
  end

  def self.setup
    Mongoid.load!(File.join("config/mongoid.yml"))

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
    repo = repo.downcase.to_sym
    repo == :consultingmd ? :jarvis : repo
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
  def self.block_until_values(obj: nil, method: nil, args: [], values:, timeout:)
    #raise "can't call #{method}" unless obj.respond_to?(method)
    poll_interval = 1
    start = Time.now
    values = Array(values)
    args = Array(args)
    logger.debug "polling timeout=#{timeout}s"

    while (remaining = (Time.now - start)) <= timeout do
      timeout_in = format('%.0fs', timeout - remaining)

      if block_given?
        logger.debug "polling block for #{values.inspect} (timeout in #{timeout_in})"
        curr = yield
      else
        logger.debug "polling #<#{obj.class.name}##{method}(#{args.map(&:to_s).join(', ')}) for #{values.inspect} (timeout in #{timeout_in})"
        curr = obj.send(method, *args)
      end

      values.each do |value|
        if value.class == Class && curr.is_a?(value)
          logger.debug "#{method} value #{curr.class} reached"
          return curr
        elsif value == curr
          logger.debug "#{method} value #{curr} reached"
          return curr
        end
      end

      sleep(poll_interval)
    end

    logger.warn "timeout of #{timeout}s reached calling #{method} for values #{values.inspect}"
    return nil
  end

  def self.branch_info_from_push_event(push_event_hash)
    repo_name = push_event_hash['repository']['name'].downcase
    branch_name = push_event_hash['ref'].sub('refs/heads/', '')
    { Pancakes.codebase_name(repo_name) => branch_name }
  end
end

module Pancakes
  class ClusterError < StandardError
    attr_accessor :original

    def self.new_with_original(orig_err)
      me = new
      me.original = orig_err
      me
    end

    def message
      @original ? @original.message : super
    end
  end
end

require 'digest/sha1'

require 'stathat_wrapper'

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
