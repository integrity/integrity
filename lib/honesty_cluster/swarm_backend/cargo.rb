module HonestyCluster
  module SwarmBackend
    module Cargo
      extend Interface
      include DockerUtil

      # a string which uniquely identifies this type of cargo
      interface_method :cargo_type

      # a unique identifier for this particular cargo
      interface_method :cargo_id

      # the type of the cargo group this cargo belongs to
      interface_method :cargo_group_type

      # the id of the cargo group this cargo belongs to
      interface_method :cargo_group_id

      # a string of the container name
      interface_method :container_name

      # a list of link strings or nil
      interface_method :container_links

      # a string of the image name
      interface_method :image_name

      # a list of command args or nil
      interface_method :docker_command

      # a list of ports to expose or nil
      interface_method :exposed_ports

      # a hash of var => value or nil
      interface_method :container_env

      # a hash of var => value or nil, which is added to default labels
      interface_method :container_labels

      # number of cores the cargo wants
      interface_method :cpu_cores

      # amount of memory the cargo wants in bytes
      interface_method :memory

      # return a bool for whether the container is healthy
      #interface_method :"container_healthy?"

      # return a bool for whether the stuff going on inside the container is healthy
      #interface_method :"cargo_healthy?"

      # hooks
      interface_method :after_run_container



      # Some Sensible Defaults
      def after_run_container ; nil ; end

      def run_container(overrides={})
        _container = create_container(container_json.deep_merge(overrides || {}))
        if HonestyCluster.dry_run?
          puts "not starting because dry_run is on"
          return false
        else
          _container.start!
          after_run_container
        end
      end

      def destroy_container(kontainer=container)
        puts "removing (with force) container #{kontainer.name}"
        kontainer.force_remove
      end

      def restart_container
        kontainer = container
        last_port_mapping = kontainer.port_mapping.to_a
        last_node = kontainer.node
        destroy_container(kontainer)
        run_container(
          exposed_ports: last_port_mapping,
          env: node_constraint(last_node),
        )
      end

      def container
        containers_filtered(
          'cargo-type' => cargo_type,
          'cargo-id'   => cargo_id,
        ).first
      end

      def container_json
        docker_api_container_json(
          name:          container_name,
          links:         container_links,
          image:         image_name,
          cmd:           docker_command,
          exposed_ports: exposed_ports,
          env:           container_env,
          labels:        all_labels,
          cpu_shares:    cpu_cores,
          memory:        memory,
        )
      end

      private def all_labels
        default_labels.merge(container_labels || {})
      end

      private def default_labels
        {
          'honesty' => '',
          'cargo-type' => cargo_type,
          'cargo-id'   => cargo_id,
        }.merge(
            if cargo_group_id && cargo_group_type
              {
                'cargo-group-type' => cargo_group_type,
                'cargo-group-id'   => cargo_group_id,
              }
            else
              {}
            end
          )
      end
    end
  end
end
