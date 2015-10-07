module HonestyCluster
  module SwarmBackend
    module Service
      include Cargo

      def timberland_command
        @__tmb_cmd ||= Timberland::Cmd.new(
          boot_type:    'pancakes',
          service_type: subtype,
          sha:          sha,
          repo:         repo,
          branch:       branch,
          debug:        Pancakes.timberland_debug?,
          setup_db:     true,
        )
      end

      def timberlandified?
        !(mysql? || postgres? || mailcatcher?)
      end

      # Cargo
      def cargo_group_type
        'pancakes-stack'
      end

      # Cargo
      def cargo_group_id
        stack_id
      end

      # Cargo
      def cargo_type
        'pancakes-service'
      end

      # Cargo
      def cargo_id
        id
      end

      # Cargo
      def container_name
        name
      end

      # Cargo
      def container_links
        nil
      end

      # Cargo
      def image_name
        image
      end

      # Cargo
      def docker_command
        if timberlandified?
          timberland_command.to_docker_api_cmd
        else
          nil
        end
      end

      # Cargo
      def exposed_ports
        ports
      end

      # Cargo
      def container_env
        _env = {
          'PANCAKES_ID'      => stack_id,
          'STACK_ID'         => stack_id,
          'SERVICE_ID'       => id,
          'PANCAKES_SHA'     => stack.short_sha,
          'HONESTY_BASE_URL' => SwarmBackend.base_url,
        }

        if timberlandified?
          _env.merge('TIMBERLAND_CMD' => timberland_command.run_cmd)
        else
          _env
        end
      end

      # Cargo
      def container_labels
        nil
      end

      # Cargo
      def cpu_shares
        1
      end

      # Cargo
      def memory
        0.5 #gb?
      end
    end
  end
end
