module HonestyCluster
  module SwarmBackend
    module Stack


      #             ___.   .__  .__
      # ______  __ _\_ |__ |  | |__| ____
      # \____ \|  |  \ __ \|  | |  |/ ___\
      # |  |_> >  |  / \_\ \  |_|  \  \___
      # |   __/|____/|___  /____/__|\___  >
      # |__|             \/             \/

      def swarm_spin_up
        clear_unit_addrs
        self.units.each do |unit|
          unit.run_container_async
        end
        refresh_unit_addrs
      end

      def swarm_destroy
        containers.each do |container|
          puts "removing (with force) container #{container.name}"
          container.remove(force: true)
        end

        refresh_unit_addrs
        nil
      end

      def clear_unit_addrs
        units_dataset.update(machine_ip: nil, port: nil)
      end

      def containers
        Docker::Container.all(
          {
            'all' => 1, # 'all' can't be a symbol key
            filters: SwarmBackend.label_filter('pancakes-stack', self.name),
          },
          SwarmBackend.conn,
        )
      end

      def refresh_unit_addrs
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
        refresh_unit_addrs

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

      def services_ping_success?
        self.units.select(&:"pingable?").map do |unit|
          unit.ping
        end.reduce(true){|memo,val| memo && val}
      end

      def healthy?
        service_containers_nominal? && services_ping_success?
      end


      #              .__               __
      # _____________|__|__  _______ _/  |_  ____
      # \____ \_  __ \  \  \/ /\__  \\   __\/ __ \
      # |  |_> >  | \/  |\   /  / __ \|  | \  ___/
      # |   __/|__|  |__| \_/  (____  /__|  \___  >
      # |__|                        \/          \/

      private def containers_mapped_by_service_name
        containers.map do |container|
          [Pancakes::Unit.parse_unit_name(container.name).service_name, container]
        end.to_h
      end
    end
  end
end
