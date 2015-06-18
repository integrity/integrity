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
        debugger
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
        units = generate_service_files(service_opts)
        units.each do |unit_fname,unit_hash|
          @fleet_client.destroy(unit_fname)
        end
        true
      rescue ::Fleet::NotFound
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
        services = @fleet_client.list.select{|s| s[:name].scan(/_/).count == 3}
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

      # @api private
      #def convert(service_opts)
        ##services = load_yml(service_yml_fname, service_opts)
        #services = service_def_for_spec_build(#TODO)
        #debugger
        ##I18n.backend.store_translations(:en, {service: SERVICE_TEMPLATE})

        #services.map do |name,service_def|
          ##locals = create_local_vars(name, service_def, service_opts)
          ##template_hash = self.class.convert_unit_file_to_fleet_hash_yea_baby(I18n.backend.translate(:en, :service, locals))
          #[service_file(name, service_opts), template_hash]
        #end
      #end

      # converts a flat systemd unit file to ruby data structures
      # ie, this (https://coreos.com/docs/launching-containers/launching/getting-started-with-systemd/) to this (https://github.com/CenturyLinkLabs/fleet-api#service-definitions)
      #
      # @api public
      #def self.convert_unit_file_to_fleet_hash_yea_baby(unit_file)
        #section_header_re = /\[([a-z\-]+)\]/i
        #unit_file
          #.lines
          #.map(&:chomp)
          #.map{|line| line.empty? ? nil : line }
          #.compact
          #.slice_before(section_header_re)
          #.to_a
          #.map{|section|
            #[
              #section.first.match(section_header_re)[1],
              #section.drop(1).map{|conf| conf.split('=', 2)}
                #.reduce({}){|hsh,(k,v)| hsh[k] = hsh[k] ? Array(hsh[k]) << v : v ; hsh }
            #]
          #}.to_h
      #end

      # This assumes that all attempted files other than .erb can be parsed as yaml
      # @api private
      #def load_yml(template_fname, service_opts)
        #case File.extname(template_fname)
        #when '.erb'
          #parse_erb(template_fname, service_opts)
        #else
          #YAML.load_file(template_fname)
        #end
      #end

      # @api private
      #def create_local_vars(name, service_def, service_opts)
        #service_def = service_def.symbolize_keys
        #service_def[:xfleet].symbolize_keys! if service_def[:xfleet]

        #image   = service_def[:image]
        #command = service_def[:command].present? ? "/bin/bash -c '#{service_def[:command]}'" : ''
        #ports   = ((service_def[:ports] || []) + [12000]).map{|port| "-p #{port}"}
        #volumes = (service_def[:volumes]     || []).map{|volume| "-v #{volume}"}

        ##This assumes that the container names end with their app name
        #links   = (service_def[:links]       || []).map{|link| "--link #{service_name(link, service_opts)}:#{link}"}
        #envs    = (service_def[:environment] || []).map{|key,value| "-e \"#{key}=#{value}\"" }
        #after   = (service_def[:links].present? ? "#{service_name(service_def[:links].last, service_opts)}" : 'docker')
        #xfleet  = service_def[:xfleet].present?

        #name = service_def[:xfleet][:machineof] rescue nil
        #machine = name.present? ? "MachineOf=#{service_file(name, service_opts)}" : ''

        #{
          #service_name: service_name(name, service_opts),
          #volumes:      volumes.join(' '),
          #after:        after,
          #links:        links.join(' '),
          #envs:         envs.join(' '),
          #ports:        ports.join(' '),
          #image:        image,
          #xfleet:       xfleet,
          #command:      command,
          #machine_of:   machine
        #}
      #end

      # @api private
      #def parse_erb(template_fname, service_opts)
        #project, sha, id, branch = [:project, :sha, :id, :branch].map{ |key| service_opts[key] }
        #build_name = "#{project}_#{sha}_#{id}"
        #read_token = ENV['GITHUB_READ_TOKEN']
        #YAML.load(ERB.new(File.read(template_fname.to_s)).result(binding))
      #end
    end
  end
end
