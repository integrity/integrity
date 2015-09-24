module HonestyCluster
  module SwarmBackend
    extend self

    def swarm_master
      ENV['SWARM_MASTER']
    end

    def conn
      @__swarm_conn ||= Docker::Connection.new("tcp://#{swarm_master}", {})
    end

    module Pancakes
      module InstanceMethods
        def swarm_bring_up
          byebug
          Docker::Container.all({}, SwarmBackend.conn)
        end
      end
    end
  end
end
