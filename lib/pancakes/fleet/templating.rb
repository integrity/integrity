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

      def detect_and_make_template(unit)
        if %w[mysql mailcatcher].include?(unit.service_name)
          base_template(unit)
        else
          dockyard_template(unit)
        end
      end

      def freezer_template(freezer_unit:, mysql_unit:, mysql_dbs:)
        base_template(
          freezer_unit,
          freeze_cmd(
            stack_id:   freezer_unit.stack.id,
            mysql_host: mysql_unit.machine_ip,
            mysql_port: mysql_unit.port,
            mysql_dbs:  mysql_dbs,
          )
        )
      end

      def thaw_template(unit)
        # TODO
      end

      # @api private
      def dockyard_template(unit)
        commit = unit.stack.commit_for_codebase(unit.codebase)

        cmd = dockyard_build_sh(
          sha:               commit.sha,
          repo:              unit.repo,
          debug:             !!ENV['DOCKYARD_DEBUG'],
          branch:            commit.branch,
          setup_db:          true,
          service_type:      unit.subtype,
        )

        cmd = bash_minus_c(
          logging_prefix_pipe(
            unit.name,
            bash_and(
              dockyard_clone(ENV['GITHUB_READ_TOKEN'], config.dockyard_branch),
              cmd,
            )
          )
        )

        base_template(unit, cmd)
      end

      # @api private
      def base_template(unit, cmd=nil)
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
            environment: { 'PANCAKES' => 'true' }.merge(unit.env),
            ports: unit.netmaster? ? unit.stack.ports : nil,
            image: unit.image,
            cmd: cmd,
          )
        )

        if unit.machine_of
          partials << machine_of(unit.machine_of)
        end

        if unit.name.include?('orchestra')
          partials << service_type('oneshot')
          partials << remain_after_exit
        end

        deep_merge(partials)
      end

      # @api private
      def deep_merge(partials_list)
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
