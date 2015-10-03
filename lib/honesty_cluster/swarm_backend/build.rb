module Timberland
  class Cmd
    NAME = 'timberland'

    attr_reader :boot_type, :sha, :repo, :debug, :branch, :setup_db, :service_type

    def initialize(boot_type:, service_type:, sha:, repo:, branch:nil, debug:nil, setup_db:nil)
      @timberland_branch = Pancakes::Fleet::Templating.config.timberland_branch
      @boot_type    = boot_type
      @service_type = service_type
      @sha          = sha
      @repo         = repo
      @branch       = branch
      @debug       ||= Pancakes.timberland_debug?
      @setup_db    ||= true
    end

    def to_s
      run_cmd
    end

    def to_docker_api_cmd
      bash_minus_c(clone_and_run_cmd)
    end

    def clone_and_run_cmd
      bash_and(
        clone_cmd,
        "cd #{NAME}",
        run_cmd,
      )
    end

    def clone_cmd
      join_args(
        'git', 'clone',
        '--depth', 1,
        '--branch', @timberland_branch,
        "https://#{Pancakes.gh_read_token}@github.com/consultingmd/#{NAME}",
        NAME,
      )
    end

    def run_cmd
      join_args(
        "./#{NAME}",
        '--boot-type', boot_type,
        '--service-type', service_type,
        '--sha', sha,
        '--repo', repo,
        !setup_db ? '--no-setup-db' : nil,
        debug ? '--debug' : nil,
        (branch && !branch.empty?) ? ['--branch', branch] : nil
      )
    end

    private def bash_minus_c(cmd)
      ['/bin/bash', '-c', cmd]
    end

    private def bash_and(*cmds)
      cmds.join(' && ')
    end

    private def join_args(*args)
      args.flatten.compact.map(&:to_s).map(&:strip).join(' ').strip
    end
  end
end

module HonestyCluster
  module SwarmBackend

    module DockerApiHelpers
      def docker_api_container_json(name:, image:, cmd: nil, links: nil, exposed_ports: nil, env: nil, labels: nil)
        {
          'name' => name,
          Cmd: cmd,
          Image: image,
          ExposedPorts: docker_api_transform_exposed_ports(exposed_ports),
          Env: docker_api_build_env(env),
          Hostname: name,
          Labels: {'honesty' => ''}.merge(labels),
          HostConfig: {
            Binds: ['/var/lib/docker/tmp:/tmp/hosttmp'],
            PublishAllPorts: true,
            Links: links,
            LogConfig: {
              Type: 'syslog',
              Config: {'syslog-tag' => name},
            },
          },
        }
      end

      def docker_api_build_env(env_hash)
        return nil unless env_hash
        env_hash.map do |k,v|
          docker_api_interpolate_env_var(k,v).join('=')
        end
      end

      private def docker_api_transform_exposed_ports(list_of_ports)
        return nil unless list_of_ports && !list_of_ports.empty?
        list_of_ports.map do |port|
          {"#{port}/tcp" => {}}
        end.reduce(&:merge)
      end

      private def docker_api_interpolate_env_var(k,v)
        k, v = k.to_s, v.to_s
        if v == ':self'
          v = ENV[k] || "<<< #{k} not found in honesty environment >>>"
        elsif v.start_with?(':')
          v = ENV[v.sub(/\A:/, '')]
        end
        [k,v]
      end
    end


    module Build
      include DockerApiHelpers


      #             ___.   .__  .__
      # ______  __ _\_ |__ |  | |__| ____
      # \____ \|  |  \ __ \|  | |  |/ ___\
      # |  |_> >  |  / \_\ \  |_|  \  \___
      # |   __/|____/|___  /____/__|\___  >
      # |__|             \/             \/


      def swarm_start
        if datastore
          ds_json = datastore_container_json
          #byebug
          _container = create_container(ds_json)
          _container.start
        end

        app_json = app_container_json
        #byebug
        _container = create_container(app_json)
        _container.start
      end

      def swarm_destroy
        containers.each do |container|
          puts "removing (with force) container #{container.name}"
          container.remove(force: true)
        end
      end

      def containers
        Docker::Container.all(
          {
            'all' => 1,
            filters: SwarmBackend.label_filter('honesty-build', build_container_prefix),
          },
          SwarmBackend.conn,
        )
      end

      def build_container_prefix
        self.service_name
      end

      def create_container(json)
        puts "creating container #{json['name']}"
        Docker::Container.create(json, SwarmBackend.conn)
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

      def datastore_container_name
        [build_container_prefix, datastore].join('_')
      end

      def app_image_name
        "grnds/#{self.project_name}_ci:latest"
      end

      def datastore_image_name
        "grnds/#{self.datastore}:latest"
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

      def datastore_exposed_ports
        if datastore == 'mysql'
          [3306]
        elsif datastore == 'postgres'
          [5432]
        else
          nil
        end
      end

      def app_docker_labels
        {
          'honesty-build' => build_container_prefix,
          'honesty-build-type' => 'app',
        }
      end

      def datastore_docker_labels
        {
          'honesty-build' => build_container_prefix,
          'honesty-build-type' => datastore,
        }
      end

      def timberland_boot_type
       'build'
      end

      def timberland_service_type
        'spec'
      end
    end
  end
end
