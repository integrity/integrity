module HonestyCluster
  module SwarmBackend
    extend self

    def connection
      @__swarm_conn ||= Docker::Connection.new((ENV['DOCKER_HOST'] || raise('must set DOCKER_HOST')), {})
    end

    def base_url
      Integrity.base_url
    end

    def node_count
      if HonestyCluster.dry_run?
        1
      else
        Docker.info(SwarmBackend.connection)['DriverStatus'].detect{|e| e[0].match(/Nodes/) }.last.to_i
      end
    end

    #def get_unit_from_container(container_name)
      #unit_info = Pancakes::Unit.parse_unit_name(container_name)
      #Pancakes::Unit.where(stack_id: unit_info.stack_id, service_name: unit_info.service_name).first
    #end
  end
end
