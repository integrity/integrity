module HonestyCluster
  module SwarmBackend
    module DockerUtil

      #def service_container_json
        #docker_api_container_json(
          #name:          self.container_name,
          #links:         self.app_container_links,
          #image:         self.app_image_name,
          #cmd:           self.docker_command,
          #exposed_ports: self.app_exposed_ports,
          #env:           self.app_docker_env('TIMBERLAND_CMD' => self.command.run_cmd),
          #labels:        self.app_docker_labels,
        #)
      #end
      #def app_container_json
        #docker_api_container_json(
          #name:          self.container_name,
          #links:         self.container_links,
          #image:         self.image_name,
          #cmd:           self.docker_command,
          #exposed_ports: self.exposed_ports,
          #env:           self.docker_env,
          #labels:        self.container_labels,
        #)
      #end
      def docker_api_container_json(name:, image:, cmd:, links:, exposed_ports:, env:, labels:)
        {
          'name' => name,
          Cmd: cmd,
          Image: image,
          ExposedPorts: docker_api_transform_exposed_ports(exposed_ports),
          Env: docker_api_build_env(env),
          Hostname: name,
          Labels: labels,
          HostConfig: {
            Binds: ['/var/lib/docker/tmp:/tmp/hosttmp'],
            PublishAllPorts: true,
            Links: links,
            LogConfig: { Type: 'syslog', Config: {'syslog-tag' => name} },
          },
        }
      end

      def containers_filtered(filter_key, filter_val)
        return [] if HonestyCluster.dry_run?
        Docker::Container.all(
          {
            'all' => 1,
            filters: SwarmBackend.label_filter(filter_key, filter_val),
          },
          SwarmBackend.connection,
        )
      end

      def create_container(json)
        msg = "creating container #{_json['name']}"
        if HonestyCluster.dry_run?
          puts "[dry-run] #{msg}"
          puts "[dry-run] json:"
          puts _json.ai
          nil
        else
          puts msg
          Docker::Container.create(_json, SwarmBackend.connection)
        end
      end

      private def label_filter(key, value)
        JSON.dump(
          { label: [[key, value].join('=')] }
        )
      end

      private def docker_api_build_env(env_hash)
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
  end
end
