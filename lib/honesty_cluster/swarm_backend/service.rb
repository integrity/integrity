module HonestyCluster
  module SwarmBackend
    module Service


      #             ___.   .__  .__
      # ______  __ _\_ |__ |  | |__| ____
      # \____ \|  |  \ __ \|  | |  |/ ___\
      # |  |_> >  |  / \_\ \  |_|  \  \___
      # |   __/|____/|___  /____/__|\___  >
      # |__|             \/             \/

      def create_container
        puts "creating container #{self.name}"
        cmd = make_timberland_command(self)
        Docker::Container.create(container_json(self, cmd), SwarmBackend.conn)
      end

      def start_container
        _start_container(container)
      end

      def _start_container(container)
        container.start
      end

      def run_container_async
        _start_container create_container
      end

      def container
        Docker::Container.all(
          {
            'all' => 1,
            filters: SwarmBackend.label_filter('pancakes-unit', self.name),
          },
          SwarmBackend.conn,
        ).first
      end

      def container_running?
        container.running?
      end

      def is_setup_service?
        self.subtype == 'setup'
      end

      def container_nominal?
        _container = container

        if !_container
          puts "there is no container for this service"
          false
        elsif is_setup_service?
          if _container.exited?
            if _container.exit_code == 0
              puts "setup was successful"
              true
            else
              puts "setup failed"
              false
            end
          else
            puts "setup is still running, but that's okay"
            true
          end
        elsif _container.running?
          puts "the container is running"
          true
        else
          puts "the container is neither running nor exited"
          false
        end
      end

      def addr_known?
        machine_ip && port
      end

      def health_check_url
        if addr_known? && health_checkable?
          service_def.ping_url.sub('$ip', machine_ip).sub('$port', port.to_s)
        else
          nil
        end
      end

      def health_checkable?
        !!service_def.ping_url
      end

      def healthy_http_status
        service_def.http_status
      end

      def create_health_check_event(passed, msg=nil)
        status = passed ? 'HEALTH_CHECK_COMPLETE' : 'HEALTH_CHECK_FAILED'
        self.add_event(source: 'honesty', type: 'Pancakes::Service::HealthCheck', status: status, status_message: msg)
        return passed
      end

      def check_health
        name = self.service_name
        raise "service #{name} is not ready for health check" unless health_checkable?
        url = self.ping_url
        healthy_status = self.healthy_http_status

        begin
          if url.start_with?('http')
            resp = if healthy_status == 302
              Net::HTTP.get_response(URI(url))
            else
              RestClient::Request.execute(method: :get, url: url, timeout: 5, open_timeout: 5)
            end

            code = resp.code.to_i

            if code == healthy_status
              create_health_check_event(true)
            else
              create_health_check_event(false, "service #{name} health_check failed. required=#{healthy_status} got=#{code} url=#{url}")
            end
          else
            create_health_check_event(false, "service #{name} at #{url} cannot be health checked due to url scheme #{url}")
          end
        rescue StandardError => e
          create_health_check_event(false, "service #{name} at #{url} is unreachable due to #{e.class} '#{e.message}'")
        end
      end

      def last_health_check
        events_dataset.where(type: 'Pancakes::Service::HealthCheck').reverse_order(:created_at).limit(1).first
      end


      #              .__               __
      # _____________|__|__  _______ _/  |_  ____
      # \____ \_  __ \  \  \/ /\__  \\   __\/ __ \
      # |  |_> >  | \/  |\   /  / __ \|  | \  ___/
      # |   __/|__|  |__| \_/  (____  /__|  \___  >
      # |__|                        \/          \/

      private def bash_minus_c(cmd)
        ['/bin/bash', '-c', cmd]
      end

      private def container_json(unit, cmd)
        {
          'name' => unit.name,
          Cmd: cmd ? bash_minus_c(cmd) : nil,
          Image: unit.image,
          ExposedPorts: docker_api_exposed_ports(unit),
          Env: docker_api_env(unit, cmd),
          Hostname: unit.name,
          Labels: {
            'honesty' => '',
            'pancakes-stack' => unit.stack.name,
            'pancakes-unit' => unit.name,
          },
          HostConfig: {
            Binds: ['/var/lib/docker/tmp:/tmp/hosttmp'],
            PublishAllPorts: true,
            LogConfig: {
              Type: 'syslog',
              Config: {'syslog-tag' => unit.name},
            },
          },
        }
      end

      private def fill_env_value(k,v)
        v = v.to_s
        if v == ':self'
          v = ENV[k]
        elsif v.start_with?(':')
          v = ENV[v.sub(/\A:/, '')]
        end
        [k,v]
      end

      private def docker_api_exposed_ports(unit)
        (unit.ports || []).map do |port|
          {"#{port}/tcp" => {}}
        end.reduce(&:merge)
      end

      private def make_timberland_command(unit, setup_db: true)
        if !%w[mysql mailcatcher postgres].include?(unit.service_name)
          Pancakes::Fleet::Templating.bash_and(
            Pancakes::Fleet::Templating.timberland_clone(
              Pancakes.gh_read_token,
              Pancakes::Fleet::Templating.config.timberland_branch
            ),
            'cd timberland',
            Pancakes::Fleet::Templating.timberland(
              boot_type:    'pancakes',
              sha:          unit.commit.sha,
              repo:         unit.repo,
              debug:        Pancakes.timberland_debug?,
              branch:       unit.commit.branch,
              setup_db:     setup_db,
              service_type: unit.subtype,
            )
          )
        else
          nil
        end
      end

      private def docker_api_env(unit, cmd)
        {
          'PANCAKES_ID' => unit.stack.id,
          'PANCAKES_SHA' => unit.stack.short_sha,
          'HONESTY_BASE_URL' => SwarmBackend.base_url,
          'TIMBERLAND_CMD' => cmd,
        }.merge(unit.env)
        .map do |k,v|
          fill_env_value(k,v).join('=')
        end
      end
    end
  end
end
