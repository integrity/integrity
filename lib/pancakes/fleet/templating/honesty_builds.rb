module Pancakes
  module Fleet
    module Templating
      module HonestyBuilds

        def build_templates(build)
          service_defs_for_build(build).map do |service_def|
            [
              dot_service(service_def[:service_name]),
              detect_and_make_build_template(service_def),
            ]
          end
        end



        #####   #####      #    #    #    ##     #####  ######
        #    #  #    #     #    #    #   #  #      #    #
        #    #  #    #     #    #    #  #    #     #    #####
        #####   #####      #    #    #  ######     #    #
        #       #   #      #     #  #   #    #     #    #
        #       #    #     #      ##    #    #     #    ######


        # @api private
        def service_defs_for_build(build)
          if build.datastore == 'mysql'
            mysql_build_service_defs(build)
          elsif build.datastore == 'postgres'
            postgres_build_service_defs(build)
          elsif build.datastore == nil
            build_only_service_defs(build)
          else
            raise "unknown build datastore: #{build.datastore}"
          end
        end

        # @api private
        def detect_and_make_build_template(service_def)
          merge_partials(
            if %w(mysql db).include?(service_def[:name])
              build_db_partials(service_def)
            else
              build_app_partials(service_def)
            end
          )
        end

        # @api private
        def build_shared_partials(service_name, requires_service_fname, image_name)
          [
            unit_section(desc: "honesty build #{service_name}", requires_service_fname: requires_service_fname),
            timeout_start_sec('10min'),
            docker_execstartpre(container_name: service_name, image_name: image_name),
            docker_execstop(container_name: service_name),
            docker_execstop_post(container_name: service_name),
            install_section,
            machine_scheduling_option(requires_service_fname),
          ]
        end

        # @api private
        def build_app_partials(service_def)
          [
            build_shared_partials(service_def[:service_name], service_def[:requires], service_def[:image]),
            execstart(
              docker_cmd(
                :run,
                '--rm',
                #grnds_dns,
                volumes_str(service_def[:volumes]),
                '--name', service_def[:service_name],
                service_def[:link] ? "--link #{docker_link(no_dot_service(service_def[:requires]), service_def[:link])}" : nil,
                env_str(service_def[:env]),
                ports_str(service_def[:ports]),
                service_def[:image],
              )
            ),
          ]
        end

        # @api private
        def build_db_partials(service_def)
          [
            build_shared_partials(service_def[:service_name], service_def[:requires], service_def[:image]),
            execstart(
              docker_cmd(
                :run,
                '--rm',
                #grnds_dns,
                volumes_str(service_def[:volumes]),
                '--name', service_def[:service_name],
                ports_str(service_def[:ports]),
                service_def[:image],
              )
            ),
          ]
        end

        # @api private
        def app_service_def(build: build, requires: nil)
          service_type = 'app'
          service = {
            #name: "#{build.project_name}-spec",
            name: service_type,
            service_name: service_name(build, service_type),
            image: "grnds/#{build.project_name}_ci:latest",
            env: {
              'BRANCH' => build.branch_name,
              'SHA' => build.sha,
              'BUILD_ID' => build.id,
              'GITHUB_READ_TOKEN' => ':self',
              'AWS_ACCESS_KEY_ID' => ':self',
              'AWS_SECRET_ACCESS_KEY' => ':self',
              'AWS_SECRET_KEY' => ':self',
              'SAUCE_USERNAME' => ':self',
              'SAUCE_ACCESS_KEY' => ':self',
              'CALLBACK_URL' => "https://#{callback_host}/status.json",
            },
            volumes: [
              '/etc/profile:/mnt/etc/profile',
              '/var/lib/docker/tmp:/tmp/hosttmp',
            ],
            link: [requires].compact.first,
            ports: [12000],
          }

          if requires
            requires_service_fname = dot_service(service_name(build, requires))
            service.merge(
              requires: requires_service_fname,
              machineof: requires_service_fname,
            )
          else
            service.merge(
              requires: docker_service_fname,
              machineof: requires,
            )
          end
        end

        # @api private
        def mysql_service_def(build)
          service_type = 'mysql'
          {
            name:  service_type,
            service_name: service_name(build, service_type),
            image: 'grnds/mysql:latest',
            ports: [3306],
            requires: docker_service_fname,
            volumes: ['/var/lib/docker/tmp:/tmp/hosttmp']
          }
        end

        # @api private
        def postgres_service_def(build)
          service_type = 'db'
          {
            name:  service_type,
            service_name: service_name(build, service_type),
            image: 'grnds/postgres:latest',
            ports: [5432],
            requires: docker_service_fname,
            volumes: ['/var/lib/docker/tmp:/tmp/hosttmp'],
          }
        end

        # @api private
        def build_only_service_defs(build)
          [
            app_service_def(build: build),
          ]
        end

        # @api private
        def mysql_build_service_defs(build)
          [
            mysql_service_def(build),
            app_service_def(build: build, requires: :mysql),
          ]
        end

        # @api private
        def postgres_build_service_defs(build)
          [
            postgres_service_def(build),
            app_service_def(build: build, requires: :db),
          ]
        end

        # @api private
        def docker_service_fname
          'docker.service'
        end

        # @api private
        def machine_scheduling_option(requires_service_fname)
          if requires_service_fname == docker_service_fname
            machine_metadata('role=worker')
          else
            machine_of(requires_service_fname)
          end
        end

        # @api private
        def callback_host
          ENV['CALLBACK_HOST']
        end

        # @api private
        def service_name(build, service_type)
          "#{build.service_name}_#{service_type}"
        end

        # @api private
        def dot_service(service_name)
          service_name.end_with?('.service') ? service_name : "#{service_name}.service"
        end

        # @api private
        def no_dot_service(service_name)
          service_name.end_with?('.service') ? service_name.sub(/\.service$/, '') : service_name
        end

        # @api private
        def docker_link(container_name, link_name)
          [container_name, link_name].join(':')
        end
      end
    end
  end
end
