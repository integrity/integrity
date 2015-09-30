module HonestyCluster
  module SwarmBackend
    extend self

    #Diplomat.configure do |config|
      #config.url = (ENV['CONSUL_HOST'] || raise('must set CONSUL_HOST'))
    #end

    def conn
      @__swarm_conn ||= Docker::Connection.new((ENV['DOCKER_HOST'] || raise('must set DOCKER_HOST')), {})
    end


    def base_url
      Integrity.base_url
    end

    #def start_container(unit)
    #end

    #def destroy_unit(unit)
    #end

    #def all_containers(filters: nil)
      #Docker::Container.all({filters: filters}, conn)
    #end

    def label_filter(key, value)
      JSON.dump(
        { label: [[key, value].join('=')] }
      )
    end

    def get_unit_from_container(container_name)
      unit_info = Pancakes::Unit.parse_unit_name(container_name)
      Pancakes::Unit.where(stack_id: unit_info.stack_id, service_name: unit_info.service_name).first
    end







    module Service

      ## assumes the "account/repo:tag" format
      #private def consul_service_name_from_image
        #self.image.split(/[\/:]/)[1]
      #end

      #def consul_service_name
        #name = consul_service_name_from_image
        #if ports && ports.size > 1
          #[name, primary_private_port].join('-')
        #else
          #name
        #end
      #end

      #private def consul_service_container_name(service_id)
        #service_id.split(':')[1]
      #end

      #def consul_service_info
        #Diplomat::Service.get(consul_service_name, :all).detect do |service_instances|
          #Array(service_instances).detect {|inst| consul_service_container_name(inst.ServiceID).match(self.name) }
        #end
      #end


      # {
      #   "Hostname": "",
      #   "Domainname": "",
      #   "User": "",
      #   "AttachStdin": false,
      #   "AttachStdout": true,
      #   "AttachStderr": true,
      #   "Tty": false,
      #   "OpenStdin": false,
      #   "StdinOnce": false,
      #   "Env": null,
      #   "Cmd": [
      #     "date"
      #   ],
      #   "Entrypoint": "",
      #   "Image": "ubuntu",
      #   "Labels": {
      #     "com.example.vendor": "Acme",
      #     "com.example.license": "GPL",
      #     "com.example.version": "1.0"
      #   },
      #   "Mounts": [
      #     {
      #       "Source": "/data",
      #       "Destination": "/data",
      #       "Mode": "ro,Z",
      #       "RW": false
      #     }
      #   ],
      #   "WorkingDir": "",
      #   "NetworkDisabled": false,
      #   "MacAddress": "12:34:56:78:9a:bc",
      #   "ExposedPorts": {
      #     "22/tcp": {}
      #   },
      #   "HostConfig": {
      #     "Binds": ["/tmp:/tmp"],
      #     "Links": ["redis3:redis"],
      #     "LxcConf": {"lxc.utsname":"docker"},
      #     "Memory": 0,
      #     "MemorySwap": 0,
      #     "CpuShares": 512,
      #     "CpuPeriod": 100000,
      #     "CpusetCpus": "0,1",
      #     "CpusetMems": "0,1",
      #     "BlkioWeight": 300,
      #     "MemorySwappiness": 60,
      #     "OomKillDisable": false,
      #     "PortBindings": { "22/tcp": [{ "HostPort": "11022" }] },
      #     "PublishAllPorts": false,
      #     "Privileged": false,
      #     "ReadonlyRootfs": false,
      #     "Dns": ["8.8.8.8"],
      #     "DnsSearch": [""],
      #     "ExtraHosts": null,
      #     "VolumesFrom": ["parent", "other:ro"],
      #     "CapAdd": ["NET_ADMIN"],
      #     "CapDrop": ["MKNOD"],
      #     "RestartPolicy": { "Name": "", "MaximumRetryCount": 0 },
      #     "NetworkMode": "bridge",
      #     "Devices": [],
      #     "Ulimits": [{}],
      #     "LogConfig": { "Type": "json-file", "Config": {} },
      #     "SecurityOpt": [""],
      #     "CgroupParent": ""
      #   }
      # }
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
            filters: SwarmBackend.label_filter('pancakes-unit', self.name),
          },
          SwarmBackend.conn,
        ).first
      end

      #def clear_remote_addr
        #self.machine_ip = self.port = nil
        #save
      #end

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
            #PortBindings: docker_api_port_bindings(unit),
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

      #private def docker_api_port_bindings(unit)
        #(unit.ports || []).map do |port|
          #{"#{port}/tcp" => [{'HostPort' => ''}] }
        #end.reduce(&:merge)
      #end

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

    module Stack
      def mysql_unit
        units_dataset.where(service_name: 'mysql').first
      end

      def postgres_unit
        units_dataset.where(service_name: 'postgres').first
      end

      def swarm_spin_up
        clear_unit_addrs

        #mysql_unit.run_container_async
        #postgres_unit.run_container_async

        #self.units.reject do |unit|
          #%w[mysql postgres].include?(unit.service_name)
        #end
        self.units.select do |unit|
          %w[banyan-server postgres].include?(unit.service_name)
        end
        .each do |unit|
          unit.run_container_async
        end
      end

      def swarm_destroy
        containers.each do |container|
          container.remove(force: true)
        end

        refresh_unit_addrs
        nil
      end

      def clear_unit_addrs
        units_dataset.update(machine_ip: nil, port: nil)
      end

      def containers
        Docker::Container.all(
          {
            'all' => 1, # 'all' can't be a symbol key
            filters: SwarmBackend.label_filter('pancakes-stack', self.name),
          },
          SwarmBackend.conn,
        )
      end

      #def consul_services
        #self.units.map(&:consul_service_info).compact
      #end

      #private?
      def refresh_unit_addrs
        mapped_containers = containers.map do |container|
          [ Pancakes::Unit.parse_unit_name(container.name).service_name, container ]
        end.to_h

        self.units.each do |unit|
          container = mapped_containers[unit.service_name]

          if container
            unit.machine_ip = container.ip
            unit.port = container.public_port
          else
            unit.machine_ip = unit.port = nil
          end
          unit.save
        end
        nil
      end
      #def refresh_unit_addrs
        #self.units.each do |unit|
          #service_info = unit.consul_service_info
          #if service_info
            #unit.machine_ip = service_info.ServiceAddress
            #unit.port = service_info.ServicePort
          #else
            #unit.machine_ip = unit.port = nil
          #end
          #unit.save
        #end
      #end

      def service_addrs
        refresh_unit_addrs

        self.units.map do |unit|
          next(nil) unless unit.tcp_str
          { unit.service_type => unit.tcp_str }
        end
          .compact
          .reduce(&:merge)
      end
    end
  end
end


# file should be /lib/docker/container.rb
module Docker
  class Container
    def info
      Hashie::Mash.new(super)
    end

    def full_name
      info.Names.first
    end

    def name
      name_parts[1]
    end

    def ip
      first_port_mapping ? first_port_mapping.IP : nil
    end

    def public_port
      first_port_mapping ? first_port_mapping.PublicPort : nil
    end

    private def first_port_mapping
      info.Ports.first
    end

    private def name_parts
      full_name.sub(/^\//, '').split('/')
    end

    # possibly deprecated
    def port_mapping
      info.Ports.map do |port_mapping|
        { port_mapping.PrivatePort => port_mapping.PublicPort }
      end.reduce(&:merge)
    end
  end
end
