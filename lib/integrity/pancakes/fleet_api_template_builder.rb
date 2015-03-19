module Integrity
  module Pancakes
    module FleetApiTemplateBuilder
      extend self

      def base_hash(cmd:, container_name:, environment:, image:, machineof:, net_container_name:, ports:, requires:, oneshot: false)
        _docker_run_cmd = docker_run(container_name: container_name,
                                     net_container_name: net_container_name,
                                     environment: environment,
                                     ports: ports,
                                     image: image,
                                     cmd: cmd)

        x_fleet =
          if machineof
            { 'MachineOf' => machineof }
          else
            { 'MachineMetadata' => 'role=worker'}
          end

        maybe_oneshot =
          if oneshot
            {
              'Type' => 'oneshot',
              'RemainAfterExit' => 'true',
            }
          else
            {}
          end

        {
          'Unit' => {
            'Description' => pancake_desc(container_name),
            'After'       => requires,
            'Requires'    => requires,
          },
          'Service' => {
            'ExecStart' => _docker_run_cmd,
            'ExecStop'  => [docker_rm(container_name: container_name)],
          }.merge(maybe_oneshot),
          'Install' => {
            'WantedBy' => 'local.target',
          },
          'X-Fleet' => x_fleet,
        }
      end

      def dockyard_cmd(branch:, gh_read_token:, repo:, dockyard_cmd:, dockyard_source:, branch_identifier:, logging_prefix:)
        clone_dir = 'test_subject'
        cmd = logging_prefix_pipe(
          logging_prefix,
          "git clone --depth 1 --branch #{branch} https://#{gh_read_token}@github.com/#{repo} ./#{clone_dir} && ./#{clone_dir}/dockyard-run #{dockyard_cmd} #{dockyard_source} #{branch_identifier}"
        )
        "/bin/bash -c '#{cmd}'"
      end

      def logging_prefix_pipe(logging_prefix, cmd)
        %Q?#{cmd} |& sed -u -e"s/^/[#{logging_prefix}] /"?
      end

      # @api private
      def env_string(env_hash)
        env_hash.to_a.map do |k,v|
          format('-e "%s=%s"', k.to_s, v.to_s)
        end.join(' ')
      end

      # @api private
      def docker_rm(container_name:)
        %Q|/usr/bin/docker rm -f #{container_name}|
      end

      # @api private
      def ports_str(ports)
        return '' unless ports
        ports.map do |p|
          format('-p %s', p.to_s)
        end.join(' ')
      end

      # @api private
      def docker_run(container_name:, net_container_name:, environment: {}, ports:, image:, cmd:)
        if net_container_name && net_container_name != container_name
          net_str = "--net=container:#{net_container_name}"
        else
          net_str = ''
        end
        #cmd = %Q|/usr/bin/docker run --rm -v /var/lib/docker/tmp:/tmp/hosttmp --name=#{container_name} #{net_str} #{env_string(environment)} #{ports_str(ports)} #{image} #{cmd}|
        its_a_string = [net_str, env_string(environment), ports_str(ports), image, cmd].flatten.map(&:to_s).map(&:strip).join(' ')
        %Q|/usr/bin/docker run --rm -v /var/lib/docker/tmp:/tmp/hosttmp --name=#{container_name} #{its_a_string}|
      end

      # @api private
      def service_file_name(service_name)
        "#{service_name}.service"
      end

      # @api private
      def pancake_desc(container_name)
        "pancakes container #{container_name}"
      end
    end
  end
end
