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
            #LogConfig: { Type: 'syslog', Config: {'syslog-tag' => name} },
            Privileged: true,
          },
        }
      end

      def containers_filtered(filters)
        return [] if HonestyCluster.dry_run?
        Docker.logger.info "getting containers: #{filters.inspect}"
        Docker::Container.all(
          {
            'all' => 1,
            filters: docker_api_label_filters(filters),
          }
        )
      end

      class InMemoryCache
        def initialize
          off
        end

        private def cache
          @__cache
        end

        def active?
          !!cache
        end

        def fresh
          @__cache = {}
        end

        def off
          @__cache = nil
        end

        def get(key)
          return nil unless active?
          if rv = cache[key]
            puts 'cache hit'
            rv
          else
            puts 'cache miss'
            nil
          end
        end

        def put(key, value)
          return nil unless active?
          cache[key] = value
        end
      end

      @@container_cache = InMemoryCache.new

      def filters_cache_key(filters)
        filters.keys.sort.map{|key| [key, filters[key]].join('=') }.join(',')
      end

      def containers_filtered_from_cache(filters)
        filters ||= {}
        if @@container_cache.active?
          cache_key = filters_cache_key(filters)
          if kontainers = @@container_cache.get(cache_key)
            kontainers
          else
            kontainers = containers_filtered(filters)
            @@container_cache.put(cache_key, kontainers)
            kontainers
          end
        else
          containers_filtered(filters)
        end
      end

      def self.with_cached_containers(&block)
        @@container_cache.fresh
        rv = block.call
        @@container_cache.off
        rv
      end

      def create_container(docker_json)
        msg = "creating container #{docker_json['name']}"
        if HonestyCluster.dry_run?
          logger.info "[dry-run] #{msg}"
          logger.info "[dry-run] docker_json:"
          logger.info docker_json.ai
          nil
        else
          logger.info msg
          Docker::Container.create(docker_json)
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

      def docker_api_pull_image(image_name)
        docker_api_with_timeout(10*60) do
          Docker.logger.info "pulling image: #{image_name}"
          Docker::Image.create({'fromImage' => image_name})
        end
      #rescue Docker::Error::TimeoutError => e
        ## image pulls may be long, so just accept it
        #return nil
      end

      def docker_api_with_timeout(timeout, &block)
        curr = Docker.options[:read_timeout]
        Docker.options[:read_timeout] = timeout
        yield
      ensure
        Docker.options[:read_timeout] = curr || nil
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
