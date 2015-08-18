module Pancakes
  module Fleet
    class Cluster
      include Pancakes::ClassLogger

      SERVICE_TEMPLATES_PATH = './services/templates'
      #SERVICE_TEMPLATE = <<HERE
#[Unit]
#Description=Run %{service_name}
#After=%{after}.service
#Requires=%{after}.service

#[Service]
#TimeoutStartSec=10min
#ExecStartPre=-/usr/bin/docker kill %{service_name}
#ExecStartPre=-/usr/bin/docker rm %{service_name}
#ExecStartPre=/usr/bin/docker pull %{image}
#ExecStart=/usr/bin/docker run --rm -v /var/lib/docker/tmp:/tmp/hosttmp --name %{service_name} %{volumes} %{links} %{envs} %{ports} %{image} %{command}
#ExecStop=/usr/bin/docker stop %{service_name}
#ExecStopPost=/usr/bin/docker rm -f %{service_name}

#[Install]
#WantedBy=local.target

#[X-Fleet]
#%{machine_of}
#MachineMetadata=role=worker
#HERE


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

      def start_build(service_opts)
        units = Pancakes::Fleet::Templating.spec_build_template(service_opts)
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
        dumb_sibling_fname = unit.dumb_sibling_service_file_name

        if !@dry_run
          logger.info "destroying #{unit_fname}, #{dumb_sibling_fname}"
          @client.destroy(unit_fname)
          sleep 0.3
          @client.destroy(dumb_sibling_fname)
          sleep 0.3
        else
          logger.info "dry-run destroying #{unit_fname}, #{dumb_sibling_fname}"
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
        list_machines.select{|m| m['metadata']['role'] == 'worker' }.map{|m| m['primaryIP'] }
      end

      # @api private
      def list_machines
        logger.info 'getting all machines'
        @client.list_machines['machines']
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
    end
  end
end
