module HonestyCluster
  module SwarmBackend
    module Build
      include SwarmBackend::Cargo

      #def swarm_run
        #create_container(datastore_container_json).start if datastore
        #create_container(container_json).start
      #end

      #def swarm_destroy
        #containers.each do |container|
          #puts "removing (with force) container #{container.name}"
          #container.force_remove
        #end
      #end

      def timberland_command
        @__tmb_cmd ||= Timberland::Cmd.new(
          boot_type:    'build',
          service_type: 'spec',
          sha:          self.sha,
          repo:         self.repo_full_name,
          branch:       self.branch_name,
        )
      end

      # Cargo
      def cargo_name
        'build-id'
      end

      # Cargo
      def cargo_identifier
        self.id
      end

      # Cargo
      def docker_command
        timberland_command.to_docker_api_cmd
      end

      # Cargo
      def container_name
        [self.service_name, 'app'].join('_')
      end

      # Cargo
      def image_name
        "grnds/#{self.project_name}_ci:latest"
      end

      # Cargo
      def container_env
        {
          'PROJECT' => self.project_name,
          'BRANCH' => self.branch_name,
          'SHA' => self.sha,
          'BUILD_ID' => self.id,
          'GITHUB_READ_TOKEN' => ':self',
          'AWS_ACCESS_KEY_ID' => ':self',
          'AWS_SECRET_ACCESS_KEY' => ':self',
          'AWS_SECRET_KEY' => ':self',
          'SAUCE_USERNAME' => ':self',
          'SAUCE_ACCESS_KEY' => ':self',
          'CALLBACK_URL' => "https://#{ENV['CALLBACK_HOST']}/status.json",
          'TIMBERLAND_CMD' => self.timberland_command.run_cmd,
        }
      end

      # Cargo
      def container_labels
        {
          'build-type' => 'app',
        }
      end

      # Cargo
      def container_links
        if datastore
          [[datastore_container_name, datastore].join(':')]
        else
          nil
        end
      end

      # Cargo
      def exposed_ports
        nil
      end
    end
  end
end
