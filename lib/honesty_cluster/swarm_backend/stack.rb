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

      def swarm_spin_up
        clear_service_addrs
        self.units.each do |unit|
          unit.run_container
        end
        refresh_service_addrs
      end

      def swarm_destroy
        containers.each do |container|
          puts "removing (with force) container #{container.name}"
          container.force_remove
        end

        refresh_service_addrs
        nil
      end

      def clear_service_addrs
        units_dataset.update(machine_ip: nil, port: nil)
      end

      #def containers
        #Docker::Container.all(
          #{
            #'all' => 1, # 'all' can't be a symbol key
            #filters: SwarmBackend.label_filters('pancakes-stack', self.name),
          #},
          #SwarmBackend.connection,
        #)
      #end

      def containers
        containers_filtered(id_filter, self.id)
      end

      def id_filter
        'pancakes-stack-id'
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

      #              .__               __
      # _____________|__|__  _______ _/  |_  ____
      # \____ \_  __ \  \  \/ /\__  \\   __\/ __ \
      # |  |_> >  | \/  |\   /  / __ \|  | \  ___/
      # |   __/|__|  |__| \_/  (____  /__|  \___  >
      # |__|                        \/          \/

    end
  end
end
