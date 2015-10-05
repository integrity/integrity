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
  end
end
