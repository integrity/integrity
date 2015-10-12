module HonestyCluster
  module SwarmBackend
    module DockerUtil
      include ClassLogger

      def docker_api_container_json(name:, image:, cmd:, links:, exposed_ports:, env:, labels:, cpu_shares:, memory:)
        {
          'name' => name,
          Cmd: cmd,
          Image: image,
          ExposedPorts: docker_api_transform_exposed_ports(exposed_ports),
          Env: docker_api_build_env(env),
          Hostname: name,
          Labels: docker_api_stringify_labels(labels),
          HostConfig: {
            Binds: ['/var/lib/docker/tmp:/tmp/hosttmp'],
            CpuShares: cpu_shares,
            Memory: memory,
            #PublishAllPorts: true,
            PortBindings: docker_api_port_bindings(exposed_ports),
            Links: links,
            LogConfig: { Type: 'syslog', Config: {'syslog-tag' => name} },
          },
        }
      end

      def containers_filtered(filters)
        return [] if HonestyCluster.dry_run?
        Docker::Container.all(
          {
            'all' => 1,
            filters: docker_api_label_filters(filters),
          },
          SwarmBackend.connection,
        )
      end

      def create_container(json)
        msg = "creating container #{json['name']}"
        if HonestyCluster.dry_run?
          logger.info "[dry-run] #{msg}"
          logger.info "[dry-run] json:"
          logger.info json.ai
          nil
        else
          logger.info msg
          Docker::Container.create(json, SwarmBackend.connection)
        end
      end

      def node_constraint(node)
        { "constraint:node==#{node}" => nil }
      end

      def node_type_constraint(type)
        { "constraint:grnds.node_type==#{type}" => nil }
      end

      def MB(bytes)
        bytes * 2**20
      end

      #ports should look like: [[private_port, public_port], ...]
      private def docker_api_port_bindings(ports)
        return nil unless ports
        ports.map do |(priv,pub)|
          { "#{priv}/tcp" => [{ 'HostPort' => (pub ? pub.to_s : '') }] }
        end.reduce(&:merge)
      end

      private def docker_api_label_filters(filters)
        filters = filters.to_a.map do |key,value|
          [key.to_s, value.to_s].join('=')
        end

        JSON.dump({ label: filters })
      end

      private def docker_api_build_env(env_hash)
        return nil unless env_hash
        env_hash.map do |k,v|
          if v
            docker_api_interpolate_env_var(k,v).join('=')
          else
            k
          end
        end
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

      private def docker_api_transform_exposed_ports(list_of_ports)
        return nil unless list_of_ports && !list_of_ports.empty?
        list_of_ports.map do |(private_port,_)|
          {"#{private_port}/tcp" => {}}
        end.reduce(&:merge)
      end

      private def docker_api_stringify_labels(labels)
        labels.map do |k,v|
          [k.to_s, v.to_s]
        end.to_h
      end
    end
  end
end
