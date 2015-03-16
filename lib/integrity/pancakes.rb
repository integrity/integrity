require 'fileutils'

module Integrity
  class Pancakes

    STATIC_PREFIX = 'pancakes'
    SERIALNO_PREFIX = 'no'
    TEMPLATES_DIR = 'services/templates/server'
    SERVICE_TO_PRIVATE_PORT_MAPPING = {
      3306  => :mysql,
      10001 => :jarvis,
      10002 => :frick,
      10004 => :tim,
    }

    @cached_urls = nil

    attr_reader :stack_id, :branch_id, :tags,
      :frick_branch, :frick_sha,
      :jarvis_branch, :jarvis_sha,
      :tim_branch, :tim_sha

    def initialize(args={})
      @branch_id     = args[:branch_id]
      @frick_branch  = args[:frick][:branch]
      @frick_sha     = args[:frick][:sha]
      @jarvis_branch = args[:jarvis][:branch]
      @jarvis_sha    = args[:jarvis][:sha]
      @tim_branch    = args[:tim][:branch]
      @tim_sha       = args[:tim][:sha]
      serialno       = "#{SERIALNO_PREFIX}#{args[:serialno]}"
      @tags          = args[:tags] || []
      # convention: the serialno tag, which should always be present, is always the first tag
      @tags.unshift(serialno)
      @stack_id      = nil
      @cached_state_of_the_pancakes = nil
      refresh_stack_id
      refresh_state_of_the_pancakes
    end

    def refresh_remote_state
      self.class.refresh_all_urls
      refresh_state_of_the_pancakes
    end

    def refresh_stack_id
      @stack_id = format("%s_%s%s", STATIC_PREFIX, @branch_id, tag_string)
    end

    # @param build must be a jarvis branch
    def self.new_with_jarvis_branch(branch: nil, tags: [])
      branch_id = branch.id
      branch_name = branch.name
      jarvis_commit = branch.most_recent_build.commit
      #jarvis_commit = Integrity::Project.first(name: 'jarvis').branches.first(name: 'dockyard').builds.last.commit
      #frick_branch = Integrity::Project.first(name: 'frick').branches.first(name: 'dockyard')
      #tim_commit = Integrity::Project.first(name: 'tim').branches.first(name: 'dockyard').builds.last.commit
      frick_commit = commit_with_branch_name_or_master('frick', branch_name)
      tim_commit   = commit_with_branch_name_or_master('tim', branch_name)

      new({
        branch_id: branch_id,
        serialno: branch.pancakes_serialno,
        tags: tags,
        frick:  { branch: frick_commit.branch,  sha: frick_commit.identifier },
        jarvis: { branch: jarvis_commit.branch, sha: jarvis_commit.identifier },
        tim:    { branch: tim_commit.branch,    sha: tim_commit.identifier },
      })
    end

    def is_service_up?(service_name)
      Integrity.logger.warn("can't ping mysql") if service_name.to_sym == :mysql
      begin
        resp = RestClient.get("#{self.class.all_urls[@branch_id][:urls][service_name]}/status")
        return resp.code == 200
      rescue
        return false
      end
    end

    def state_of_the_pancakes
      @cached_state_of_the_pancakes
    end

    def running?
      state_of_the_pancakes == :running
    end

    def starting?
      state_of_the_pancakes == :starting
    end

    def failed?
      state_of_the_pancakes == :failed
    end

    def off?
      state_of_the_pancakes == :off
    end

    def fucked_up?
      state_of_the_pancakes == :fucked_up
    end

    # states
    # - :running   units nominal and jarvis pingable
    # - :starting  units nominal and jarvis unpingable, or units starting
    # - :off       no units
    # - :failed    any unit failed
    # - :fucked_up ...
    def refresh_state_of_the_pancakes
      jarvis_up = is_service_up?(:jarvis)
      units_state = state_of_my_units

      @cached_state_of_the_pancakes =
        if units_state == :nominal && jarvis_up
          :running
        elsif units_state == :nominal && !jarvis_up
          :starting
        else
          units_state
        end
      return @cached_state_of_the_pancakes
    end

    # states
    # - :nominal   all active
    # - :off       no units
    # - :starting  active | inactive
    # - :failed    anything failed
    # - :fucked_up fallback
    def state_of_my_units
      expected_services = %w[frick-server jarvis-dj jarvis-orchestra jarvis-server mysql tim-dj tim-orchestra tim-server]
      units = my_units

      none_exist = units.size == 0
      if none_exist
        return :off
      end

      unit_names = units.map(&:name)
      # make sure each of the expected services exist
      all_exist = expected_services.reduce(true){|memo,val| memo && !!unit_names.detect{|name| name.include?(val) } }
      # active state refers to the 'ACTIVE' column when you run 'fleetctl list-units'
      active_states = units.map(&:active)

      if !all_exist
        Integrity.logger.warn "expected the following services: <#{expected_services.join(', ')}> but got units <#{unit_names.join(', ')}>"
        return :fucked_up
      end

      all_active = active_states.reduce(true){|memo,val| memo && val == 'active' }
      if all_active
        return :nominal
      end

      active_or_inactive = active_states.reduce(true){|memo,val| memo && %w[active inactive activating].include?(val) }
      if active_or_inactive
        return :starting
      end

      any_failed = active_states.reduce(false){|memo,val| memo || val == 'failed' }
      if any_failed
        return :failed
      end

      Integrity.logger.warn "something isn't right with unit states"
      return :fucked_up
    end

    #def self.jarvis_build_at_branch(branch_name)
      #Integrity::Project.first(name: 'jarvis').branches.first(name: branch_name).builds.last
    #end

    def orchestrate
      bake_erb
      Fleetctl.load(service_files)

      mysql = service_files.select{|f| f.path.include?('mysql') }
      Fleetctl.start(mysql)

      sleep 5

      orchs = service_files.select{|f| f.path.include?('orchestra') }
      Fleetctl.start(orchs)

      sleep 5

      other = service_files.select{|f| !f.path.include?('orchestra') && !f.path.include?('mysql') }
      Fleetctl.start(other)
    end

    # locals/methods needed by the ERB rendering context
    # - stack_id
    # - jarvis_branch
    # - jarvis_sha
    # - frick_branch
    # - frick_sha
    # - tim_branch
    # - tim_sha
    # - github_read_token
    # - aws_access_key_id
    # - aws_secret_access_key
    # - aws_secret_key
    def bake_erb
      github_read_token = ENV['GITHUB_READ_TOKEN']
      aws_access_key_id = ENV['DEV_AWS_ACCESS_KEY_ID']
      aws_secret_access_key = ENV['DEV_AWS_SECRET_ACCESS_KEY']
      aws_secret_key = ENV['DEV_AWS_SECRET_KEY']
      b = binding

      mk_out_dir

      Dir[TEMPLATES_DIR + '/*.erb'].each do |erb_fname|
        contents = ERB.new(File.read(erb_fname)).result(b)
        outf = baked_filename(erb_fname)

        File.open(outf, 'w') do |f|
          f.puts contents
        end
      end

      service_files
    end

    def service_files
      Dir["#{out_dir}/*.service"].map do |file|
        File.open(file, 'r')
      end
    end

    #def get_urls
      #Fleetctl.clear_units
      #units = Fleetctl.units

      ## since all containers in a stack run on the same machine, we can get the worker ip from the first one
      #servers = units.select{|u| u.name.include?(@stack_id) && u.name.include?('-server.') }
      #if !servers.empty?
        #worker_ip = servers.first.ip
      #else
        #return nil
      #end

      #setup_docker_api_client(worker_ip)
      #net_cont_name = gen_container_name('mysql')

      #begin
        #net_container = Docker::Container.get(net_cont_name)
        #@cached_urls = net_container.info['NetworkSettings']['Ports'].to_a.map do |service_port,host_ports|
          #{ SERVICE_TO_PRIVATE_PORT_MAPPING[service_port.to_i] => format("http://%s:%d", worker_ip, host_ports.first['HostPort'].to_i) }
        #end
          #.reduce(&:merge)
        #return @cached_urls
      #rescue Docker::Error::NotFoundError => e
        #Integrity.logger.warn "networking container not found: #{net_cont_name}"
        #return nil
      #end
    #end

    def self.all_urls
      refresh_all_urls unless @cached_urls
      return @cached_urls
    end

    def self.refresh_all_urls
      Fleetctl.clear_units
      units = Fleetctl.units

      worker_ips = units.map(&:ip).to_set
      if worker_ips.empty?
        @cached_urls = {}
        return @cached_urls
      end

      @cached_urls = worker_ips.map do |worker_ip|
        get_urls_for_machine_by_branch_id(worker_ip)
      end
      .reduce(&:merge)

      return @cached_urls
    end

    def my_units
      Fleetctl.clear_units
      Fleetctl.units.select{|u| u.name.start_with?(@stack_id) }
    end

    def destroy
      unit_names = my_units.map(&:name)
      if !unit_names.empty?
        Fleetctl.destroy(*unit_names)
      end
    end

    private

    #
    # private class methods
    #

    def self.get_urls_for_machine_by_branch_id(ip)
      set_docker_api_client_url(ip)
      mysql_containers = Docker::Container.all.select{|c| get_container_name(c).match(/mysql/) }

      if mysql_containers.empty?
        Integrity.logger.warn "no networking containers found on worker with addr #{ip}"
        return {}
      end

      return mysql_containers.map do |container|
        unit_info = parse_unit_name(get_container_name(container))
        ports = container.info["Ports"].map do |ports|
          service = SERVICE_TO_PRIVATE_PORT_MAPPING.fetch(ports['PrivatePort'])
          { service => "http://#{ip}:#{ports['PublicPort']}" }
        end
        .reduce(&:merge)
        {
          unit_info[:branch_id] =>
            { urls: ports,
              worker_ip: ip,
            }
        }
      end
      .reduce(&:merge)
    end

    def self.get_container_name(container)
      container.info['Names'].first
    end

    def self.commit_with_branch_name_or_master(project_name, branch_name)
      branch = branch_of_project(project_name, branch_name)
      if !branch
        branch = branch_of_project(project_name, 'master')
      end
      branch.builds.last.commit
    end

    def self.branch_of_project(project_name, branch_name)
      Integrity::Project.first(name: project_name).branches.first(name: branch_name)
    end

    def self.parse_unit_name(unit_name)
      match = unit_name.match((/\/?(?:pancakes)_(?<branch_id>\d+)_no(?<serialno>\d+)(?<tag_string>_\w+)?_(?<service>\w+)/))
      raise "unit name '#{unit_name}' didnt match the expected format" unless match
      {
        branch_id: match[:branch_id].to_i,
        serialno:  match[:serialno].to_i,
        tags:      (match[:tag_string] || '').split('_').delete_if(&:empty?),
        service:   match[:service],
      }
    end

    def self.set_docker_api_client_url(addr)
      Docker.url = "tcp://#{addr}:2375"
      Docker.validate_version!
    end

    #
    # private instance methods
    #

    def tag_string
      return '' if tags.empty?
      "_#{tags.join('_')}"
    end

    def mk_out_dir
      FileUtils.mkdir_p out_dir
    end

    def out_dir
      File.join('/tmp', @stack_id)
    end

    def baked_filename(fname)
      File.join(out_dir, "#{@stack_id}_#{File.basename fname.sub(/\.erb$/, '')}")
    end

    def gen_container_name(service)
      "#{@stack_id}_#{service}"
    end
  end
end
