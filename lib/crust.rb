class Crust

  SERVICE_TEMPLATES_PATH = './services/templates'
  SERVICE_TEMPLATE = <<HERE
[Unit]
Description=Run %{service_name}
After=%{after}.service
Requires=%{after}.service

[Service]
ExecStartPre=-/usr/bin/docker kill %{service_name}
ExecStartPre=-/usr/bin/docker rm %{service_name}
ExecStartPre=/usr/bin/docker pull %{image}
ExecStart=/usr/bin/docker run --rm -v /var/lib/docker/tmp:/tmp/hosttmp --name %{service_name} %{volumes} %{links} %{envs} %{ports} %{image} %{command}
ExecStop=/usr/bin/docker kill %{service_name}
ExecStop=/usr/bin/docker rm %{service_name}

[Install]
WantedBy=local.target

[X-Fleet]
%{machine_of}
MachineMetadata=role=worker
HERE

  def initialize(logger:)
    @logger = logger
    @fleet_client  = ::Fleet.new(read_timeout: 10, open_timeout: 10)
  end

  # @api public
  def get_machines
    @fleet_client.list_machines['machines'].map{|m| m['primaryIP'] }
  end

  # @api public
  def start_build(service_opts)
    units = generate_service_files(service_opts)
    units.each do |unit_fname,unit_hash|
      start(unit_fname, unit_hash)
    end
    nil
  end

  # @api public
  def start(unit_fname, unit_hash)
    @fleet_client.submit(unit_fname, unit_hash)
    sleep 0.1
    @fleet_client.load(unit_fname)
    sleep 0.1
    @fleet_client.start(unit_fname)
    sleep 0.1
  end

  # @api private
  def service_name(srv_name, service_opts)
    "#{build_name(service_opts)}_#{srv_name}"
  end

  # @api private
  def service_file(srv_name, service_opts)
    "#{service_name(srv_name, service_opts)}.service"
  end

  # @api private
  def build_name(service_opts)
    [:project, :sha, :id].map{|i| service_opts[i] }.join('_')
  end

  # @api public
  def destroy_build(service_opts)
    units = generate_service_files(service_opts)
    units.each do |unit_fname,unit_hash|
      @fleet_client.destroy(unit_fname)
    end
    true
  rescue Fleet::NotFound
    false
  end

  # @api public
  def get_service_status
    formated_services(@fleet_client.list)
  end


  #####   #####      #    #    #    ##     #####  ######
  #    #  #    #     #    #    #   #  #      #    #
  #    #  #    #     #    #    #  #    #     #    #####
  #####   #####      #    #    #  ######     #    #
  #       #   #      #     #  #   #    #     #    #
  #       #    #     #      ##    #    #     #    ######
  private

  # @api private
  def convert(service_yml_fname, service_opts)
    services = load_yml(service_yml_fname, service_opts)
    I18n.backend.store_translations(:en, {service: SERVICE_TEMPLATE})
    create_service_files(services, service_opts)
  end

  # @api private
  def create_service_files(services, service_opts)
    services.map do |name,service_def|
      locals = create_local_vars(name, service_def, service_opts)
      template_hash = self.class.convert_unit_file_to_fleet_hash_yea_baby(I18n.backend.translate(:en, :service, locals))
      [service_file(name, service_opts), template_hash]
    end
  end

  # @api public
  def self.convert_unit_file_to_fleet_hash_yea_baby(unit_file)
    section_header_re = /\[([a-z\-]+)\]/i
    # oh yea baby
    unit_file
      .lines
      .map(&:chomp)
      .map{|line| line.empty? ? nil : line }
      .compact
      .slice_before(section_header_re)
      .to_a
      .map{|section|
        [
          section.first.match(section_header_re)[1],
          section.drop(1).map{|conf| conf.split('=', 2)}.to_h
        ]
      }.to_h
  end

  # This assumes that all attempted files other than .erb can be parsed as yaml
  # @api private
  def load_yml(template_fname, service_opts)
    case File.extname(template_fname)
    when '.erb'
      parse_erb(template_fname, service_opts)
    else
      YAML.load_file(template_fname)
    end
  end

  # @api private
  def create_local_vars(name, service_def, service_opts)
    service_def = service_def.symbolize_keys
    service_def[:xfleet].symbolize_keys! if service_def[:xfleet]

    image   = service_def[:image]
    command = service_def[:command].present? ? "/bin/bash -c '#{service_def[:command]}'" : ''
    ports   = (service_def[:ports]       || []).map{|port| "-p #{port}"}
    volumes = (service_def[:volumes]     || []).map{|volume| "-v #{volume}"}

    #This assumes that the container names end with their app name
    links   = (service_def[:links]       || []).map{|link| "--link #{service_name(link, service_opts)}:#{link}"}
    envs    = (service_def[:environment] || []).map{|key,value| "-e \"#{key}=#{value}\"" }
    after   = (service_def[:links].present? ? "#{service_name(service_def[:links].last, service_opts)}" : 'docker')
    xfleet  = service_def[:xfleet].present?
    machine = machine_of(service_def, service_opts)

    {
      service_name: service_name(name, service_opts),
      volumes:      volumes.join(' '),
      after:        after,
      links:        links.join(' '),
      envs:         envs.join(' '),
      ports:        ports.join(' '),
      image:        image,
      xfleet:       xfleet,
      command:      command,
      machine_of:   machine
    }
  end

  # @api private
  def machine_of(service_def, service_opts)
    name = service_def[:xfleet][:machineof] rescue nil
    name.present? ? "MachineOf=#{service_file(name, service_opts)}" : ''
  end

  # @api private
  def parse_erb(template_fname, service_opts)
    project, sha, id, branch = [:project, :sha, :id, :branch].map{ |key| service_opts[key] }
    build_name = "#{project}_#{sha}_#{id}"
    read_token = ENV['GITHUB_READ_TOKEN']
    YAML.load(ERB.new(File.read(template_fname.to_s)).result(binding))
  end


  # @api private
  def formated_services(services)
    services = services.select{|s| s[:name].scan(/_/).count == 3}
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
  def generate_service_files(service_opts)
    template_name = service_opts[:template_name]
    template = service_template(template_name)
    convert(template, service_opts)
  end

  # @api private
  def service_template(template_name)
    paths = Dir[SERVICE_TEMPLATES_PATH + '/*']
    Hash[
      paths.map{ |path| [File.basename(path, '.erb'), path] }
    ][template_name]
  end
end
