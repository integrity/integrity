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

      # Hooks
      # passes the current container and cargo_json as params, and uses the return value as the cargo_json.
      interface_method :before_restart_container
      interface_method :after_run_container



      # Some Sensible Defaults
      def before_restart_container(kontainer, cargo_json) ; nil ; end
      def after_run_container ; nil ; end

      def run_container
        internal_run_container(docker_json)
      end

      def destroy_container(kontainer=container)
        return unless kontainer
        puts "removing (with force) container #{kontainer.name}"
        kontainer.force_remove
      end

      def restart_container
        kontainer = container
        old_cargo_json = cargo_json
        new_cargo_json = before_restart_container(kontainer, old_cargo_json)
        destroy_container(kontainer)
        internal_run_container(docker_api_container_json(new_cargo_json || cargo_json))
      end

      def container
        containers_filtered(
          'cargo-type' => cargo_type,
          'cargo-id'   => cargo_id,
        ).first
      end

      def cargo_json
        {
          name:          container_name,
          links:         container_links,
          image:         image_name,
          cmd:           docker_command,
          exposed_ports: exposed_ports,
          env:           container_env,
          labels:        all_labels,
          cpu_shares:    cpu_cores,
          memory:        memory,
        }
      end

      def docker_json(_cargo_json=cargo_json)
        docker_api_container_json(_cargo_json)
      end

      private def internal_run_container(_docker_json)
        _container = create_container(_docker_json)
        if HonestyCluster.dry_run?
          puts "not starting because dry_run is on"
          return false
        else
          _container.start!
          after_run_container
        end
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
