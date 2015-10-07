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

      def before_run_containers
        clear_service_addrs
      end

      def after_run_containers
        refresh_service_addrs
      end

      def after_destroy_containers
        refresh_service_addrs
      end

      # CargoGroup
      def cargo_list
        self.units.to_a
      end

      # CargoGroup
      def cargo_group_type
      end

      # CargoGroup
      def cargo_group_id
      end

      def clear_service_addrs
        units_dataset.update(machine_ip: nil, port: nil)
      end

      def refresh_service_addrs
        puts 'refreshing service addresses'
        mapped_containers = containers_mapped_by_service_name

        self.units.each do |unit|
          container = mapped_containers[unit.service_name]

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

        self.units.map do |unit|
          next(nil) unless unit.tcp_str
          { unit.service_type => unit.tcp_str }
        end
          .compact
          .reduce(&:merge)
      end

      def service_containers_nominal?
        self.units.map(&:"container_nominal?").reduce(true){|memo,val| memo && val}
      end

      def services_healthy?
        self.units.select(&:"health_checkable?").map do |unit|
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

        create_health_check_event(check_state, msg)
      end

      def create_health_check_event(passed, msg=nil)
        status = passed ? 'HEALTH_CHECK_COMPLETE' : 'HEALTH_CHECK_FAILED'
        self.add_event(source: 'honesty', type: 'Pancakes::Stack::HealthCheck', status: status, status_message: msg)
        return passed
      end

      def last_health_check
        events_dataset.where(type: 'Pancakes::Stack::HealthCheck').reverse_order(:created_at).limit(1).first
      end


      def containers_mapped_by_service_name
        containers.map do |container|
          [Pancakes::Unit.parse_unit_name(container.name).service_name, container]
        end.to_h
      end
    end
  end
end
