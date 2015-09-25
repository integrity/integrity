module HonestyCluster
  module SwarmBackend
    extend self

    def swarm_master
      ENV['SWARM_MASTER']
    end

    def conn
      @__swarm_conn ||= Docker::Connection.new("tcp://#{swarm_master}", {})
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
          'Cmd' => cmd,
          'Image' => unit.image,
          'ExposedPorts' => {
            '3306/tcp' => {},
          },
          'Env' => docker_api_env(unit),
          'Mounts' => [
            {
              'Source' => '/var/lib/docker/tmp',
              'Destination' => '/tmp/hosttmp',
              'Mode' => 'rw',
              'RW' => true,
            },
          ],
          'HostConfig' => {
            #'NetworkMode' => 'host',
            'PortBindings' => {'3306/tcp' => [{'HostPort' => ''}]},
          },
        },
        conn
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

    def base_url
      Integrity.base_url
    end

    def run_unit(unit)
      container = create_container(unit)
      #byebug
      container.start
    end

    module Pancakes
      module InstanceMethods
        def swarm_bring_up
          #Docker::Container.all({}, SwarmBackend.conn)
          SwarmBackend.run_unit(netmaster_unit)
        end
      end
    end
  end
end
