module HonestyCluster
  module SwarmBackend
    module Stack
      include DockerUtil
      include SwarmBackend::CargoGroup


      #             ___.   .__  .__
      # ______  __ _\_ |__ |  | |__| ____
      # \____ \|  |  \ __ \|  | |  |/ ___\
      # |  |_> >  |  / \_\ \  |_|  \  \___
      # |   __/|____/|___  /____/__|\___  >
      # |__|             \/             \/

      # CargoGroup
      def before_run_containers
        clear_service_addrs
      end

      # CargoGroup
      def after_run_containers
        refresh_service_addrs
      end

      # CargoGroup
      def after_destroy_containers
        refresh_service_addrs
      end

      # CargoGroup
      def cargo_list
        units.to_a
      end

      # CargoGroup
      def cargo_group_type
        'pancakes-stack'
      end

      # CargoGroup
      def cargo_group_id
        self.id
      end

      def clear_service_addrs
        units_dataset.update(machine_ip: nil, port: nil)
      end

      def refresh_service_addrs
        puts 'refreshing service addresses'

        units_with_health_and_container.each do |unit,_,container|
          if container
            unit.machine_ip = container.ip
            unit.port = container.public_port
          else
            unit.machine_ip = unit.port = nil
          end
          unit.save
        end
        nil
      end

      def service_addrs
        refresh_service_addrs

        units.map do |unit|
          next(nil) unless unit.tcp_str
          { unit.service_type => unit.tcp_str }
        end
          .compact
          .reduce(&:merge)
      end

      def containers_mapped_by_service_name
        containers.map do |container|
          [Pancakes::Unit.parse_unit_name(container.name).service_name, container]
        end.to_h
      end

      def units_with_health_and_container
        mapped_containers = containers_mapped_by_service_name
        units.sort do |a,b|
          a.service_name <=> b.service_name
        end
        .map do |unit|
          [
            unit,
            unit.last_health_check,
            mapped_containers[unit.service_name]
          ]
        end
      end

      def service_containers_nominal?
        units.map(&:"container_nominal?").reduce(true){|memo,val| memo && val}
      end

      def services_healthy?
        units.select(&:"health_checkable?").map do |unit|
          unit.check_health
        end.reduce(true){|memo,val| memo && val}
      end

      def check_health
        refresh_service_addrs
        check_state = true
        msg = nil

        _containers_healthy = service_containers_nominal?
        if !_containers_healthy
          check_state &&= false
          msg = "one or more containers are in a bad state"
        end

        _services_healthy = services_healthy?
        if !_services_healthy
          check_state &&= false
          msg = "one or more services are unhealthy"
        end

        create_health_check_event(check_state ? :complete : :failed, msg)
      end

    end
  end
end
