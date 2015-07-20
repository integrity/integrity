module Pancakes
  module Fleet
    module Templating
      module Helpers
        extend self

        def dockyard_build_sh(branch:, sha:, repo:, service_type:, setup_db:, debug:)
          args = [
            './dockyard/build.sh',
            '-s', sha,
            '-r', repo,
            '--service-type', service_type,
            !setup_db ? ' --no-setup-db' : nil,
            debug ? ' --debug' : nil,
          ]

          args << "-b #{branch}" if branch && !branch.empty?
          join_args(*args)
        end

        def dockyard_clone(gh_read_token, branch)
          join_args(
            'git', 'clone',
            '--depth', 1,
            '--branch', branch,
            "https://#{gh_read_token}@github.com/consultingmd/dockyard",
            'dockyard',
          )
        end

        def logging_prefix_pipe(logging_prefix, cmd)
          %Q?#{cmd.strip} |& sed -u -e"s/^/[#{logging_prefix}] /"?
        end

        def env_str(env_hash)
          return nil if !env_hash || env_hash.empty?
          env_hash.to_a.map do |k,v|
            v = v.to_s
            if v == ':self'
              v = ENV[k]
            elsif v.start_with?(':')
              v = ENV[v.sub(/\A:/, '')]
            elsif v.start_with?(Pancakes::Fleet::Etcd::URL_SCHEME)
              v = Pancakes.cluster.etcd.get(v)
            end
            format('-e "%s=%s"', k.to_s, v)
          end.join(' ')
        end

        def ports_str(ports)
          return nil if !ports || ports.empty?
          ports.map do |p|
            format('-p %s', p.to_s)
          end.join(' ')
        end

        def volumes_str(volumes)
          return nil if !volumes || volumes.empty?
          volumes.map do |v|
            format('-v %s', v)
          end.join(' ')
        end

        def systemd_minus(cmd)
          "-#{cmd}"
        end

        def bash_and(*cmds)
          cmds.join(' && ')
        end

        def bash_minus_c(cmd)
          "/bin/bash -c '#{cmd}'"
        end

        def join_args(*args)
          args.compact.map(&:to_s).map(&:strip).join(' ').strip
        end

        def docker_cmd(cmd, *args)
          "#{DOCKER} #{cmd} #{join_args(*args)}"
        end

        #def grnds_dns
          #'--dns=8.8.8.8'
        #end

        def docker_run(container_name:, netmaster_name:, environment:, ports:, image:, cmd:)
          docker_cmd(
            :run,
            '--rm',
            '-v', '/var/lib/docker/tmp:/tmp/hosttmp',
            #grnds_dns,
            '--name', container_name,
            (netmaster_name != container_name) ? "--net=container:#{netmaster_name}" : nil,
            env_str(environment),
            ports_str(ports),
            image,
            cmd,
          )
        end

        def freeze_cmd(fname:, mysql_host:, mysql_port:, mysql_dbs:)
          join_args(
            './freezer.sh',
            'freeze',
            '--fname', fname,
            '--bucket-name', 'grnds-development-coreos',
            '--mysql-host', mysql_host,
            '--mysql-port', mysql_port,
            *mysql_dbs.map{|db| ['--mysql-db', db] }.flatten,
          )
        end

        def thaw_cmd(fname:, mysql_host:, mysql_port:)
          join_args(
            './freezer.sh',
            'thaw',
            '--fname', fname,
            '--bucket-name', 'grnds-development-coreos',
            '--mysql-host', mysql_host,
            '--mysql-port', mysql_port,
          )
        end
      end
    end
  end
end
