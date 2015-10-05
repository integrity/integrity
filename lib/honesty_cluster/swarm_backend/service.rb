module HonestyCluster
  module SwarmBackend
    module Service
      include SwarmBackend::Cargo

      def timberland_command
        @__tmb_cmd ||= Timberland::Cmd.new(
          boot_type:    'pancakes',
          sha:          self.sha,
          repo:         self.repo,
          debug:        Pancakes.timberland_debug?,
          branch:       self.branch,
          setup_db:     true,
          service_type: self.subtype,
        )
      end

      # Cargo
      def cargo_group_type
        'pancakes-stack'
      end

      # Cargo
      def cargo_group_id
        self.stack_id
      end

      # Cargo
      def cargo_type
        'pancakes-service'
      end

      # Cargo
      def cargo_id
        self.id
      end

      # Cargo
      def container_name
        self.name
      end

      # Cargo
      def container_links
        nil
      end

      # Cargo
      def image_name
        self.image
      end

      # Cargo
      def docker_command
        timberland_command.to_docker_api_cmd
      end

      # Cargo
      def exposed_ports
        self.ports
      end

      # Cargo
      def container_env
        {
          'PANCAKES_ID' => self.stack_id,
          'STACK_ID' => self.stack_id,
          'SERVICE_ID' => self.id,
          'PANCAKES_SHA' => self.stack.short_sha,
          'HONESTY_BASE_URL' => SwarmBackend.base_url,
          'TIMBERLAND_CMD' => self.timberland_command.run_cmd,
        }
      end

      # Cargo
      def container_labels
        nil
      end



      # pancakes

      def container
        containers.first
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



      # health checking

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
        create_health_check_event(false, "health check address is unavailable") unless addr_known?
        raise "service #{name} is not ready for health check" unless health_checkable?
        url = self.health_check_url
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

      #private def bash_minus_c(cmd)
        #['/bin/bash', '-c', cmd]
      #end

      #private def container_json(unit, cmd)
        #{
          #'name' => unit.name,
          #Cmd: cmd ? bash_minus_c(cmd) : nil,
          #Image: unit.image,
          #ExposedPorts: docker_api_exposed_ports(unit),
          #Env: docker_api_env(unit, cmd),
          #Hostname: unit.name,
          #Labels: {
            #'honesty' => '',
            #'pancakes-stack-id' => unit.stack.id,
            #'pancakes-service-id' => unit.id,
          #},
          #HostConfig: {
            #Binds: ['/var/lib/docker/tmp:/tmp/hosttmp'],
            #PublishAllPorts: true,
            #LogConfig: {
              #Type: 'syslog',
              #Config: {'syslog-tag' => unit.name},
            #},
          #},
        #}
      #end

      # docker helpers
      #private def fill_env_value(k,v)
        #v = v.to_s
        #if v == ':self'
          #v = ENV[k]
        #elsif v.start_with?(':')
          #v = ENV[v.sub(/\A:/, '')]
        #end
        #[k,v]
      #end

      # docker helpers
      #private def docker_api_exposed_ports(unit)
        #(unit.ports || []).map do |port|
          #{"#{port}/tcp" => {}}
        #end.reduce(&:merge)
      #end

      #tb
      #private def make_timberland_command(unit, setup_db: true)
        #if !%w[mysql mailcatcher postgres].include?(unit.service_name)
          #Pancakes::Fleet::Templating.bash_and(
            #Pancakes::Fleet::Templating.timberland_clone(
              #Pancakes.gh_read_token,
              #Pancakes::Fleet::Templating.config.timberland_branch
            #),
            #'cd timberland',
            #Pancakes::Fleet::Templating.timberland(
              #boot_type:    'pancakes',
              #sha:          unit.commit.sha,
              #repo:         unit.repo,
              #debug:        Pancakes.timberland_debug?,
              #branch:       unit.commit.branch,
              #setup_db:     setup_db,
              #service_type: unit.subtype,
            #)
          #)
        #else
          #nil
        #end
      #end

      # docker helpers
      #private def docker_api_env(unit, cmd)
        #{
          #'PANCAKES_ID' => unit.stack.id,
          #'STACK_ID' => unit.stack.id,
          #'SERVICE_ID' => unit.id,
          #'PANCAKES_SHA' => unit.stack.short_sha,
          #'HONESTY_BASE_URL' => SwarmBackend.base_url,
          #'TIMBERLAND_CMD' => cmd,
        #}.merge(unit.env)
        #.map do |k,v|
          #fill_env_value(k,v).join('=')
        #end
      #end
    end
  end
end
