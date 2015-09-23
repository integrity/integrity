module Pancakes
  module Fleet
    module Templating
      extend self
      extend Templating::Helpers
      extend Templating::Partials
      extend Templating::HonestyBuilds

      DOCKER = '/usr/bin/docker'

      @@config = Hashie::Mash.new(
        timberland_branch: 'pancakes',
      )

      def configure
        yield @@config
      end

      def config
        @@config
      end

      def detect_and_make_template(unit, setup_db: true)
        if %w[mysql mailcatcher postgres].include?(unit.service_name)
          docker_template(unit)
        elsif unit.commit
          docker_template(
            unit,
            bash_minus_c(
              logging_prefix_pipe(
                unit.name,
                bash_and(
                  timberland_clone(Pancakes.gh_read_token, config.timberland_branch),
                  'cd timberland',
                  timberland(
                    boot_type:    'pancakes',
                    sha:          unit.commit.sha,
                    repo:         unit.repo,
                    debug:        Pancakes.timberland_debug?,
                    branch:       unit.commit.branch,
                    setup_db:     setup_db,
                    service_type: unit.subtype,
                  )
                )
              )
            )
          )
        else
          raise "expected unit #{unit.name} to have a commit"
        end
      end

      def dumb_sibling_template(unit)
        partials = [
          unit_section(desc: "dumb sibling for pancakes container #{unit.service_name}", requires_service_fname: 'docker.service'),
          install_section,
          execstart('/bin/sh -c "while true ; do sleep 1 ; done"'),
          machine_metadata('role=worker'),
        ]

        if unit.service_name == 'mysql'
          partials << conflicts(unit.service_file_name)
        else
          partials << machine_of("#{unit.stack.name}_mysql-dumb_sibling.service")
        end

        merge_partials(partials)
      end

      def freezer_template(freezer_unit:, fname:, mysql_host:, mysql_port:, mysql_dbs:)
        docker_template(
          freezer_unit,
          bash_minus_c(
            logging_prefix_pipe(
              freezer_unit.name,
              freeze_cmd(
                fname:      fname,
                mysql_host: mysql_host,
                mysql_port: mysql_port,
                mysql_dbs:  mysql_dbs,
              )
            )
          )
        )
      end

      def thaw_template(freezer_unit:, fname:, mysql_host:, mysql_port:)
        docker_template(
          freezer_unit,
          bash_minus_c(
            logging_prefix_pipe(
              freezer_unit.name,
              thaw_cmd(
                fname:      fname,
                mysql_host: mysql_host,
                mysql_port: mysql_port,
              )
            )
          )
        )
      end

      def logspout(image_tag)
        unit_name = 'logspout'
        image_name = "gliderlabs/logspout:#{image_tag}"

        merge_partials(
          [
            unit_section(desc: "log log log log log log log log log log", requires_service_fname: 'docker.service'),
            timeout_start_sec('10min'),
            restart_always,
            docker_execstartpre(container_name: unit_name, image_name: image_name),
            # /usr/bin/docker run --rm -v=/var/run/docker.sock:/tmp/docker.sock --hostname="%H" --name=logspout gliderlabs/logspout:latest syslog://173.247.105.172:49166
            execstart(
              docker_cmd(
                :run,
                '--rm',
                '-v', '/var/run/docker.sock:/tmp/docker.sock',
                '--hostname', '"%H"',
                '--name', unit_name,
                image_name,
                'syslog://173.247.105.172:49166',
              )
            ),
            docker_execstop(container_name: unit_name),
            docker_execstop_post(container_name: unit_name),
            global,
          ]
        )
      end

      def metrics(etcdctl_peers, image_tag)
        unit_name = 'metrics'
        image_name = "grnds/metrics:#{image_tag}"

        merge_partials(
          [
            unit_section(desc: 'Metrics v2', requires_service_fname: 'docker.service'),
            timeout_start_sec('10min'),
            restart_always,
            in_service_section('KillSignal' => 'SIGKILL'),
            docker_execstartpre(container_name: unit_name, image_name: image_name),
            execstart(
              bash_minus_c(
                docker_cmd(
                  :run,
                  '--rm',
                  '--name', unit_name,
                  '--hostname', 'metrics',
                  env_str(
                    'METRICS_HOSTNAME' => '%H',
                    'STATHAT_EZ_KEY'   => ':self',
                    'ETCDCTL_PEERS'    => etcdctl_peers,
                    'MACHINE_ID'       => '$(cat /etc/machine-id)'
                  ),
                  image_name,
                )
              )
            ),
            docker_execstop(container_name: unit_name),
            docker_execstop_post(container_name: unit_name),
            global,
          ]
        )
      end

      # @api private
      def docker_template(unit, cmd=nil)
        partials = [
          unit_section(desc: "pancakes container #{unit.service_name}", requires_service_fname: unit.requires),
          timeout_start_sec('10min'),
          docker_execstartpre(container_name: unit.name, image_name: unit.image),
          docker_execstop(container_name: unit.name),
          docker_execstop_post(container_name: unit.name),
          install_section,
          machine_metadata('role=worker'),
        ]

        partials << execstart(
          docker_run(
            container_name: unit.name,
            netmaster_name: unit.stack.netmaster_unit.name,
            environment: {
              'PANCAKES_ID' => unit.stack.id,
              'PANCAKES_SHA' => unit.stack.short_sha,
              'HONESTY_BASE_URL' => Integrity.base_url,
            }.merge(unit.env),
            ports: unit.netmaster? ? unit.stack.ports : nil,
            image: unit.image,
            cmd: cmd,
          )
        )

        partials << machine_of(unit.machine_of) if unit.machine_of

        if unit.name.include?('orchestra')
          partials << service_type('oneshot')
          partials << remain_after_exit
        end

        merge_partials(partials)
      end

      # @api private
      def merge_partials(partials_list)
        partials_list.flatten.compact.reduce do |config,partial|
          merge_partial(config, partial)
        end
      end

      # @api private
      def merge_partial(base, layer)
        base.merge(layer) do |key,baseval,layerval|
          if baseval.is_a?(Hash) && layerval.is_a?(Hash)
            merge_partial(baseval, layerval)
          elsif baseval.is_a?(String) && layerval.is_a?(String)
            layerval
          elsif baseval.is_a?(Array) || layerval.is_a?(Array)
            Array(baseval) + Array(layerval)
          end
        end
      end
    end
  end
end
