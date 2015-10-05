module HonestyCluster
  module SwarmBackend
    module CargoGroup
      extend Interface
      include DockerUtil

      def run_containers
        create_container(datastore_container_json).start if datastore
        create_container(container_json).start
      end

      def destroy_containers
        containers.each do |container|
          puts "removing (with force) container #{container.name}"
          container.force_remove
        end
      end

      def containers
        containers_filtered(cargo_name, cargo_identifier)
      end
    end
  end
end
