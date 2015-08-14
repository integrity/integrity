module Pancakes
  module Fleet
    class Cluster
      include Pancakes::ClassLogger

      SERVICE_TEMPLATES_PATH = './services/templates'
      BUILD_REGEX = /\A(?<build>\w+_[0-9a-f]{7}_\d+)_(?<type>\w+)\.service\z/

      attr_reader :client, :etcd
      attr_writer :dry_run

      def initialize(dry_run: false)
        @dry_run = dry_run
        @client = ::Fleet.new(read_timeout: 10, open_timeout: 10)
        @etcd   = Pancakes::Fleet::Etcd.new
      end

      def dry_run?
        @dry_run
      end

      def next_available_machine_for_build
        mach_and_builds = running_builds_grouped_by_machine.detect{ |machine,builds| builds.size < machine.max_builds }
        if mach_and_builds
          mach_and_builds.first
        else
          nil
        end
      end

      def start_build(service_opts, machine_id)
        units = Pancakes::Fleet::Templating.spec_build_template(service_opts, machine_id)
        units.each do |unit_fname,unit_hash|
          start_template(unit_fname, unit_hash)
        end
        nil
      end

      def start_template(unit_fname, unit_hash)
        if !@dry_run
          logger.debug "submitting #{unit_fname}"
          @client.submit(unit_fname, unit_hash)

          sleep 0.1

          logger.debug "loading #{unit_fname}"
          @client.load(unit_fname)

          sleep 0.1

          logger.info "starting #{unit_fname}"
          @client.start(unit_fname)

          sleep 0.1
        else
          logger.info "dry-run starting #{unit_fname}"
          logger.debug "\n" + unit_hash.ai
        end
      rescue ::Fleet::Conflict => e
        raise Pancakes::ClusterError.new_with_original(e)
      end

      def destroy_build(service_opts)
        units = Pancakes::Fleet::Templating.spec_build_template(service_opts)
        units.each do |unit_fname,_|
          logger.info "method=destroy_build #{unit_fname}"
          @client.destroy(unit_fname)
        end
        true
      rescue ::Fleet::NotFound => e
        logger.info "method=destroy_build #{e.class}"
        false
      end

      def destroy_unit(unit)
        unit_fname = unit.service_file_name

        if !@dry_run
          logger.info "destroying #{unit_fname}"
          @client.destroy(unit_fname)
          sleep 0.3
        else
          logger.info "dry-run destroying #{unit_fname}"
        end
      rescue ::Fleet::NotFound => e
        logger.info "unit #{unit.name} not found during destroy. that's fine, we want it gone"
      end

      # @api private
      def reset_failed(host)
        if !@dry_run
          logger.info "calling systemctl reset-failed on #{host}"
          system("ssh core@#{host} sudo systemctl reset-failed")
          StatHatWrapper.post_count('pancakes fleet cluster reset-failed calls', 1)
        else
          logger.info "dry_run calling but not really systemctl reset-failed on #{host}"
        end
      end

      def reset_failed_all
        worker_machine_ips.each do |ip|
          reset_failed(ip)
        end
      end

      def worker_machine_ips
        worker_machines.map(&:ip)
      end

      def worker_machines
        list_machines.select(&:worker?)
      end

      def worker_machines_by_ip
        worker_machines.map{|e| {e.ip => e}}.reduce(&:merge)
      end

      def list_machines
        logger.info 'getting all machines'
        @client.list_machines['machines'].map{|e| Pancakes::Fleet::Machine.new(e) }
      end

      def all_units
        logger.info 'getting all units'
        @client.list.select{|u| Unit.pancakes_unit?(u[:name]) }.map{|u| Hashie::Mash.new(u) }
      end

      # @api public
      def get_service_status
        services = @client.list.select{|s| s[:name].scan(/_/).count == 3}
        services.each do|service|
          app, sha, id, type = service[:name].split("_")
          type = type.split(".").first
          {app: app, sha: sha, id: id, type: type}.each do |k,v|
            service[k] = v
          end
        end
        services.each{|s| s[:id] = s[:name].split("_")[2] }
        ids = services.map{|s| s[:id]}.uniq.compact

        id_sha = {}
        ids.each do |id|
          id_sha[id] = services.select{|s| s[:id] == id}
        end
        id_sha
      end

      def running_build_count_by_machine
        running_builds_grouped_by_machine.map{|machine,builds| [machine.ip, builds.size] }
      end

      def running_builds_grouped_by_machine
        running_builds.group_by do |_,v|
          v[:machine]
        end
      end

      def running_builds_grouped_by_machine_test
        {
          { "ip" => "10.0.80.21", "id" => "929cdd95fdb6486eb0739c469dcefb6b", "metadata" => { "role" => "worker" } } => [
            [
              "jarvis_281dd2c_12340",
              {
                :units => [
                  {
                    :name => "jarvis_281dd2c_12340_app.service",
                    :load_state => "loaded",
                    :active_state => "active",
                    :sub_state => "running",
                    :machine_id => "929cdd95fdb6486eb0739c469dcefb6b",
                    :machine_ip => "10.0.80.21"
                  },
                  {
                    :name => "jarvis_281dd2c_12340_mysql.service",
                    :load_state => "loaded",
                    :active_state => "active",
                    :sub_state => "running",
                    :machine_id => "929cdd95fdb6486eb0739c469dcefb6b",
                    :machine_ip => "10.0.80.21"
                  }
                ],
                :unit_types => [
                  "app",
                  "mysql"
                ],
                :machine => {
                  "ip" => "10.0.80.21",
                  "id" => "929cdd95fdb6486eb0739c469dcefb6b",
                  "metadata" => {
                    "role" => "worker"
                  }
                }
              }
            ],
            [
              "jarvis_7fb4966_12338",
              {
                :units => [
                  {
                    :name => "jarvis_7fb4966_12338_app.service",
                    :load_state => "loaded",
                    :active_state => "active",
                    :sub_state => "running",
                    :machine_id => "929cdd95fdb6486eb0739c469dcefb6b",
                    :machine_ip => "10.0.80.21"
                  },
                  {
                    :name => "jarvis_7fb4966_12338_mysql.service",
                    :load_state => "loaded",
                    :active_state => "active",
                    :sub_state => "running",
                    :machine_id => "929cdd95fdb6486eb0739c469dcefb6b",
                    :machine_ip => "10.0.80.21"
                  }
                ],
                :unit_types => [
                  "app",
                  "mysql"
                ],
                :machine => {
                  "ip" => "10.0.80.21",
                  "id" => "929cdd95fdb6486eb0739c469dcefb6b",
                  "metadata" => {
                    "role" => "worker"
                  }
                }
              }
            ]
          ],
          { "ip" => "10.0.80.31", "id" => "9449eeba7df8464cb876f8c86712a3e8", "metadata" => { "role" => "worker" } } => [
            [
              "jarvis_abda3c6_12341",
              {
                :units => [
                  {
                    :name => "jarvis_abda3c6_12341_app.service",
                    :load_state => "loaded",
                    :active_state => "active",
                    :sub_state => "running",
                    :machine_id => "9449eeba7df8464cb876f8c86712a3e8",
                    :machine_ip => "10.0.80.31"
                  },
                  {
                    :name => "jarvis_abda3c6_12341_mysql.service",
                    :load_state => "loaded",
                    :active_state => "active",
                    :sub_state => "running",
                    :machine_id => "9449eeba7df8464cb876f8c86712a3e8",
                    :machine_ip => "10.0.80.31"
                  }
                ],
                :unit_types => [
                  "app",
                  "mysql"
                ],
                :machine => {
                  "ip" => "10.0.80.31",
                  "id" => "9449eeba7df8464cb876f8c86712a3e8",
                  "metadata" => {
                    "role" => "worker"
                  }
                }
              }
            ]
          ]
        }.map{|m,b| [Pancakes::Fleet::Machine.new(m), b] }.to_h
      end

      def running_builds
        machines = worker_machines_by_ip
        client.list.select do |unit|
          unit[:name] =~ BUILD_REGEX && unit[:active_state] == 'active' && unit[:sub_state] == 'running'
        end
        .reduce({}) do |memo,unit|
          match = unit[:name].match(BUILD_REGEX)
          build, type = match[:build], match[:type]
          memo[build] ||= { units: [], unit_types: [], machine: machines[unit[:machine_ip]] }
          memo[build][:units] << unit
          memo[build][:unit_types] << type
          memo
        end
        .select do |build,info|
          info[:unit_types].sort == %w[app mysql] || info[:unit_types].sort == %w[app db]
        end
      end
    end
  end
end
