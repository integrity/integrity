module Pancakes
  module Fleet
    module Templating
      extend self

      DOCKER = '/usr/bin/docker'

      def detect_and_make_template(unit)
        if unit.service_name == 'mysql'
          mysql_template(unit)
        elsif unit.service_name == 'mailcatcher'
          base_template(unit: unit)
        else
          dockyard_template(unit)
        end
      end

      def gen_service_file_name(unit)
        return nil unless unit
        "#{unit.name}.service"
      end

      # @param codebase :jarvis, :frick, :tim, etc. ie, not jarvis-server, tim-orchestra, etc. only the codebase part of the service name.
      # @api private
      def git_env(commit)
        {
          'BRANCH' => commit.branch,
          'SHA'    => commit.sha,
        }
      end

      # @api private
      def dockyard_template(unit)
        codebase = unit.service_def.codebase
        stack = unit.stack
        commit = stack.commit_for_codebase(codebase)

        cmd = Pancakes::Fleet::Templating.dockyard_cmd(
          sha:               commit.sha,
          repo:              unit.service_def.repo,
          debug:             !!ENV['DOCKYARD_DEBUG'],
          branch:            commit.branch,
          codebase:          codebase,
          service_type:      unit.service_def.subtype,
          gh_read_token:     ENV['GITHUB_READ_TOKEN'],
          logging_prefix:    unit.name,
          dockyard_source:   'from_github',
          branch_identifier: stack.branch_sha_short,
        )

        base_template(unit: unit, cmd: cmd, more_env: git_env(commit))
      end

      # @api private
      def base_template(unit:, cmd: nil, more_env: {})
        service_def = unit.service_def
        machine_of_unit = service_def.machineof ? gen_service_file_name(unit.stack.unit_with_service_name(service_def.machineof)) : nil
        requires_unit = service_def.requires.is_a?(Symbol) ? gen_service_file_name(unit.stack.unit_with_service_name(service_def.requires)) : service_def.requires
        ports = service_def.netmaster ? Pancakes::Services.all_ports : nil

        Pancakes::Fleet::Templating.base_hash(
          cmd:            cmd,
          image:          service_def.image,
          ports:          ports,
          oneshot:        service_def.name.include?('orchestra')
          requires:       requires_unit,
          machineof:      machine_of_unit,
          container:      unit.name,
          environment:    (service_def.env || {}).merge(more_env),
          netmaster_name: unit.stack.netmaster_unit.name,
        )
      end

      # @api private
      def mysql_template(unit)
        template = base_template(unit: unit)
        cmd = Pancakes::Fleet::Templating.logging_prefix_pipe(
          unit.name,
          "-#{DOCKER} exec #{unit.name} /root/freeze.sh #{unit.stack.branch_sha_short}"
        )
        template['Service']['ExecStop'].unshift(cmd)
        template
      end

      # @api private
      def base_hash(cmd:, container:, environment:, image:, machineof:, netmaster_name:, ports:, requires:, oneshot: false)
        _docker_run_cmd = docker_run(container: container,
                                     netmaster_name: netmaster_name,
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

        #i_am_netmaster = netmaster_name == container
        #maybe_pause =
          #if !i_am_netmaster
            #{
              #'ExecStartPost' => [
                #'/bin/sleep 1',
                #docker_pause(container: container)
              #]
            #}
          #else
            #{}
          #end

        {
          'Unit' => {
            'Description' => pancake_desc(container),
            'After'       => requires,
            'Requires'    => requires,
          },

          'Service' => {
            'TimeoutStartSec' => '10min',
            'ExecStartPre' => [
              systemd_minus(docker_cmd(:kill, container)),
              systemd_minus(docker_cmd(:rm, container)),
              docker_cmd(:pull, image),
            ],
            'ExecStart'    => _docker_run_cmd,
            'ExecStop'     => [
              docker_cmd(:stop, container),
              docker_cmd(:rm, container),
            ],
          }.merge(maybe_oneshot),

          'Install' => {
            'WantedBy' => 'local.target',
          },

          'X-Fleet' => x_fleet,
        }
      end

      # @api private
      def dockyard_cmd(branch:, sha:, repo:, codebase:, service_type:, dockyard_source:, branch_identifier:, logging_prefix:, gh_read_token:, debug: false)
        clone_dir = 'test_subject'
        debug_arg = debug ? 'DEBUG=true' : ''
        cmd = logging_prefix_pipe(
          logging_prefix,
          #"git clone --depth 1 --branch #{branch} https://#{gh_read_token}@github.com/#{repo} ./#{clone_dir} && ./#{clone_dir}/dockyard-run #{service_type} #{dockyard_source} #{branch_identifier}"

          "git clone --depth 1 --branch pancakes https://#{gh_read_token}@github.com/consultingmd/dockyard dockyard && ./dockyard/build.sh #{branch} #{sha} #{repo} #{codebase} #{clone_dir} #{service_type} #{branch_identifier} #{debug_arg}"
        )
        "/bin/bash -c '#{cmd}'"
      end

      # @api private
      def logging_prefix_pipe(logging_prefix, cmd)
        %Q?#{cmd.strip} |& sed -u -e"s/^/[#{logging_prefix}] /"?
      end

      # @api private
      def env_str(env_hash)
        return nil unless env_hash
        env_hash.to_a.map do |k,v|
          v = ENV[k] if v == true
          format('-e "%s=%s"', k.to_s, v.to_s)
        end.join(' ')
      end

      # @api private
      def ports_str(ports)
        return nil unless ports
        ports.map do |p|
          format('-p %s', p.to_s)
        end.join(' ')
      end

      # @api private
      def systemd_minus(cmd)
        "-#{cmd}"
      end

      # @api private
      def docker_cmd(cmd, image_or_container)
        %Q|#{DOCKER} #{cmd} #{image_or_container}|
      end

      # @api private
      def docker_run(container:, netmaster_name:, environment: {}, ports:, image:, cmd:)
        i_am_netmaster = netmaster_name == container
        if !i_am_netmaster
          net_str = "--net=container:#{netmaster_name}"
        else
          net_str = ''
        end

        its_a_string = [net_str, env_str(environment), ports_str(ports), image, cmd].compact.map(&:to_s).map(&:strip).join(' ').strip
        %Q|#{DOCKER} run -v /var/lib/docker/tmp:/tmp/hosttmp --name=#{container} #{its_a_string}|
      end

      # @api private
      def pancake_desc(container)
        "pancakes container #{container}"
      end
    end
  end
end
