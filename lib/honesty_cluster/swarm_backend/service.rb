module HonestyCluster
  module SwarmBackend
    module Service
      include Cargo

      def timberland_command
        @__tmb_cmd ||= Timberland::Cmd.new(
          boot_type:    'pancakes',
          service_type: self.subtype,
          sha:          self.sha,
          repo:         self.repo,
          branch:       self.branch,
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
        if timberlandified?
          timberland_command.to_docker_api_cmd
        else
          nil
        end
      end

      # Cargo
      def exposed_ports
        self.ports
      end

      # Cargo
      def container_env
        _env = {
          'PANCAKES_ID' => self.stack_id,
          'STACK_ID' => self.stack_id,
          'SERVICE_ID' => self.id,
          'PANCAKES_SHA' => self.stack.short_sha,
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



      # pancakes

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

      def health_checkable?
        !!service_def.ping_url
      end

      def health_check_url
        if addr_known? && health_checkable?
          service_def.ping_url.sub('$ip', machine_ip).sub('$port', port.to_s)
        else
          nil
        end
      end

      def healthy_http_status
        service_def.http_status
      end

      def make_health_check_http_request(url, desired_response)
        resp =
          if desired_response == 302
            Net::HTTP.get_response(URI(url))
          else
            RestClient::Request.execute(method: :get, url: url, timeout: 5, open_timeout: 5)
          end

        if (resp_code = resp.code.to_i) == healthy_status
          [:complete]
        else
          [:failed,
           "health_check failed. required=#{healthy_status} got=#{code} url=#{url}"]
        end
      end

      def current_health
        name           = self.service_name
        url            = self.health_check_url
        healthy_status = self.healthy_http_status

        HealthCheck.new(*
          if url
            begin
              make_health_check_http_request(url, healthy_status)
            rescue StandardError => e
              [:failed,
               "unreachable at #{url} due to #{e.class} '#{e.message}'"]
            end
          else
            [:failed,
             "health check url is unavailable"]
          end
        )
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
