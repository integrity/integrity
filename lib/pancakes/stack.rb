require 'concurrent/async'

module Pancakes

  # A Stack represents a series of instances of services. This kinda seems like it should be split into Stack and Something,
  # where stack represents an instance of N the branches, and Something (Breakfast?) represents a series of Stacks which are
  # created and destroyed in serial for a set of branches.
  #
  # Right now Stack represents both.
  class Stack
    include Concurrent::Async
    include Pancakes::Clients
    extend Pancakes::Clients

    STACK_PREFIX = 'pancakes'
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

    attr_reader :stack_id, :branch_id, :commits, :serialno, :start_time

    # @param branch_id [String,Integer] Tracking number of the stack. This stays the same throughout the lifetime of the stack.
    # @param serialno [Integer] unique identifier for an instance of a stack in a series of stacks
    # @param commits [Hash] a hash of { jarvis: Pancakes::Commit, ... } which represents which
    #   commits the stack is using and the branches they belong to
    def initialize(branch_id:, serialno:, commits:, start_time:nil) # not really used -> , tags: [])
      @branch_id  = branch_id
      @serialno   = serialno
      @commits    = commits
      @start_time = start_time
      #@tags      = tags || []

      @stack_id = nil
      refresh_stack_id
      init_mutex  # must call before using .async
      @state_of_my_units = nil
      @state_of_the_pancakes = nil
    end

    def start_time_as_date
      Time.parse(@start_time)
    end

    #
    # logging
    #

    def logger
      Pancakes.logger
    end

    def log(level, msg)
      logger.send(level, "[pancakes][#@stack_id] #{msg}")
    end

    def branch_identifier
      format("%s_%s", STACK_PREFIX, @branch_id)
    end

    def serialno=(value)
      @serialno = value
      refresh_stack_id
    end

    def serialno_str
      "#{SERIALNO_PREFIX}#{serialno}"
    end

    def tcp_info(service_name=nil)
      stack_info =  self.class.all_tcp_info[@stack_id]
      if stack_info && info = stack_info[:tcp_info]
        if service_name
          info[service_name.to_sym]
        else
          info
        end
      else
        nil
      end
    end

    def service_url(service_name)
      info = tcp_info(service_name)
      if info
        "http://#{info[:host]}:#{info[:port]}"
      else
        nil
      end
    end

    def is_service_up?(service_name)
      log(:warn, "sorry, can't check mysql") if %i[mysql mailcatcher].include?(service_name.to_sym)
      begin
        resp = RestClient.get("#{service_url(service_name)}/status")
        return resp.code == 200
      rescue
        return false
      end
    end

    def all_services_up?
      #%i[jarvis-server].map do |service|
      %i[jarvis-server tim-server frick-server].map do |service|
        result = is_service_up?(service)
        log :info, "#{service} is not up" if !result
        result
      end
      .reduce(true) { |memo,val| memo && val }
    end

    def state_of_the_pancakes
      state_of_the_pancakes! unless @state_of_the_pancakes
      @state_of_the_pancakes
    end

    # states
    # - :running    units nominal and jarvis pingable
    # - :starting   units nominal and jarvis unpingable, or units starting
    # - :off        no units
    # - :failed     any unit failed
    # - :incomplete something is missing
    # - :fucked_up  fallback
    def state_of_the_pancakes!
      units_state = state_of_my_units!

      @state_of_the_pancakes =
        if units_state == :nominal
          if all_services_up?
            log :debug, "pancakes state is running"
            :running
          else
            log :debug, "pancakes state is starting"
            :starting
          end
        else
          units_state
        end
      return @state_of_the_pancakes
    end

    def state_of_my_units
      state_of_my_units! unless @state_of_my_units
      @state_of_my_units
    end

    # states
    # - :nominal    all active
    # - :off        no units
    # - :starting   active | inactive
    # - :failed     anything failed
    # - :incomplete something is missing
    # - :fucked_up  fallback
    def state_of_my_units!
      self.class.refresh_all_pancakes_units!

      expected = service_configuration.keys.map(&:to_s)
      units = my_units

      if units.empty?
        @state_of_my_units = :off
        return @state_of_my_units
      end

      unit_names = units.map{ |u| u[:name] }
      # make sure each of the expected services exist
      all_exist = expected.reduce(true){|memo,val| memo && !!unit_names.detect{|name| name.include?(val) } }
      # active state refers to the 'ACTIVE' column when you run 'fleetctl list-units'
      active_states = units.map{ |u| u[:active_state] }

      if !all_exist
        log :debug, "my_units state is incomplete. expected the following services: <#{expected.sort.join(', ')}> but got units <#{unit_names.sort.join(', ')}>. missing: <#{(expected - unit_names).sort.join(', ')}>"
        @state_of_my_units = :incomplete
        return @state_of_my_units
      end

      all_active = active_states.reduce(true){|memo,val| memo && val == 'active' }
      if all_active
        log :debug, "my_units state is nominal"
        @state_of_my_units = :nominal
        return @state_of_my_units
      end

      active_or_inactive = active_states.reduce(true){|memo,val| memo && %w[active inactive activating].include?(val) }
      if active_or_inactive
        log :debug, "my_units state is starting"
        @state_of_my_units = :starting
        return @state_of_my_units
      end

      any_failed = active_states.reduce(false){|memo,val| memo || val == 'failed' }
      if any_failed
        log :debug, "stack failed: #{self.class.unit_states_string(units)}"
        @state_of_my_units = :failed
        return @state_of_my_units
      end

      log :debug, "my_units state is fucked_up with states: #{self.class.unit_states_string(units)}"
      @state_of_my_units = :fucked_up
      return @state_of_my_units
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

    def as_json(opts={})
      {
        branch_id:  @branch_id,
        serialno:   @serialno,
        start_time: @start_time,
        commits:    @commits.as_json,
      }.stringify_keys
    end

    def self.from_json(json)
      json = json.deep_symbolize_keys
      json[:commits] = json[:commits].map{|k,v| {k => Pancakes::Commit.from_json(v)} }.reduce(&:merge)
      new(json)
    end

    def self.etcd_inspect
      resp = etcd.get('/pancakes', recursive: true)

      print_node = lambda do |node|
        if node.dir == true
          child_keys = node.children.map do |node|
            print_node.call(node)
          end.reduce(&:+)
        end

        inspected_value = node.key

        if inspected_value.end_with?('last_serialno')
          inspected_value = [inspected_value, etcd.get(inspected_value).value]
        end

        return [inspected_value] + (child_keys || [])

      end

      print_node.call(resp.node)
    rescue Etcd::KeyNotFound
      return []
    end

    def self.etcd_clear_all!
      etcd.delete("/#{STACK_PREFIX}", recursive: true)
    end

    def create_async
      async.create
    end

    def create
      log :info, "orchestration starting"
      StatHatWrapper.post_count('pancakes orchestration starts', 1)
      start_time = Time.now
      @start_time = start_time.to_s
      etcd_store_myself

      # start mysql first since it's sort of more important
      service_hash = detect_and_make_template(:mysql)
      unit_file = gen_unit_file_name(:mysql)
      log :debug, "orchestration submitting #{unit_file}"
      fleet.submit(unit_file, service_hash)
      sleep 0.2
      log :debug, "orchestration loading #{unit_file}"
      fleet.load(unit_file)
      sleep 0.5

      (service_configuration.keys - [:mysql]).each do |service|
        service_hash = detect_and_make_template(service)
        unit_file = gen_unit_file_name(service)
        log :debug, "orchestration submitting #{unit_file}"
        fleet.submit(unit_file, service_hash)
        sleep 0.3
      end

      (service_configuration.keys - [:mysql]).each do |service|
        unit_file = gen_unit_file_name(service)
        log :debug, "orchestration loading #{unit_file}"
        fleet.load(unit_file)
        sleep 0.3
      end

      sleep 1

      [:mysql].each do |service|
        unit_file = gen_unit_file_name(service)
        log :debug, "orchestration starting #{unit_file}"
        fleet.start(unit_file)
        sleep 0.3
      end

      sleep 2

      %i[mailcatcher jarvis-orchestra tim-orchestra frick-server].each do |service|
        unit_file = gen_unit_file_name(service)
        log :debug, "orchestration starting #{unit_file}"
        fleet.start(unit_file)
        sleep 0.3
      end

      sleep 2

      %i{jarvis-server jarvis-delayed_job tim-server tim-delayed_job}.each do |service|
        unit_file = gen_unit_file_name(service)
        log :debug, "orchestration starting #{unit_file}"
        fleet.start(unit_file)
        sleep 0.3
      end

      timeout = 60*4
      if block_until_desired_pancakes_state(desired_state: :running, timeout: timeout)
        orch_time = Time.now - start_time
        log :info, "orchestration took #{format('%.1f', orch_time)}s"
        StatHatWrapper.post_value('pancakes orchestration duration', orch_time)
      else
        log :warn, "orchestration timed out after #{timeout}s"
        StatHatWrapper.post_count('pancakes orchestration timeouts', 1)
      end

      nil
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

    def destroy_async(rm_frozen: false)
      async.destroy(rm_frozen: rm_frozen)
    end

    def destroy(rm_frozen: false)
      log :info, 'destroying stack'
      start_time = Time.now
      StatHatWrapper.post_count('pancakes destroys', 1)

      my_units.each do |unit|
        unit_name = unit[:name]
        log :info, "orchestration destroying #{unit_name}"
        fleet.destroy(unit_name)
        sleep 0.2
      end

      timeout = 60
      if block_until_desired_pancakes_state(desired_state: :off, timeout: timeout)
        destroy_time = Time.now - start_time
        log :info, "destroy took #{format('%.1f', destroy_time)}s"
        StatHatWrapper.post_value('pancakes destroy duration', destroy_time)
        StatHatWrapper.post_count('pancakes destroyed', 1)
      else
        log :info, "destroy timeout after #{timeout}s"
        StatHatWrapper.post_count('pancakes destroy timeouts', 1)
      end

      etcd_delete_myself
      async.remove_from_freezer(10) if rm_frozen == true
      nil
    end

    def remove_from_freezer(delay=0)
      sleep(delay)
      log :info, "removing #{self.branch_id} from freezer"
      Pancakes::Freezer.remove(self.branch_identifier)
    end

    def restart_async
      destroy_async
      pk = StackMaker.new_for_restart(self)
      pk.create_async
      pk
    end

    # @return see block_until_desired_state_of_method
    #def block_until_desired_units_state(desired_state:, timeout:)
      #block_until_desired_state_of_method(method: :state_of_my_units!, desired_state: desired_state, timeout: timeout)
    #end

    # @return see block_until_desired_state_of_method
    def block_until_desired_pancakes_state(desired_state:, timeout: 30)
      block_until_desired_state_of_method(method: :state_of_the_pancakes!, desired_state: desired_state, timeout: timeout)
    end

    def dockyard_template(service)
      raise "#{service} is definitely not a service" unless service_configuration.keys.include?(service.to_sym)
      codebase, service_type = service.to_s.split('-')
      service = service.to_sym
      codebase = codebase.to_sym
      conf = service_configuration[service]

      cmd = Pancakes::FleetApiTemplateBuilder.dockyard_cmd(
        branch: commit_for(codebase).branch_name,
        sha: commit_for(codebase).sha,
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
      @commits[codebase.to_sym]
    end


    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # public class methods # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    def self.all
      all_pancakes_units.reduce(Set.new) do |uniq,unit|
        stack_info = parse_unit_name(unit[:name])
        uniq << {branch_id: stack_info[:branch_id], serialno: stack_info[:serialno]}
        uniq
      end
      .map do |stack_info|
        etcd_get_stack(branch_id: stack_info[:branch_id], serialno: stack_info[:serialno])
      end
    end

    def self.all_with_unlocked_branches(branches={})
      all.select do |pk|
        branches.reduce(false) do |memo,br|
          codebase, branch_name = br.to_a
          ci = pk.commit_for(codebase)
          memo || (ci.branch_name == branch_name && !ci.locked?)
        end
      end
    end

    def self.get(branch_id, serialno)
      serialno = parse_serialno(serialno)
      # get all units and get etcd data from their unit names, then find the first one
      #all.detect { |stack| stack.branch_id == branch_id && stack.serialno == serialno  }

      # just get stack info from etcd
      etcd_get_stack(branch_id: branch_id, serialno: serialno)
    end

    def self.get_with_branches(branches)
      sha = Pancakes::StackMaker.branch_names_sha(branches)
      etcd_get_stack(branch_id: sha)
    end

    # @api private
    def self.parse_serialno(serialno)
      serialno.to_s.sub(/^#{SERIALNO_PREFIX}/, '').to_i
    end

    def self.all_tcp_info
      return refresh_all_urls! unless @cached_urls
      #Pancakes.logp :info, "using cached container urls"
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

    def etcd_store_myself
      key = self.class.etcd_sn_path(branch_id: branch_id, serialno: serialno)
      log :info, "storing #{key} in etcd"
      etcd.set(key, value: JSON.dump(as_json))
      self.class.etcd_set_last_sn(branch_id: branch_id, serialno: serialno)
    end
    alias :save :etcd_store_myself


    private

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # private instance methods # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    #
    # pancakes
    #

    # @api private
    def self.etcd_update_last_sn(branch_id: branch_id)
      last_sn = etcd_get_last_sn(branch_id: branch_id)
      etcd_set_last_sn(branch_id: branch_id, serialno: last_sn)
    end

    # @api private
    def self.etcd_set_last_sn(branch_id: branch_id, serialno: serialno)
      key = etcd_last_serialno_path(branch_id: branch_id)
      etcd.set(key, value: serialno)
    end

    # @api private
    def etcd_get_stack
      self.class.etcd_get_stack(branch_id, serialno)
    end

    # @api private
    def etcd_delete_myself
      key = self.class.etcd_sn_path(branch_id: branch_id, serialno: serialno)
      log :info, "deleting stack #{key} from etcd"
      etcd.delete(key)

      #key = self.class.etcd_branch_path(branch_id: branch_id)
      #dir = etcd.get(key)

      #if dir.value == nil && dir.children.empty?
        #log :info, "deleting all stacks in #{key} from etcd"
        #etcd.delete(key, recursive: true)
      #end
    rescue Etcd::KeyNotFound
    end
    public :etcd_delete_myself

    # @api private
    def refresh_stack_id
      #tag_str = @tags.empty? ? '' : "_#{@tags.join('_')}"
      @stack_id = self.class.make_stack_id(@branch_id, @serialno)
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
    def logging_prefix_for_service(service)
      "#{STACK_PREFIX} #@stack_id #{service}"
    end

    # @api private
    # @return true if state was reached, false if there was a timeout
    def block_until_desired_state_of_method(method:, desired_state:, timeout: 30)
      raise "can't call #{method}" unless respond_to?(method)
      poll_interval = 1
      counter = 1
      start = Time.now
      log :debug, "polling for #{desired_state} with timeout=#{timeout}"

      while (Time.now - start) <= timeout do
        log :debug, "polling for #{desired_state} #{counter}"

        state = send(method)

        if state == desired_state
          log :debug, "#{method} desired_state #{desired_state} reached"
          return true
        #elsif state == :failed # TODO this kind of changes the method api, so figure out a better way
          #log :debug, "#{method} failed waiting for desired_state #{desired_state}"
          #return false
        end

        sleep(poll_interval)
        counter += 1
      end

      log :warn, "timeout of #{timeout}s reached calling #{method} for desired_state #{desired_state}"
      return false
    end


    #
    # templating
    #

    # @api private
    def base_template(service:, cmd: nil, more_env: {})
      conf = service_configuration[service]
      ports = conf[:net_container] ? self.class.all_ports : nil

      Pancakes::FleetApiTemplateBuilder.base_hash(
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
        'BRANCH' => commit_for(codebase).branch_name,
        'SHA'    => commit_for(codebase).sha,
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
    def my_units
      self.class.all_pancakes_units.select{|u| u[:name].start_with?(@stack_id) }
    end


    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # 'private' class methods  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # @api private
    def self.all_pancakes_units
      return refresh_all_pancakes_units! unless @cached_all_pancakes_units
      #Pancakes.logp :info, "using cached units"
      @cached_all_pancakes_units
    end

    # @api private
    def self.refresh_all_pancakes_units!
      Pancakes.logp :debug, "getting latest units from fleet"
      @cached_all_pancakes_units = fleet.list.select{|u| is_pancakes_unit?(u[:name]) }
    end

    # @api private
    def self.is_pancakes_unit?(name)
      name.start_with?(STACK_PREFIX)
    end

    # @api private
    def self.get_urls_for_machine_grouped_by_branch_id!(machine_ip)
      Docker.url = "tcp://#{machine_ip}:#{Pancakes::DOCKER_API_PORT}"
      Docker.validate_version!

      Pancakes.logp :debug, "getting latest containers from docker on #{machine_ip}"
      network_containers = Docker::Container.all.select do |container|
        name = get_container_name(container)
        next false if !is_pancakes_unit?(name)
        parsed_unit_info = parse_unit_name(name)
        !parsed_unit_info.nil? && parsed_unit_info[:service_type].to_sym == net_container
      end

      if network_containers.empty?
        Pancakes.logp :warn, "no networking containers found on worker with addr #{machine_ip}"
        return {}
      end

      return network_containers.map do |container|
        parsed_unit_info = parse_unit_name(get_container_name(container))
        tcp_info = service_names_mapped_to_public_port_and_host(container.info['Ports'], machine_ip)

        {
          make_stack_id(parsed_unit_info[:branch_id], parsed_unit_info[:serialno]) => {
            tcp_info: tcp_info,
            worker_ip: machine_ip,
          }
        }
      end
      .reduce(&:merge)
    end

    # @api private
    ## @return a hash like { :"jarvis-server" => "http://10.0.80.1:43631", ... }
    # @return a hash like { :"jarvis-server" => { host: "10.0.80.1", port: 43631 }, ... }
    def self.service_names_mapped_to_public_port_and_host(docker_ports, machine_ip)
      docker_ports.map do |port_pair|
        public_port, private_port = port_pair['PublicPort'], port_pair['PrivatePort']
        service_name = service_name_with_private_port(private_port)
        #service_name ? { service_name => "http://#{machine_ip}:#{public_port}" } : {}
        service_name ? { service_name => { host: machine_ip, port: public_port } } : {}
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
      container.info['Names'].first.sub(/^\//, '')
    end

    # @api private
    def self.parse_unit_name(unit_name)
      #match = unit_name.match((/\/?(?:pancakes)_(?<branch_id>[0-9a-f]+)_no(?<serialno>\d+)(?<tag_string>_\w+)?_(?<service_type>\w+)/))
      match = unit_name.match((/\/?(?:pancakes)_(?<branch_id>[0-9a-f]+)_no(?<serialno>\d+)_(?<service_type>\w+)/))
      if !match
        Pancakes.logp :warn, "unit name '#{unit_name}' didnt match the expected format"
        return nil
      end
      {
        branch_id: match[:branch_id],
        serialno:  match[:serialno].to_i,
        #tags:      (match[:tag_string] || '').split('_').delete_if(&:empty?),
        service_type: match[:service_type],
      }
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

    # @api private
    def self.make_stack_id(branch_id, serialno)
      @stack_id = format("%s_%s_%s%d", STACK_PREFIX, branch_id, SERIALNO_PREFIX, serialno)
    end

    # @api private
    def self.etcd_get_last_sn(branch_id:)
      last_sn = etcd.get(etcd_last_serialno_path(branch_id: branch_id))
      return last_sn.value.to_i

      #branch_resp = etcd.get(etcd_branch_path(branch_id: branch_id) + "/serialnos")

      #if branch_resp.node.dir && !branch_resp.node.children.empty?
        #branch_resp.node.children.map(&:key).sort.last.split('/').last.to_i
      #else
        #nil
      #end
    rescue Etcd::KeyNotFound
      nil
    end

    def self.etcd_get_next_sn(branch_id:)
      (etcd_get_last_sn(branch_id: branch_id) || 0) + 1
    end

    # @api private
    def self.etcd_branch_path(branch_id:)
      "/#{STACK_PREFIX}/#{branch_id}"
    end

    # @api private
    def self.etcd_sn_path(branch_id:, serialno:)
      "#{etcd_branch_path(branch_id: branch_id)}/serialnos/#{serialno}"
    end

    # @api private
    def self.etcd_last_serialno_path(branch_id:)
      "#{etcd_branch_path(branch_id: branch_id)}/last_serialno"
    end

    # If serialno is nil, get the stack with the highest serialno within branch_id.
    #
    # @api private
    def self.etcd_get_stack(branch_id:, serialno: nil)
      if serialno
        resp = etcd.get(etcd_sn_path(branch_id: branch_id, serialno: serialno))

        if resp.value
          from_json JSON.load(resp.value)
        else
          nil
        end
      else
        last_sn = etcd_get_last_sn(branch_id: branch_id)
        last_sn_path = etcd_sn_path(branch_id: branch_id, serialno: last_sn)
        resp = etcd.get(last_sn_path)

        if resp.value
          from_json(JSON.load(resp.value))
        else
          nil
        end
      end
    rescue Etcd::KeyNotFound
      nil
    end
  end
end
