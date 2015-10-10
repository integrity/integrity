module HonestyCluster
  module SwarmBackend

    # thing which represents a collection of Cargos.
    module CargoGroup
      extend Interface
      include DockerUtil

      # the type of the cargo group
      interface_method :cargo_group_type

      # the id of the cargo group
      interface_method :cargo_group_id

      # list of Cargos
      interface_method :cargo_list

      interface_method :before_run_containers
      interface_method :after_run_containers
      interface_method :after_destroy_containers

      def restart_containers
        destroy_containers
        run_containers
      end

      def run_containers
        begin
          before_run_containers
          cargo_list.each do |cargo|
            cargo.run_container
          end
          after_run_containers
        rescue Docker::Error::ServerError => e
          if e.message.include?('no resources available to schedule container')
            puts "failure: #{e.message}"
            puts "destroying this cargo group"
            destroy_containers
          else
            raise e
          end
        end
      end

      def destroy_containers
        containers.each do |container|
          puts "removing (with force) container #{container.name}"
          container.force_remove
        end
        after_destroy_containers
      end

      def containers
        containers_filtered(
          'cargo-group-type' => cargo_group_type,
          'cargo-group-id'   => cargo_group_id,
        )
      end
    end
  end
end
