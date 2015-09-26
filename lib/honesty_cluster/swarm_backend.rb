module HonestyCluster
  module SwarmBackend
    extend self

    Diplomat.configure do |config|
      config.url = "http://#{ENV['CONSUL_HOST']}:8500"
    end

    def swarm_master_host
      ENV['SWARM_MASTER']
    end

    def conn
      @__swarm_conn ||= Docker::Connection.new("tcp://#{swarm_master_host}", {})
    end

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
    def create_container(unit)
      puts "creating container #{unit.name}"
      #docker_run(
        #container_name: unit.name,
        #netmaster_name: unit.stack.netmaster_unit.name,
        #environment: {
          #'PANCAKES_ID' => unit.stack.id,
          #'PANCAKES_SHA' => unit.stack.short_sha,
          #'HONESTY_BASE_URL' => Integrity.base_url,
        #}.merge(unit.env),
        #ports: unit.netmaster? ? unit.stack.ports : nil,
        #image: unit.image,
        #cmd: cmd,
      #)

      cmd = nil

      Docker::Container.create(
        {
          'name' => unit.name,
          Cmd: cmd,
          Image: unit.image,
          ExposedPorts: docker_api_exposed_ports(unit),
          Env: docker_api_env(unit),
          Labels: {
            'honesty' => '',
            'pancakes-stack' => unit.stack.name,
          },
          'HostConfig' => {
            Binds: ['/var/lib/docker/tmp:/tmp/hosttmp'],
            PublishAllPorts: true,
            #'PortBindings' => {'3306/tcp' => [{'HostPort' => ''}]},
          },
        },
        conn,
      )
    end

    def docker_api_env(unit)
      {
        'PANCAKES_ID' => unit.stack.id,
        'PANCAKES_SHA' => unit.stack.short_sha,
        'HONESTY_BASE_URL' => base_url,
      }.merge(unit.env)
      .map do |k,v|
        [k,v].join('=')
      end
    end

    def docker_api_exposed_ports(unit)
      (unit.ports || []).map do |port|
        {"#{port}/tcp" => {}}
      end.reduce(&:merge)
    end

    def base_url
      Integrity.base_url
    end

    def run_unit(unit)
      container = create_container(unit)
      #byebug
      #container.start
    end

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

    module Service

      # assumes the "account/repo:tag" format
      private def consul_service_name_from_image
        self.image.split(/[\/:]/)[1]
      end

      def consul_service_name
        name = consul_service_name_from_image
        if ports && ports.size > 1
          [name, primary_private_port].join('-')
        else
          name
        end
      end

      private def consul_service_container_name(service_id)
        service_id.split(':')[1]
      end

      def consul_service_info
        Diplomat::Service.get(consul_service_name, :all).detect do |service_instances|
          Array(service_instances).detect {|inst| consul_service_container_name(inst.ServiceID).match(self.name) }
        end
      end
    end

    module Stack
      def swarm_spin_up
        self.units.each do |unit|
          SwarmBackend.run_unit(unit)
        end
      end

      def swarm_destroy
        containers.each do |container|
          container.remove(force: true)
        end
      end

      def containers
        Docker::Container.all(
          { 'all' => 1,
            filters: SwarmBackend.label_filter('pancakes-stack', self.name),
          },
          SwarmBackend.conn,
        )
      end

      def consul_services
        self.units.map(&:consul_service_info).compact
      end

      #private
      def refresh_unit_addrs
        self.units.each do |unit|
          service_info = unit.consul_service_info
          if service_info
            unit.machine_ip = service_info.ServiceAddress
            unit.port = service_info.ServicePort
          else
            unit.machine_ip = unit.port = nil
          end
          unit.save
        end
      end

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

