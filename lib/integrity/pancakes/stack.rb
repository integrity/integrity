module Integrity
  module Pancakes
    class Stack

      DOCKER_API_PORT = 2375
      STATIC_PREFIX = 'pancakes'
      SERIALNO_PREFIX = 'no'

      SERVICES = {
        mysql: {
          image: 'grnds/mysql',
          net_container: true,
          ports: [3306],
          requires: 'docker.service',
          env: {
            'AWS_ACCESS_KEY_ID'     => ENV['DEV_AWS_ACCESS_KEY_ID'],
            'AWS_SECRET_ACCESS_KEY' => ENV['DEV_AWS_SECRET_ACCESS_KEY'],
            'AWS_SECRET_KEY'        => ENV['DEV_AWS_SECRET_KEY'],
          },
        },
        mailcatcher: {
          image: 'simpledrupalcloud/mailcatcher',
          requires: :mysql,
          machineof: :mysql,
          ports: [25, 80],
        },
        :"frick-server" => {
          repo: 'consultingmd/frick',
          image: 'grnds/frick_ci',
          machineof: :mysql,
          requires: :mysql,
          ports: [10002],
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
          ports: [10001],
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
          ports: [10004],
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
      @cached_all_pancakes_units = nil
      @fleet_client = Fleet.new

      attr_reader :stack_id, :branch_id, :tags, :serialno

      def initialize(branch_id:, frick_commit:, jarvis_commit:, tim_commit:, serialno:, tags: [])
        @branch_id = branch_id
        @commits = {
          frick:  frick_commit,
          jarvis: jarvis_commit,
          tim:    tim_commit,
        }
        @serialno = serialno
        @tags     = tags || []

        @stack_id = nil
        refresh_stack_id
      end

      #
      # logging
      #

      def logger
        Integrity::Pancakes.logger
      end

      def log(level, msg)
        logger.send(level, "[pancakes][#@stack_id] #{msg}")
      end

      def branch_identifier
        format("%s_%s", STATIC_PREFIX, @branch_id)
      end

      def serialno=(value)
        @serialno = value
        refresh_stack_id
      end

      def urls
        self.class.refresh_all_urls!
        br = self.class.all_urls[@branch_id]
        if br && br.has_key?(@serialno)
          br[@serialno][:urls]
        else
          nil
        end
      end

      def is_service_up?(service_name)
        log(:warn, "sorry, can't check mysql") if %i[mysql mailcatcher].include?(service_name.to_sym)
        self.class.refresh_all_urls!
        begin
          resp = RestClient.get("#{url_for_service(service_name)}/status")
          return resp.code == 200
        rescue
          return false
        end
      end

      def all_services_up?
        #%i[jarvis-server tim-server frick-server].map do |service|
        %i[jarvis-server].map do |service|
          is_service_up?(service)
        end
          .reduce(true){|memo,val| memo && val }
      end

      # states
      # - :running    units nominal and jarvis pingable
      # - :starting   units nominal and jarvis unpingable, or units starting
      # - :off        no units
      # - :failed     any unit failed
      # - :incomplete something is missing
      # - :fucked_up  fallback
      def state_of_the_pancakes
        units_state = state_of_my_units

        if units_state == :nominal
          if all_services_up?
            return :running
          else
            return :starting
          end
        else
          return units_state
        end
      end

      def state_of_the_pancakes!
        self.class.refresh_all_pancakes_units!
        #self.class.refresh_all_urls!
        state_of_the_pancakes
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

      def incomplete?
        state_of_the_pancakes == :incomplete
      end

      def fucked_up?
        state_of_the_pancakes == :fucked_up
      end

      def orchestrate_async
        log :info, "orchestration starting"

        # start mysql first since it's sort of more important
        service_hash = detect_and_make_template(:mysql)
        unit_file = gen_unit_file_name(:mysql)
        log :debug, "orchestration submitting #{unit_file}"
        fleet_client.submit(unit_file, service_hash)
        sleep 0.2
        log :debug, "orchestration loading #{unit_file}"
        fleet_client.load(unit_file)
        sleep 0.5

        (service_configuration.keys - [:mysql]).each do |service|
          service_hash = detect_and_make_template(service)
          unit_file = gen_unit_file_name(service)
          log :debug, "orchestration submitting #{unit_file}"
          fleet_client.submit(unit_file, service_hash)
          sleep 0.3
        end

        (service_configuration.keys - [:mysql]).each do |service|
          unit_file = gen_unit_file_name(service)
          log :debug, "orchestration loading #{unit_file}"
          fleet_client.load(unit_file)
          sleep 0.3
        end

        sleep 1

        [:mysql].each do |service|
          unit_file = gen_unit_file_name(service)
          log :debug, "orchestration starting #{unit_file}"
          fleet_client.start(unit_file)
          sleep 0.3
        end

        sleep 2

        %i[mailcatcher jarvis-orchestra tim-orchestra frick-server].each do |service|
          unit_file = gen_unit_file_name(service)
          log :debug, "orchestration starting #{unit_file}"
          fleet_client.start(unit_file)
          sleep 0.3
        end

        sleep 2

        %i{jarvis-server jarvis-delayed_job tim-server tim-delayed_job}.each do |service|
          unit_file = gen_unit_file_name(service)
          log :debug, "orchestration starting #{unit_file}"
          fleet_client.start(unit_file)
          sleep 0.3
        end

        log :info, "orchestration done"
      end

      def detect_and_make_template(service)
        if service == :mysql
          mysql_template
        elsif service == :mailcatcher
          mailcatcher_template
        else
          dockyard_template(service)
        end
      end

      def destroy_async
        my_units.each do |unit|
          unit_name = unit[:name]
          log :info, "orchestration destroying #{unit_name}"
          fleet_client.destroy(unit_name)
          sleep 0.2
        end
      end

      def destroy
        destroy_async
        block_until_desired_pancakes_state(desired_state: :off, timeout: 30)
      end

      # @return see block_until_desired_state_of_method
      #def block_until_desired_units_state(desired_state:, timeout:)
        #block_until_desired_state_of_method(method: :state_of_my_units!, desired_state: desired_state, timeout: timeout)
      #end

      # @return see block_until_desired_state_of_method
      def block_until_desired_pancakes_state(desired_state:, timeout:)
        block_until_desired_state_of_method(method: :state_of_the_pancakes!, desired_state: desired_state, timeout: timeout)
      end

      def dockyard_template(service)
        raise "#{service} is definitely not a service" unless service_configuration.keys.include?(service.to_sym)
        codebase, service_type = service.to_s.split('-')
        service = service.to_sym
        codebase = codebase.to_sym
        conf = service_configuration[service]
        cmd = Integrity::Pancakes::FleetApiTemplateBuilder.dockyard_cmd(
          branch: branch_name_for(codebase),
          sha: sha_for(codebase),
          repo: conf[:repo],
          codebase: codebase,
          service_type: service_type,
          dockyard_source: 'from_github',
          branch_identifier: branch_identifier,
          logging_prefix: logging_prefix_for_service(service),
          gh_read_token: ENV['GITHUB_READ_TOKEN'],
          debug: !!ENV['DOCKYARD_DEBUG'],
        )

        base_template service: service, cmd: cmd, more_env: git_env(codebase)
      end

      def commit_for(codebase)
        @commits[codebase]
      end

      def sha_for(codebase)
        commit_for(codebase).identifier
      end

      def branch_name_for(codebase)
        commit_for(codebase).branch
      end


      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      # public class methods # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

      def self.new_with_branch(branch:, tags: [])
        branch_prj_name = branch.project.name
        jarvis_commit = commit_with_branch_name_or_master(project_name: 'jarvis', branch_name: branch.name, only_head: branch_prj_name == 'jarvis')
        frick_commit  = commit_with_branch_name_or_master(project_name: 'frick', branch_name: branch.name, only_head: branch_prj_name == 'frick')
        tim_commit    = commit_with_branch_name_or_master(project_name: 'tim', branch_name: branch.name, only_head: branch_prj_name == 'tim')

        if !jarvis_commit || !frick_commit || !tim_commit
          Pancakes.logp :warn, "commit was nil jarvis_commit=#{jarvis_commit.inspect} frick_commit=#{frick_commit.inspect} tim_commit=#{tim_commit.inspect}"
          return nil
        end

        new(
          branch_id: branch.id,
          serialno: branch.pancakes_serialno,
          tags: tags,
          frick_commit:  frick_commit,
          jarvis_commit: jarvis_commit,
          tim_commit:    tim_commit,
        )
      end

      def self.all_urls
        return refresh_all_urls! unless @cached_urls
        Pancakes.logp :info, "using cached container urls"
        @cached_urls
      end

      def self.refresh_all_urls!
        worker_ips = all_pancakes_units.map{|unit| unit[:machine_ip] }.to_set
        if worker_ips.empty?
          @cached_urls = {}
          return @cached_urls
        end

        @cached_urls = worker_ips.map do |worker_ip|
          get_urls_for_machine_grouped_by_branch_id!(worker_ip)
        end
        .reduce(&:merge)

        return @cached_urls
      end


      private

      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      # private instance methods # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

      #
      # pancakes
      #

      # @api private
      def refresh_stack_id
        tag_str = @tags.empty? ? '' : "_#{@tags.join('_')}"
        @stack_id = format("%s_%s_%s%d%s", STATIC_PREFIX, @branch_id, SERIALNO_PREFIX, @serialno, tag_str)
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
      def service_configuration
        self.class.service_configuration
      end

      # @api private
      def url_for_service(service_name)
        urls[service_name]
      end

      # @api private
      def logging_prefix_for_service(service)
        "#{STATIC_PREFIX} #@stack_id #{service}"
      end

      # @api private
      # @return true if state was reached, false if there was a timeout
      def block_until_desired_state_of_method(method:, desired_state:, timeout:)
        raise "can't call #{method}" unless respond_to?(method)
        self.class.refresh_all_urls!
        poll_interval = 1
        counter = 1
        start = Time.now

        while (Time.now - start) <= timeout do
          log :debug, "polling for #{desired_state.inspect} #{counter}"

          state = send(method)

          if state == desired_state
            log :debug, "#{method} desired_state #{desired_state.inspect} reached"
            return true
          end

          sleep(poll_interval)
          counter += 1
        end

        log :warn, "timeout of #{timeout}s reached calling #{method} for desired_state #{desired_state.inspect}"
        return false
      end


      #
      # templating
      #

      # @api private
      def base_template(service:, cmd: nil, more_env: {})
        conf = service_configuration[service]
        ports = conf[:net_container] ? self.class.all_ports : nil

        Integrity::Pancakes::FleetApiTemplateBuilder.base_hash(
          cmd: cmd,
          container_name: gen_container_name(service),
          environment: (conf[:env] || {}).merge(more_env),
          image: conf[:image],
          machineof: gen_service_file_name(conf[:machineof]),
          net_container_name: gen_container_name(self.class.net_container),
          ports: ports,
          requires: smart_requires(conf[:requires]),
          oneshot: !!service.to_s['orchestra']
        )
      end

      # @api private
      def smart_requires(dep)
        if service_configuration.keys.include?(dep)
          gen_service_file_name(dep)
        else
          dep
        end
      end

      # @param codebase :jarvis, :frick, :tim, etc. ie, not jarvis-server, tim-orchestra, etc. only the codebase part of the service name.
      # @api private
      def git_env(codebase)
        {
          'BRANCH' => branch_name_for(codebase),
          'SHA'    => sha_for(codebase),
        }
      end

      # @api private
      def mysql_template
        template = base_template service: :mysql
        cmd = Pancakes::FleetApiTemplateBuilder.logging_prefix_pipe(
          logging_prefix_for_service(:mysql),
          "/usr/bin/docker exec #{gen_container_name(:mysql)} /root/freeze.sh #{branch_identifier}"
        )
        template['Service']['ExecStop'].unshift(cmd)
        template
      end

      # @api private
      def mailcatcher_template
        base_template service: :mailcatcher
      end


      #
      # fleet-related
      #

      # @api private
      def fleet_client
        self.class.fleet_client
      end

      # @api private
      def my_units
        self.class.all_pancakes_units.select{|u| u[:name].start_with?(@stack_id) }
      end

      # @api private
      def state_of_my_units!
        self.class.refresh_all_pancakes_units!
        state_of_my_units
      end

      # states
      # - :nominal    all active
      # - :off        no units
      # - :starting   active | inactive
      # - :failed     anything failed
      # - :incomplete something is missing
      # - :fucked_up  fallback
      #
      # @api private
      def state_of_my_units
        expected = service_configuration.keys.map(&:to_s)
        units = my_units

        if units.empty?
          return :off
        end

        unit_names = units.map{ |u| u[:name] }
        # make sure each of the expected services exist
        all_exist = expected.reduce(true){|memo,val| memo && !!unit_names.detect{|name| name.include?(val) } }
        # active state refers to the 'ACTIVE' column when you run 'fleetctl list-units'
        active_states = units.map{ |u| u[:active_state] }

        if !all_exist
          log :warn, "stack is incomplete. expected the following services: <#{expected.sort.join(', ')}> but got units <#{unit_names.sort.join(', ')}>. missing: <#{(expected - unit_names).sort.join(', ')}>"
          return :incomplete
        end

        all_active = active_states.reduce(true){|memo,val| memo && val == 'active' }
        if all_active
          log :debug, "stack is nominal"
          return :nominal
        end

        active_or_inactive = active_states.reduce(true){|memo,val| memo && %w[active inactive activating].include?(val) }
        if active_or_inactive
          log :debug, "stack is starting"
          return :starting
        end

        any_failed = active_states.reduce(false){|memo,val| memo || val == 'failed' }
        if any_failed
          log :warn, "stack failed: #{self.class.unit_states_string(units)}"
          return :failed
        end

        log :warn, "stack is fucked_up with states: #{self.class.unit_states_string(units)}"
        return :fucked_up
      end

      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      # 'private' class methods  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

      # @api private
      def self.all_pancakes_units
        return refresh_all_pancakes_units! unless @cached_all_pancakes_units
        Pancakes.logp :info, "using cached units"
        @cached_all_pancakes_units
      end

      # @api private
      def self.refresh_all_pancakes_units!
        Pancakes.logp :info, "getting latest units from fleet"
        @cached_all_pancakes_units = fleet_client.list.select{|u| u[:name].start_with?(STATIC_PREFIX) }
      end

      # @api private
      def self.get_urls_for_machine_grouped_by_branch_id!(machine_ip)
        Docker.url = "tcp://#{machine_ip}:#{DOCKER_API_PORT}"
        Docker.validate_version!

        Pancakes.logp :info, "getting latest containers from docker on #{machine_ip}"
        network_containers = Docker::Container.all.select do |c|
          parsed_unit_info = parse_unit_name(get_container_name(c))
          !parsed_unit_info.nil? && parsed_unit_info[:service_type]
        end

        if network_containers.empty?
          Pancakes.logp :warn, "no networking containers found on worker with addr #{machine_ip}"
          return {}
        end

        return network_containers.map do |container|
          parsed_unit_info = parse_unit_name(get_container_name(container))
          urls = service_names_mapped_to_public_port_url(container.info['Ports'], machine_ip)

          [
            parsed_unit_info[:branch_id],
            {
              parsed_unit_info[:serialno] => {
                urls: urls,
                worker_ip: machine_ip,
              }
            }
          ]
        end   # reduce [[branch_id, {serialno => {urls:...}}]] to {branch_id => {serialno =>..., serialno =>...}}
        .reduce({}) do |memo,(branch_id,urls)|
          if memo.has_key?(branch_id)
            memo[branch_id] = memo[branch_id].merge(urls)
          else
            memo[branch_id] = urls
          end
          memo
        end
      end

      # @api private
      # @return a hash like { :"jarvis-server" => "http://10.0.80.1:43631", :"frick-server" => ... }
      def self.service_names_mapped_to_public_port_url(docker_ports, machine_ip)
        docker_ports.map do |port_pair|
          public_port, private_port = port_pair['PublicPort'], port_pair['PrivatePort']
          service_name = service_name_with_private_port(private_port)
          service_name ? { service_name => "http://#{machine_ip}:#{public_port}" } : {}
        end
        .reduce(&:merge)
      end

      # @api private
      # @return a symbol like :"jarvis-server" or :"frick-server"
      def self.service_name_with_private_port(private_port)
        service_configuration.each do |name,conf|
          if conf[:ports] && conf[:ports].include?(private_port)
            return name
          end
        end
        return nil
      end

      # @api private
      def self.service_configuration
        SERVICES
      end

      # @api private
      def self.get_container_name(container)
        container.info['Names'].first
      end

      # @api private
      def self.commit_with_branch_name_or_master(project_name:, branch_name:, only_head: false)
        branch = branch_of_project(project_name, branch_name)

        if !branch
          if only_head
            Pancakes.logp :warn, "can't find #{project_name} #{branch_name} and only_head=true"
            return nil
          end

          Pancakes.logp :info, "using #{project_name} master instead of #{branch_name}"
          branch_name = 'master'
          branch = branch_of_project(project_name, branch_name)
        end

        bu = branch.last_build

        if !bu
          Pancakes.logp :warn, "#{project_name} #{branch_name} has nil last_build"
          return nil
        elsif bu.successful?
          ci = bu.commit
          Pancakes.logp :warn, "using last_build commit(#{ci.identifier}) for #{project_name} #{branch_name}"
          return ci
        else
          Pancakes.logp :warn, "#{project_name} #{branch_name} tip commit(#{bu.commit.identifier}) isn't green. using latest green commit instead."
        end

        bu = branch.builds.first(successful: true, order: :completed_at.desc)

        if bu
          ci = bu.commit
          Pancakes.logp :warn, "using last green commit(#{ci.identifier}) for #{project_name} #{branch_name}"
          return ci
        else
          Pancakes.logp :warn, "#{project_name} #{branch_name} has no green commits I can use"
          return nil
        end
      end

      # @api private
      def self.branch_of_project(project_name, branch_name)
        Integrity::Project.first(name: project_name).branches.first(name: branch_name)
      end

      # @api private
      def self.parse_unit_name(unit_name)
        match = unit_name.match((/\/?(?:pancakes)_(?<branch_id>\d+)_no(?<serialno>\d+)(?<tag_string>_\w+)?_(?<service_type>\w+)/))
        if !match
          Pancakes.logp :warn, "unit name '#{unit_name}' didnt match the expected format"
          return nil
        end
        {
          branch_id: match[:branch_id].to_i,
          serialno:  match[:serialno].to_i,
          tags:      (match[:tag_string] || '').split('_').delete_if(&:empty?),
          service_type: match[:service_type],
        }
      end

      # @api private
      def self.fleet_client
        @fleet_client
      end

      # @api private
      def self.net_container
        service_configuration.each_pair do |service,conf|
          if conf[:net_container] == true
            return service
          end
        end

        raise "no net_container is specified"
      end

      # @api private
      def self.all_ports
        service_configuration.to_a.map{|k,v| v[:ports] || [] }.reduce(&:+)
      end

      # @api private
      def self.unit_states_string(units)
        units.map do |unit|
          format('%s<active=%s, sub=%s>', unit[:name], unit[:active_state], unit[:sub_state])
        end
          .join(' ')
      end
    end
  end
end
