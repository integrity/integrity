module HonestyCluster
  module SwarmBackend
    class BuildDatastore
      include SwarmBackend::Cargo

      attr_reader :build

      def initialize(build)
        if !build.datastore
          raise "cannot create BuildDatastore for build id=#{build.id} datastore=nil"
        end
        @build = build
      end

      # Cargo
      def cargo_group_type
        build.cargo_group_type
      end

      # Cargo
      def cargo_group_id
        build.cargo_group_id
      end

      # Cargo
      def cargo_type
        build.datastore
      end

      # Cargo
      def cargo_id
        build.cargo_id
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
        builds_constraint
      end

      # Cargo
      def container_labels
        nil
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

      # Cargo
      # - first we tried 1
      # - each c4.8xlarge has 37 cores in the schedulers perspective because of the swarm overcommit ratio default value
      # - i noticed the prepare_parallel_specs loops were going slower than id ever noticed
      # - during a build with 35 spec procs, mysql cpu was at 150%, and systemd-journal was at 99%
      # - now im wondering if we could get better performance out of mysql with 2 cores
      def cpu_shares
        if build.uses_parallel_spec?
          7
        else
          1
        end
      end
    end
  end
end
