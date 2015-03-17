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

    SERVICES = {
      mysql: {
        image: 'grnds/mysql',
        net_container: true,
        ports: [25, 80, 3306, 10001, 10002, 10004],
        requires: 'docker.service',
      },
      mailcatcher: {
        image: 'simpledrupalcloud/mailcatcher',
        requires: :mysql,
        machineof: :mysql,
      },
      :"frick-server" => {
        repo: 'consultingmd/frick',
        image: 'grnds/frick_ci',
        machineof: :mysql,
        requires: :mysql,
        env: {
          'GITHUB_READ_TOKEN'     => ENV['GITHUB_READ_TOKEN'],
          'AWS_ACCESS_KEY_ID'     => ENV['DEV_AWS_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['DEV_AWS_SECRET_ACCESS_KEY'],
          'AWS_SECRET_KEY'        => ENV['DEV_AWS_SECRET_KEY'],
        },
      },
      :"jarvis-orchestra" => {
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :mysql,
        env: {
          'GITHUB_READ_TOKEN'     => ENV['GITHUB_READ_TOKEN'],
          'AWS_ACCESS_KEY_ID'     => ENV['DEV_AWS_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['DEV_AWS_SECRET_ACCESS_KEY'],
          'AWS_SECRET_KEY'        => ENV['DEV_AWS_SECRET_KEY'],
        },
      },
      :"jarvis-server" => {
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-orchestra",
        env: {
          'MAILCATCHER_SMTP_PORT' => 25,
          'GITHUB_READ_TOKEN'     => ENV['GITHUB_READ_TOKEN'],
          'AWS_ACCESS_KEY_ID'     => ENV['DEV_AWS_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['DEV_AWS_SECRET_ACCESS_KEY'],
          'AWS_SECRET_KEY'        => ENV['DEV_AWS_SECRET_KEY'],
        },
      },
      :"jarvis-delayed_job" => {
        image: 'grnds/jarvis_ci',
        repo: 'consultingmd/consultingmd',
        machineof: :mysql,
        requires: :"jarvis-orchestra",
        env: {
          'MAILCATCHER_SMTP_PORT' => 25,
          'GITHUB_READ_TOKEN'     => ENV['GITHUB_READ_TOKEN'],
          'AWS_ACCESS_KEY_ID'     => ENV['DEV_AWS_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['DEV_AWS_SECRET_ACCESS_KEY'],
          'AWS_SECRET_KEY'        => ENV['DEV_AWS_SECRET_KEY'],
        },
      },
      :"tim-orchestra" => {
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :mysql,
        env: {
          'GITHUB_READ_TOKEN'     => ENV['GITHUB_READ_TOKEN'],
          'AWS_ACCESS_KEY_ID'     => ENV['DEV_AWS_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['DEV_AWS_SECRET_ACCESS_KEY'],
          'AWS_SECRET_KEY'        => ENV['DEV_AWS_SECRET_KEY'],
        },
      },
      :"tim-server" => {
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-orchestra",
        env: {
          'GITHUB_READ_TOKEN'     => ENV['GITHUB_READ_TOKEN'],
          'AWS_ACCESS_KEY_ID'     => ENV['DEV_AWS_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['DEV_AWS_SECRET_ACCESS_KEY'],
          'AWS_SECRET_KEY'        => ENV['DEV_AWS_SECRET_KEY'],
        },
      },
      :"tim-delayed_job" => {
        image: 'grnds/tim_ci',
        repo: 'consultingmd/tim',
        machineof: :mysql,
        requires: :"tim-orchestra",
        env: {
          'GITHUB_READ_TOKEN'     => ENV['GITHUB_READ_TOKEN'],
          'AWS_ACCESS_KEY_ID'     => ENV['DEV_AWS_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['DEV_AWS_SECRET_ACCESS_KEY'],
          'AWS_SECRET_KEY'        => ENV['DEV_AWS_SECRET_KEY'],
        },
      },
    }


    @cached_urls = nil
    @fleet_client = Fleet.new

    attr_reader :stack_id, :branch_id, :tags, :serialno
      #:frick_branch, :frick_sha,
      #:jarvis_branch, :jarvis_sha,
      #:tim_branch, :tim_sha

    def initialize(branch_id: nil, frick: nil, jarvis: nil, tim: nil, serialno: nil, tags: [])
      @branch_id = branch_id

      @git_branches = {
        frick:  frick,
        jarvis: jarvis,
        tim:    tim,
      }

      #@frick_branch  = args[:frick][:branch]
      #@frick_sha     = args[:frick][:sha]
      #@jarvis_branch = args[:jarvis][:branch]
      #@jarvis_sha    = args[:jarvis][:sha]
      #@tim_branch    = args[:tim][:branch]
      #@tim_sha       = args[:tim][:sha]

      @serialno      = serialno
      @tags          = tags || []

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
      tag_str = @tags.empty? ? '' : "_#{@tags.join('_')}"
      @stack_id = format("%s_%s_%s%d%s", STATIC_PREFIX, @branch_id, SERIALNO_PREFIX, @serialno, tag_str)
    end

    def serialno=(value)
      @serialno = value
      refresh_stack_id
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

      new(
        branch_id: branch_id,
        serialno: branch.pancakes_serialno,
        tags: tags,
        frick:  { branch: frick_commit.branch,  sha: frick_commit.identifier },
        jarvis: { branch: jarvis_commit.branch, sha: jarvis_commit.identifier },
        tim:    { branch: tim_commit.branch,    sha: tim_commit.identifier },
      )
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
      expected = self.class.expected_services()
      units = my_units

      none_exist = units.size == 0
      if none_exist
        return :off
      end

      unit_names = units.map(&:name)
      # make sure each of the expected services exist
      all_exist = expected.reduce(true){|memo,val| memo && !!unit_names.detect{|name| name.include?(val) } }
      # active state refers to the 'ACTIVE' column when you run 'fleetctl list-units'
      active_states = units.map(&:active)

      if !all_exist
        Integrity.logger.warn "expected the following services: <#{expected.join(', ')}> but got units <#{unit_names.join(', ')}>"
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
      #bake_erb
      #files = service_files
      #Fleetctl.load(files)

      # start mysql first since it's sort of more important
      service_hash = detect_and_make_template(:mysql)
      unit_file = gen_unit_file_name(:mysql)
      fleet_client.submit(unit_file, service_hash)
      sleep 0.2
      fleet_client.load(unit_file)
      sleep 0.5

      (SERVICES.keys - [:mysql]).each do |service|
        service_hash = detect_and_make_template(service)
        unit_file = gen_unit_file_name(service)
        fleet_client.submit(unit_file, service_hash)
        sleep 0.3
      end

      (SERVICES.keys - [:mysql]).each do |service|
        fleet_client.load gen_unit_file_name(service)
        sleep 0.3
      end

      sleep 1

      #round1 = files.select{|f| f.path.include?('mysql') }
      #Fleetctl.start(mysql)
      [:mysql].each do |service|
        fleet_client.start gen_unit_file_name(service)
        sleep 0.3
      end

      sleep 2

      #round2 = files.select{|f| f.path.include?('orchestra') || f.path.include?('mailcatcher') }
      #Fleetctl.start(round2)
      %i[mailcatcher jarvis-orchestra tim-orchestra frick-server].each do |service|
        fleet_client.start gen_unit_file_name(service)
        sleep 0.3
      end

      sleep 2

      #round3 = files.select{|f| !f.path.include?('orchestra') && !f.path.include?('mysql') }
      #Fleetctl.start(round3)
      %i{jarvis-server jarvis-delayed_job tim-server tim-delayed_job}.each do |service|
        fleet_client.start gen_unit_file_name(service)
        sleep 0.3
      end
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
    #def bake_erb
      #github_read_token = ENV['GITHUB_READ_TOKEN']
      #aws_access_key_id = ENV['DEV_AWS_ACCESS_KEY_ID']
      #aws_secret_access_key = ENV['DEV_AWS_SECRET_ACCESS_KEY']
      #aws_secret_key = ENV['DEV_AWS_SECRET_KEY']
      #b = binding

      #mk_out_dir

      #Dir[TEMPLATES_DIR + '/*.erb'].each do |erb_fname|
        #contents = ERB.new(File.read(erb_fname)).result(b)
        #outf = baked_filename(erb_fname)

        #File.open(outf, 'w') do |f|
          #f.puts contents
        #end
      #end

      #service_files
    #end

    #def service_files
      #Dir["#{out_dir}/*.service"].map do |file|
        #File.open(file, 'r')
      #end
    #end

    def detect_and_make_template(service)
      if service == :mysql
        mysql_template
      elsif service == :mailcatcher
        mailcatcher_template
      else
        dockyard_template(service)
      end
    end

    #def service_names
      #%w[mailcatcher frick-server jarvis-dj jarvis-orchestra jarvis-server mysql tim-dj tim-orchestra tim-server].map do |service|
        #{ service.to_sym => gen_container_name(service) }
      #end.reduce(&:merge)
    #end

    def my_units
      #Fleetctl.units.select{|u| u.name.start_with?(@stack_id) }
      fleet_client.list.select{|u| u[:name].start_with?(@stack_id) }
    end

    def destroy
      #unit_names = my_units.map(&:name)
      #if !unit_names.empty?
        #Fleetctl.destroy(*unit_names)
      #end

      my_units.each do |unit|
        fleet_client.destroy(unit[:name])
        sleep 0.2
      end
    end

    def mysql_template
      base_template service: :mysql
    end

    def mailcatcher_template
      base_template service: :mailcatcher
    end

    def dockyard_template(service)
      raise "#{service} is definitely not a service" unless SERVICES.keys.include?(service.to_sym)
      app, dockyard_cmd = service.to_s.split('-')
      service = service.to_sym
      app = app.to_sym
      conf = SERVICES[service]
      cmd = Integrity::FleetApiTemplateBuilder.dockyard_cmd(
        branch: @git_branches[app][:branch],
        gh_read_token: github_read_token,
        repo: conf[:repo],
        dockyard_cmd: dockyard_cmd,
        dockyard_source: 'from_github',
      )

      base_template service: service, cmd: cmd, more_env: git_env(app)
    end


    #
    # class methods
    #

    def self.all_urls
      refresh_all_urls unless @cached_urls
      return @cached_urls
    end

    def self.refresh_all_urls
      #Fleetctl.clear_units
      #units = Fleetctl.units
      units = fleet_client.list

      worker_ips = units.map{|unit| unit[:machine_ip] }.to_set
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


    #
    # private class methods
    #

    private

    # @api private
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

    # @api private
    def self.get_container_name(container)
      container.info['Names'].first
    end

    # @api private
    def self.commit_with_branch_name_or_master(project_name, branch_name)
      branch = branch_of_project(project_name, branch_name)
      if !branch
        branch = branch_of_project(project_name, 'master')
      end
      branch.builds.last.commit
    end

    # @api private
    def self.branch_of_project(project_name, branch_name)
      Integrity::Project.first(name: project_name).branches.first(name: branch_name)
    end

    # @api private
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

    # @api private
    def self.set_docker_api_client_url(addr)
      Docker.url = "tcp://#{addr}:2375"
      Docker.validate_version!
    end

    # @api private
    def self.expected_services
      Dir[TEMPLATES_DIR + '/*.erb'].map { |t| File.basename(t).sub(/\.\w+\.erb$/, '') }
    end

    # @api private
    def self.fleet_client
      @fleet_client
    end


    #
    # private instance methods
    #

    # @api private
    def fleet_client
      self.class.fleet_client
    end

    # @api private
    def mk_out_dir
      FileUtils.mkdir_p out_dir
    end

    # @api private
    def out_dir
      File.join('/tmp', @stack_id)
    end

    # @api private
    def baked_filename(fname)
      File.join(out_dir, "#{@stack_id}_#{File.basename fname.sub(/\.erb$/, '')}")
    end

    # @api private
    def gen_container_name(service)
      return nil unless service
      "#{@stack_id}_#{service}"
    end

    # @api private
    def gen_service_file_name(service)
      return nil unless service
      "#{gen_container_name(service)}.service"
    end
    alias :gen_unit_file_name :gen_service_file_name

    # @api private
    def github_read_token
      ENV['GITHUB_READ_TOKEN']
    end

    # @api private
    def smart_requires(dep)
      if SERVICES.keys.include?(dep)
        gen_service_file_name(dep)
      else
        dep
      end
    end

    # @api private
    def net_container
      :mysql
    end

    # @api private
    def base_template(service:, cmd: nil, more_env: {})
      conf = SERVICES[service]

      Integrity::FleetApiTemplateBuilder.base_hash(
        cmd: cmd,
        container_name: gen_container_name(service),
        environment: (conf[:env] || {}).merge(more_env),
        image: conf[:image],
        machineof: gen_service_file_name(conf[:machineof]),
        net_container_name: gen_container_name(net_container),
        ports: conf[:ports],
        requires: smart_requires(conf[:requires]),
        oneshot: !!service.to_s['orchestra']
      )
    end

    # @param service :jarvis, :frick, :tim
    # @api private
    def git_env(app)
      {
        'BRANCH' => @git_branches[app][:branch],
        'SHA'    => @git_branches[app][:sha],
      }
    end
  end
end
