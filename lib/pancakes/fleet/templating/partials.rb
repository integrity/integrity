module Pancakes
  module Fleet
    module Templating
      module Partials
        extend self
        extend Templating::Helpers

        def unit_section(service_name:, requires_service_file:)
          {
            'Unit' => {
              'Description' => "pancakes container #{service_name}",
              'After'       => requires_service_file,
              'Requires'    => requires_service_file,
            }
          }
        end

        def timeout_start_sec(timeout)
          {
            'Service' => {
              'TimeoutStartSec' => timeout
            }
          }
        end

        def execstart(cmd)
          {
            'Service' => {
              'ExecStart' => cmd
            }
          }
        end

        def docker_execstartpre(container_name:, image_name:)
          {
            'Service' => {
              'ExecStartPre' => [
                systemd_minus(docker_cmd(:kill, container_name)),
                systemd_minus(docker_cmd(:rm, container_name)),
                docker_cmd(:pull, image_name),
              ]
            }
          }
        end

        def docker_execstop(container_name:)
          {
            'Service' => {
              'ExecStop' => [
                docker_cmd(:stop, container_name),
                docker_cmd(:rm, container_name),
              ]
            }
          }
        end

        def install_section
          {
            'Install' => {
              'WantedBy' => 'local.target'
            }
          }
        end

        def machine_of(machineof)
          {
            'X-Fleet' => {
              'MachineOf' => machineof
            }
          }
        end

        def machine_metadata(metadata)
          {
            'X-Fleet' => {
              'MachineMetadata' => metadata
            }
          }
        end

        def service_type(type)
          {
            'Service' => {
              'Type' => type
            }
          }
        end

        def remain_after_exit
          {
            'Service' => {
              'RemainAfterExit' => 'true'
            }
          }
        end
      end
    end
  end
end
