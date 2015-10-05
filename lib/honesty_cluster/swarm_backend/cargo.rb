module Interface
  def interface_method(name)
    define_method(name) { |*args|
      raise "interface method #{name} not implemented"
    }
  end
end

module HonestyCluster
  module SwarmBackend
    module Cargo
      extend Interface
      include DockerUtil

      # a string which uniquely identifies this type of cargo
      interface_method :cargo_name

      # a unique identifier for this particular cargo
      interface_method :cargo_identifier

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


      def run_container
        create_container.start
      end

      def containers
        containers_filtered(cargo_name, cargo_identifier)
      end

      def container_json
        docker_api_container_json(
          name:          container_name,
          links:         container_links,
          image:         image_name,
          cmd:           docker_command,
          exposed_ports: exposed_ports,
          env:           container_env,
          labels:        default_container_labels.merge(container_labels || {}),
        )
      end

      private def create_container
        create_container(container_json)
      end

      private def default_container_labels
        {
          'honesty' => '',
          cargo_name => cargo_identifier,
        }
      end
    end
  end
end
