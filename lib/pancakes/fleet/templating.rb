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

      # @api private
      def docker_template(unit, cmd=nil)
        partials = [
          unit_section(service_name: unit.service_name, requires_service_file: unit.requires),
          timeout_start_sec('10min'),
          docker_execstartpre(container_name: unit.name, image_name: unit.image),
          docker_execstop(container_name: unit.name),
          install_section,
          machine_metadata('role=worker'),
        ]

        partials << execstart(
          docker_run(
            container_name: unit.name,
            netmaster_name: unit.stack.netmaster_unit.name,
            environment: {
              'PANCAKES' => 'true',
              'PANCAKES_ID' => unit.stack.id,
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
