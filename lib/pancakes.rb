module Pancakes
  DOCKER_API_PORT = 2375

  @logger = nil
  @fleet_client = Fleet.new
  @etcd_client  = Etcd.client(host: ENV['ETCD_HOSTNAME'])
  @cache = {}

  def self.cache
    @cache
  end

  def self.logger
    @logger
  end

  def self.logger=(l)
    @logger = l
  end

  def self.fleet
    @fleet_client
  end

  def self.etcd
    @etcd_client
  end

  module Clients
    def fleet
      Pancakes.fleet
    end

    def etcd
      Pancakes.etcd
    end
  end
end

require 'pancakes/stack'
require 'pancakes/fleet_api_template_builder'
require 'pancakes/freezer'
require 'pancakes/stack_maker'
require 'pancakes/commit'
