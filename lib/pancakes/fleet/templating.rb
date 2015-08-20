module Pancakes
  module Fleet
    module Templating
      extend self
      extend Templating::Helpers
      extend Templating::Partials

      DOCKER = '/usr/bin/docker'

      @@config = Hashie::Mash.new(
        dockyard_branch: 'pancakes',
      )

      def configure
        yield @@config
      end

      def config
        @@config
      end

      module HonestyBuilds
        # @api private
        def service_def_for_spec_build(build_hsh)
          [
            {
              name:  'mysql',
              image: 'grnds/mysql:latest',
              ports: [3306],
              requires: 'docker.service',
              volumes: [
                '/var/lib/docker/tmp:/tmp/hosttmp',
              ],
            },
            {
              #name: "#{build_hsh[:project]}-spec",
              name: 'app',
              image: "grnds/#{build_hsh[:project]}_ci:latest",
              env: {
                'BRANCH' => build_hsh[:branch],
                'SHA' => build_hsh[:sha],
                'BUILD_ID' => build_hsh[:id],
                'GITHUB_READ_TOKEN' => ':self',
                'AWS_ACCESS_KEY_ID' => ':self',
                'AWS_SECRET_ACCESS_KEY' => ':self',
                'AWS_SECRET_KEY' => ':self',
                'SAUCE_USERNAME' => ':self',
                'SAUCE_ACCESS_KEY' => ':self',
                'CALLBACK_URL' => "https://#{ENV['CALLBACK_HOST']}/status.json",
              },
              volumes: [
                '/etc/profile:/mnt/etc/profile',
                '/var/lib/docker/tmp:/tmp/hosttmp',
              ],
              links: [
                'mysql',
              ],
              ports: [12000],
              requires: :mysql,
              machineof: :mysql,
            },
          ]
        end

        def service_def_for_spec_psql_build(build_hsh)
          [
            {
              name:  'db',
              image: 'grnds/postgres:latest',
              ports: [5432],
              requires: 'docker.service',
              volumes: [
                '/var/lib/docker/tmp:/tmp/hosttmp',
              ],
            },
            {
              name: 'app',
              image: "grnds/#{build_hsh[:project]}_ci:latest",
              env: {
                'BRANCH' => build_hsh[:branch],
                'SHA' => build_hsh[:sha],
                'BUILD_ID' => build_hsh[:id],
                'GITHUB_READ_TOKEN' => ':self',
                'AWS_ACCESS_KEY_ID' => ':self',
                'AWS_SECRET_ACCESS_KEY' => ':self',
                'AWS_SECRET_KEY' => ':self',
                'SAUCE_USERNAME' => ':self',
                'SAUCE_ACCESS_KEY' => ':self',
                'CALLBACK_URL' => "https://#{ENV['CALLBACK_HOST']}/status.json",
              },
              volumes: [
                '/etc/profile:/mnt/etc/profile',
                '/var/lib/docker/tmp:/tmp/hosttmp',
              ],
              links: [
                'db',
              ],
              ports: [12000],
              requires: :db,
              machineof: :db,
            },
          ]
        end

        # @api private
        def service_name(service_type, build_hsh)
          "#{build_name(build_hsh)}_#{service_type}"
        end

        # @api private
        def service_file(service_type, build_hsh)
          "#{service_name(service_type, build_hsh)}.service"
        end

        # @api private
        def build_name(build_hsh)
          [:project, :sha, :id].map{|i| build_hsh[i] }.join('_')
        end

        def spec_build_template(build_hsh)
          services =
            if build_hsh[:template_name] == 'spec'
              service_def_for_spec_build(build_hsh)
            elsif build_hsh[:template_name] == 'spec_psql'
              service_def_for_spec_psql_build(build_hsh)
            else
              raise "unknown template type '#{build_hsh[:template]}'"
            end

          services.map do |service_def|
            service_type = service_def[:name]
            service_name = service_name(service_type, build_hsh)
            requires_service_name = service_def[:requires] == 'docker.service' ? service_def[:requires] : service_name(service_def[:requires], build_hsh)
            service_fname = service_file(service_type, build_hsh)

            template_hash =
              if %w(mysql db).include?(service_def[:name])
                spec_db_template(service_name, requires_service_name, service_def)
              else
                spec_docker_template(
                  service_name,
                  requires_service_name,
                  service_def,
                )
              end

            [service_fname, template_hash]
          end
        end

        def spec_docker_template(service_name, requires_service_name, service_def, cmd=nil)
          requires_service_fname = "#{requires_service_name}.service"

          partials = [
            unit_section(desc: "honesty build #{service_name}", requires_service_fname: requires_service_fname),
            timeout_start_sec('10min'),
            docker_execstartpre(container_name: service_name, image_name: service_def[:image]),
            docker_execstop(container_name: service_name),
            docker_execstop_post(container_name: service_name),
            install_section,
            machine_of(requires_service_fname),
          ]

          partials << execstart(
            docker_cmd(
              :run,
              '--rm',
              #grnds_dns,
              volumes_str(service_def[:volumes]),
              '--name', service_name,
              '--link', [requires_service_name, service_def[:requires]].join(':'),
              env_str(service_def[:env]),
              ports_str(service_def[:ports]),
              service_def[:image],
              cmd,
            )
          )

          unify(partials)
        end

        def spec_db_template(service_name, requires_service_name, service_def)
          partials = [
            unit_section(desc: "honesty build #{service_name}", requires_service_fname: requires_service_name),
            timeout_start_sec('10min'),
            docker_execstartpre(container_name: service_name, image_name: service_def[:image]),
            docker_execstop(container_name: service_name),
            docker_execstop_post(container_name: service_name),
            install_section,
            machine_metadata('role=worker'),
          ]

          partials << execstart(
            docker_cmd(
              :run,
              '--rm',
              #grnds_dns,
              volumes_str(service_def[:volumes]),
              '--name', service_name,
              ports_str(service_def[:ports]),
              service_def[:image],
            )
          )

          unify(partials)
        end
      end

      extend HonestyBuilds

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
                  dockyard_clone(Pancakes.gh_read_token, config.dockyard_branch),
                  dockyard_build_sh(
                    sha:               unit.commit.sha,
                    repo:              unit.repo,
                    debug:             Pancakes.dockyard_debug?,
                    branch:            unit.commit.branch,
                    setup_db:          setup_db,
                    service_type:      unit.subtype,
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

        unify(partials)
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

        unify(
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

        unify(
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
            machine_metadata('role=worker'),
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

        unify(partials)
      end

      # @api private
      def unify(partials_list)
        partials_list.compact.reduce{ |config,partial| config_merge(config, partial) }
      end

      # @api private
      def config_merge(base, layer)
        base.merge(layer) do |key,baseval,layerval|
          if baseval.is_a?(Hash) && layerval.is_a?(Hash)
            config_merge(baseval, layerval)
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
