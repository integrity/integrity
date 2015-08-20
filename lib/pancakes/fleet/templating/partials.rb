module Pancakes
  module Fleet
    module Templating
      module Partials
        extend self
        extend Templating::Helpers

        def in_section(sec, hsh)
          { sec => hsh }
        end

        def unit_section(desc:, requires_service_fname:)
          in_section(
            'Unit',
            {
              'Description' => desc,
              'After'       => requires_service_fname,
              'Requires'    => requires_service_fname,
            }
          )
        end

        def in_service_section(hsh)
          in_section('Service', hsh)
        end

        def timeout_start_sec(timeout)
          in_service_section('TimeoutStartSec' => timeout)
        end

        def restart_always
          in_service_section('Restart' => 'always')
        end

        def execstart(cmd)
           in_service_section('ExecStart' => cmd)
        end

        def docker_execstartpre(container_name:, image_name:)
          in_service_section(
            'ExecStartPre' => [
              systemd_minus(docker_cmd(:kill, container_name)),
              systemd_minus(docker_cmd(:rm, container_name)),
              systemd_minus(docker_cmd(:pull, image_name)),
            ]
          )
        end

        def docker_execstop(container_name:)
          in_service_section(
            'ExecStop' => [
              docker_cmd(:stop, container_name),
            ]
          )
        end

        def docker_execstop_post(container_name:)
          in_service_section(
            'ExecStopPost' => [
              docker_cmd(:rm, '-f', container_name),
            ]
          )
        end

        def install_section
          in_section(
            'Install',
            'WantedBy' => 'local.target',
          )
        end

        def machine_of(machineof)
          in_section(
            'X-Fleet',
            'MachineOf' => machineof,
          )
        end

        def machine_metadata(metadata)
          in_section(
            'X-Fleet',
            'MachineMetadata' => metadata,
          )
        end

        def machine_id(machine_id)
          in_section(
            'X-Fleet',
            'MachineID' => machine_id,
          )
        end

        def global
          in_section(
            'X-Fleet',
            'Global' => 'true',
          )
        end

        def conflicts(conflict)
          in_section(
            'X-Fleet',
            'Conflicts' => conflict,
          )
        end

        def service_type(type)
          in_service_section('Type' => type)
        end

        def remain_after_exit
          in_service_section('RemainAfterExit' => 'true')
        end
      end
    end
  end
end
