module HonestyCluster
  module SwarmBackend
    class BuildDatastore
      include SwarmBackend::Cargo

      attr_reader :build

      def initialize(build)
        @build = build
      end

      # Cargo
      def cargo_name
        build.cargo_name
      end

      # Cargo
      def cargo_identifier
        build.cargo_identifier
      end

      # Cargo
      def docker_command
        nil
      end

      # Cargo
      def container_name
        [build.service_name, build.datastore].join('_')
      end

      # Cargo
      def image_name
        "grnds/#{build.datastore}:latest"
      end

      # Cargo
      def container_env
        nil
      end

      # Cargo
      def container_labels
        {
          'build-type' => build.datastore,
        }
      end

      # Cargo
      def container_links
        nil
      end

      # Cargo
      def exposed_ports
        if build.datastore == 'mysql'
          [3306]
        elsif build.datastore == 'postgres'
          [5432]
        else
          nil
        end
      end
    end
  end
end

