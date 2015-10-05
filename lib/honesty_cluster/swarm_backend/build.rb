module HonestyCluster
  module SwarmBackend
    module Build
      include DockerApiHelpers


      #             ___.   .__  .__
      # ______  __ _\_ |__ |  | |__| ____
      # \____ \|  |  \ __ \|  | |  |/ ___\
      # |  |_> >  |  / \_\ \  |_|  \  \___
      # |   __/|____/|___  /____/__|\___  >
      # |__|             \/             \/


      def swarm_start
        create_and_start_container(datastore_container_json) if datastore
        create_and_start_container(app_container_json)
      end

      def swarm_destroy
        containers.each do |container|
          puts "removing (with force) container #{container.name}"
          container.force_remove
        end
      end

      private def create_and_start_container(json)
        #byebug
        cc = create_container(json)
        cc.start unless HonestyCluster.dry_run?
        cc
      end

      private def containers
        return [] if HonestyCluster.dry_run?

        Docker::Container.all(
          {
            'all' => 1,
            filters: SwarmBackend.label_filter('honesty-build-id', self.id),
          },
          SwarmBackend.conn,
        )
      end

      def build_container_prefix
        self.service_name
      end

      def timberland_boot_type
       'build'
      end

      def timberland_service_type
        'spec'
      end

      def create_container(json)
        msg = "creating container #{json['name']}"
        if HonestyCluster.dry_run?
          puts "[dry-run] #{msg}"
          puts "[dry-run] json:"
          puts json.ai
          nil
        else
          puts msg
          Docker::Container.create(json, SwarmBackend.conn)
        end
      end

      def app_container_json
        app_cmd = Timberland::Cmd.new(
          boot_type:    self.timberland_boot_type,
          service_type: self.timberland_service_type,
          sha:          self.sha,
          repo:         self.repo_full_name,
          branch:       self.branch_name,
        )

        docker_api_container_json(
          name:          self.app_container_name,
          links:         self.app_container_links,
          image:         self.app_image_name,
          cmd:           app_cmd.to_docker_api_cmd,
          exposed_ports: self.app_exposed_ports,
          env:           self.app_docker_env('TIMBERLAND_CMD' => app_cmd.run_cmd),
          labels:        self.app_docker_labels,
        )
      end

      def app_container_name
        [build_container_prefix, 'app'].join('_')
      end

      def app_image_name
        "grnds/#{self.project_name}_ci:latest"
      end

      def app_docker_env(more_env=nil)
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
        }.merge(more_env || {})
      end

      def app_docker_labels
        {
          'honesty-build-id' => self.id,
          'honesty-build-type' => 'app',
        }
      end

      def app_container_links
        if datastore
          [[datastore_container_name, datastore].join(':')]
        else
          nil
        end
      end

      def app_exposed_ports
        nil
      end





      def datastore_container_json
        return nil unless datastore

        docker_api_container_json(
          name:          self.datastore_container_name,
          image:         self.datastore_image_name,
          exposed_ports: self.datastore_exposed_ports,
          labels:        self.datastore_docker_labels,
        )
      end

      def datastore_container_name
        [build_container_prefix, datastore].join('_')
      end

      def datastore_image_name
        "grnds/#{self.datastore}:latest"
      end

      def datastore_exposed_ports
        if datastore == 'mysql'
          [3306]
        elsif datastore == 'postgres'
          [5432]
        else
          nil
        end
      end

      def datastore_docker_labels
        {
          'honesty-build-id' => self.id,
          'honesty-build-type' => datastore,
        }
      end
    end
  end
end
