module Pancakes
  class Stack < Sequel::Model
    include ClassLogger
    include HonestyCluster::SwarmBackend::CargoGroup
    include HonestyCluster::Health::HealthCheckable

    health_check_type 'Pancakes::Stack'

    set_dataset :pancakes_stacks
    plugin :timestamps
    plugin :serialization, :json, :pocs, :services
    plugin :association_dependencies
    plugin :validation_helpers
    plugin :json_serializer

    serialize_attributes :symbolize, :state, :desired_state

    HUMAN_STATES   = %i[off running starting stopping failed]
    CLUSTER_STATES = %i[off running pinging changing incomplete unknown failed]
    DESIRED_STATES = %i[off running]

    one_to_many :commits, key: :stack_id, class: :"Pancakes::Commit"
    one_to_many :units,   key: :stack_id, class: :"Pancakes::Unit"
    one_to_many :events,  key: :stack_id, class: :"HonestyCluster::StatusEvent", order: :created_at

    add_association_dependencies commits: :destroy, units: :destroy

    def validate
      super
      validates_includes   CLUSTER_STATES, :state,         allow_blank: false, allow_nil: false
      validates_includes   DESIRED_STATES, :desired_state, allow_blank: false, allow_nil: false
      validates_min_length 1,              :services,      allow_blank: false, allow_nil: false
      errors.add(:"Owner", 'cannot be empty') if pocs.empty? || pocs[0].empty?
    end

    def before_create
      self.services = self.services.map(&:to_s)
      new_sha
      super
    end

    def before_destroy
      Pancakes::Freezer.delete_stack(self.id)
      self.destroy_containers
      super
    end


    #
    # constructors
    #

    def self.create_with_git_strings(services: Services.full_services, pocs: '', desired_state: :off, branches: nil, **git_strings)
      self.db.transaction do
        pocs = (pocs || "").split(',').map(&:strip)
        me = new(services: services.to_set.to_a, pocs: pocs, desired_state: desired_state)
        me.set_state(:off)
        me.save

        me.services.each do |name|
          me.add_unit(Unit.create_with_service_def(service_def: Services.get(name)))
        end

        git_strings = (branches || {}) if git_strings.nil? || git_strings.empty?
        # dont create Commits for codebases we aren't using for this stack.
        codebases = codebases(me.services)
        git_strings.select! {|cb| codebases.include?(cb.to_s) }

        # figure out which codebases dont have git strings and add nil ones
        required_codebases = services.map{|x| x.split('-') }.select{|x| x.size == 2 }.map(&:first).map(&:to_sym).to_set
        missing_codebases = required_codebases - git_strings.keys.map(&:to_sym)
        missing_codebases.each do |k|
          git_strings[k] = nil
        end

        git_strings.each do |codebase,git_str|
          # TODO validate dynamically: Pancakes.validate_codebase(codebase) || raise("unsupported codebase #{codebase}")
          git_str = 'L+master' if git_str.nil? || git_str.empty?
          me.add_commit(Pancakes::Commit.create_from_git_string(Pancakes.repo_name(codebase), git_str))
        end

        me.initial_health_check!
        me
      end
    end

    # @param branches [Hash] hash like { jarvis: 'master', frick: 'foobar', codebase: 'branch_name' }
    def self.with_branches(branches)
      return nil unless branches && !branches.empty?

      branches = branches.map{|codebase,branch| { repo: Pancakes.repo_name(codebase), branch: branch } }
      # a call to .where has to come before calls to .or
      commits_ref = Pancakes::Commit.select(:stack_id).where(branches.take(1))

      branches.drop(1).each do |branch_conditions|
        commits_ref = commits_ref.or(branch_conditions)
      end

      commits_ref = commits_ref.group(:stack_id).having{ count(:stack_id) =~ branches.size }
      where(id: commits_ref)
    end

    def self.first_with_branches(branches)
      with_branches(branches).first
    end

    def self.codebases(service_names)
      service_names
        .map{ |str| Services.parse_service_name(str) }
        .select{ |str| str.size == 2 }
        .map(&:first)
    end

    # we use a sha so that unit names are never reused, which was causing problems.
    def short_sha
      self.sha ? self.sha[0..6] : (raise "where is the sha???")
    end

    def name
      format("%s_%s_%d", Pancakes::NAMESPACE, self.short_sha, self.id)
    end

    # TODO break this down into smaller pieces. it's also similar in structure to bring_down.
    def bring_up(thaw_dbs: false)
      # pre
      if running?
        logger.info "#{self.name} is already running"
        return false
      end

      dry_run = Pancakes.cluster.dry_run?
      logger.info "bring_up will be a dry run" if dry_run
      StatHatWrapper.pause if dry_run

      StatHatWrapper.post_count('pancakes stacks bring_up started', 1)
      new_sha
      set_all(desired_state: :running, started_at: Time.now, destroyed_at: nil)
      save unless dry_run
      logger.info "bring_up #{self.name}"


      # body

      # TODO doing this for every worker could be pretty inefficient
      Pancakes.cluster.reset_failed_all
      sleep 2

      begin
        nm = netmaster_unit
        Pancakes.cluster.start_template(nm.service_file_name, Pancakes::Fleet::Templating.detect_and_make_template(nm))

        timeout = 60*5

        Pancakes.block_until_values(values: true, timeout: timeout, raise_on_timeout: true) do
          refresh_unit_states
          !nm.refresh.machine_ip.nil?
        end

        Pancakes.docker.set_machine_ip(nm.machine_ip)
        if !Pancakes.docker.block_until_container_running(name: nm.name, timeout: timeout)
          raise Pancakes::ClusterError.new('timeout waiting for netmaster container run')
        end

        Pancakes.cluster.start_template(nm.dumb_sibling_service_file_name, Pancakes::Fleet::Templating.dumb_sibling_template(nm))

        #should_thaw = thaw_dbs && Pancakes::Freezer.stack_exists?(self.id)
        should_thaw = false
        #run_thaw_er if should_thaw

        non_netmaster_units.each do |unit|
          Pancakes.cluster.start_template(unit.service_file_name, Pancakes::Fleet::Templating.detect_and_make_template(unit, setup_db: !should_thaw))
        end

        non_netmaster_units.each do |unit|
          Pancakes.cluster.start_template(unit.dumb_sibling_service_file_name, Pancakes::Fleet::Templating.dumb_sibling_template(unit))
        end

      rescue Pancakes::ClusterError, Pancakes::TimeoutError => e
        # this will never run during a dry_run, so we dont need to worry about re-enabling StatHatWrapper
        StatHatWrapper.post_count('pancakes stacks bring_up errors', 1)
        logger.error "error during bring_up. some units may have been started successfully. class=#{e.class} message='#{e.message}'"
        return false
      end

      StatHatWrapper.unpause if dry_run
      return if dry_run

      timeout = 60*20
      state = block_until_stack_states(states: %i[running failed], timeout: timeout)


      # post
      if state == :running
        orch_time = Time.now - self.started_at
        logger.info "bring_up took #{format('%.1f', orch_time)}s"
        StatHatWrapper.post_value('pancakes stacks bring_up duration', orch_time)
        StatHatWrapper.post_count('pancakes stacks bring_up success', 1)
        return true
      elsif state == :failed
        logger.info "bring_up failed"
        StatHatWrapper.post_count('pancakes stacks bring_up failed', 1)
        return false
      else
        logger.warn "bring_up timed out after #{timeout}s"
        StatHatWrapper.post_count('pancakes stacks bring_up timeouts', 1)
        return false
      end
    end

    def destroy_unit_with_dumb_sibling(unit, setup_db)
      Pancakes.cluster.start_template(unit.service_file_name, Pancakes::Fleet::Templating.detect_and_make_template(unit, setup_db: setup_db))
      Pancakes.cluster.start_template(unit.dumb_sibling_service_file_name, Pancakes::Fleet::Templating.dumb_sibling_template(unit))
    end

    def bring_down(freeze_dbs: false)
      # pre
      if self.state! == :off
        logger.info "bring_down nothing to do for #{self.name}"
        return false
      end

      dry_run = Pancakes.cluster.dry_run?
      logger.info "bring_down will be a dry run" if dry_run
      StatHatWrapper.pause if dry_run

      logger.info "bring_down #{self.name}"
      start_time = Time.now
      update_all(desired_state: :off) unless dry_run
      StatHatWrapper.post_count('pancakes stacks bring_down started', 1)


      # body
      timeout = 60

      except_units(['mysql', 'freezer']).each do |unit|
        Pancakes.cluster.destroy_unit(unit)
      end

      begin
        Pancakes.block_until_values(values: [['mysql'].to_set, Set.new], timeout: timeout) do
          refresh_unit_states
          running_unit_names
        end
      rescue Pancakes::TimeoutError => e
        # this will never run during a dry_run, so we dont need to worry about re-enabling StatHatWrapper
        StatHatWrapper.post_count('pancakes stacks bring_down errors', 1)
        logger.error "error during bring_down. some units may have been started successfully. class=#{e.original.class} message='#{e.message}'"
        return false
      end

      #run_freezer if freeze_dbs

      only_units(['mysql']).each do |unit|
        Pancakes.cluster.destroy_unit(unit)
      end

      StatHatWrapper.unpause if dry_run
      return if dry_run

      state = block_until_stack_states(states: %i[off], timeout: timeout)


      # post
      if state == :off
        now = Time.now
        destroy_time = now - start_time
        logger.info "bring_down took #{format('%.1f', destroy_time)}s"
        StatHatWrapper.post_value('pancakes stacks bring_down duration', destroy_time)
        StatHatWrapper.post_count('pancakes stacks bring_down success', 1)
        set_all(destroyed_at: now)
        return true
      else
        logger.info "bring_down timeout after #{timeout}s"
        StatHatWrapper.post_count('pancakes stacks bring_down timeouts', 1)
        return false
      end
    end

    # @api private
    def run_thaw_er
      logger.info 'thawing databases'
      run_freezer_helper(
        Pancakes::Fleet::Templating.thaw_template(
          freezer_unit: freezer_unit,
          fname:        Pancakes::Freezer.stack_fname(self.id),
          mysql_host:   mysql_unit.machine_ip,
          mysql_port:   mysql_unit.port,
        )
      )
    end

    # @api private
    def run_freezer
      logger.info "freezing databases: #{mysql_dbs.join(', ')}"
      run_freezer_helper(
        Pancakes::Fleet::Templating.freezer_template(
          freezer_unit: freezer_unit,
          fname:        Pancakes::Freezer.stack_fname(self.id),
          mysql_host:   mysql_unit.machine_ip,
          mysql_port:   mysql_unit.port,
          mysql_dbs:    mysql_dbs,
        )
      )
    end

    # @api private
    def run_freezer_helper(templ)
      Pancakes.cluster.start_template(freezer_unit.service_file_name, templ)
      Pancakes.cluster.etcd.watch_unit_for_active_state(freezer_unit.service_file_name, 'inactive', timeout: 30)

      Pancakes.cluster.destroy_unit(freezer_unit)
      # TODO use etcd watch instead of sleep
      sleep 5
      destroy_freezer_unit
    end

    # @api private
    def mysql_dbs
      units.map{|unit| unit.dbs || [] }.reduce(&:+).delete_if{|x| x =~ /\Apg-/ }
    end

    def ports
      units.map{|unit| unit.ports || [] }.reduce(&:+)
    end

    # @api private
    def only_units(names)
      self.units.select{|unit| names.include?(unit.service_name) }
    end

    # @api private
    def except_units(names)
      only_units(all_unit_names - names)
    end

    # @api private
    def all_unit_names
      self.units.map(&:service_name)
    end

    def restart_with_branch_heads
      logger.info 'restarting with branch heads'
      bring_down(freeze_dbs: true)
      logger.info 'doing bring_up for restart with branch heads'
      refresh_commits
      save
      bring_up(thaw_dbs: true)
      logger.info 'done restarting with branch heads'
    end

    def restart_with_same_commits
      logger.info 'restarting with same commits'
      bring_down(freeze_dbs: true)
      logger.info 'doing bring_up for restart with same commits'
      bring_up(thaw_dbs: true)
      logger.info 'done restarting with same commits'
    end

    def refresh_commits
      commits.each do |ci|
        ci.refresh_branch_head
      end
    end

    def jarvis_env
      if unit_named('banyan-server')
        _port = netmaster_unit.container.port_mapping[unit_named('postgres').primary_private_port]
        { 'BANYAN_DATABASE_URL' => format("postgres://root@%s:%d/pg-cache-development", netmaster_unit.machine_ip, _port) }
      else
        {}
      end
    end


    #
    # states
    #

    # states
    # - :off
    # - :running
    # - :starting
    # - :stopping
    # - :failed
    def human_state!
      human_state_helper(state_from_cluster!)
    end

    def human_state
      human_state_helper(state)
    end

    # @api private
    private def human_state_helper(cluster_state)
      if desired_state == :running
        if %i[off].include?(cluster_state)
          :off
        elsif %i[pinging changing].include?(cluster_state)
          :starting
        else
          cluster_state
        end
      elsif desired_state == :off && %i[running changing].include?(cluster_state)
        :stopping
      elsif cluster_state == :unknown
        :failed
      else
        cluster_state
      end
    end


    # states
    # - :running    units nominal and all pingable
    # - :pinging    units nominal and any unpingable
    # - :changing   units state is :changing
    # - :off        no units
    # - :failed     any unit failed
    # - (deprecated) :incomplete something is missing
    # - :unknown    fallback
    def state_from_cluster!
      _units_state = units_state

      new_state =
        if _units_state == :nominal
          if all_services_up?
            logger.info 'pancakes state is running'
            :running
          else
            logger.info 'pancakes state is pinging'
            :pinging
          end
        else
          _units_state
        end

      set_state(new_state)
      save
      new_state
    end
    alias :state! :state_from_cluster!

    # states
    # - :nominal    all active
    # - :off        no units
    # - :changing active | changing | inactive | unit missing
    # - :failed     anything failed
    # - (deprecated) :incomplete something is missing
    # - :unknown    fallback
    # @api private
    def units_state
      refresh_unit_states
      uu = self.units
      states = uu.map(&:state)

      if self.class.has_only_states(states, :off, :inactive)
        logger.debug 'units state is off'
        return :off
      end

      if self.class.has_any_states(states, :failed)
        logger.debug 'units state is failed'
        return :failed
      end

      if self.class.has_any_states(states, :off)
        logger.debug 'units state is changing'
        return :changing
      end

      if self.class.has_only_states(states, :active)
        logger.debug 'units state is nominal'
        return :nominal
      end

      if self.class.has_only_states(states, :active, :inactive, :activating)
        logger.debug 'units state is changing'
        return :changing
      end

      logger.debug 'units state is unknown'
      return :unknown
    end

    # @api private
    def refresh_unit_states
      cluster_units = Pancakes.cluster.pancakes_units.select do |u|
        u.name.start_with?(self.name)
      end
      .reject do |u|
        u.name.match(/dumb_sibling/)
      end
      .map do |u|
        { Unit.parse_unit_name(u.name).service_name => { cluster_unit: u } }
      end
      .reduce(&:merge) || {}

      units.each do |unit|
        cluster_unit = cluster_units[unit.service_name]
        # TODO dry this up

        if !cluster_unit
          logger.debug "no cluster unit for #{unit.name}"
          unit.set_state(:off)
          unit.set_all(cluster_info: {}, machine_ip: nil, port: nil)
          unit.save
          next
        end

        ip = cluster_unit[:cluster_unit].machine_ip
        container = Pancakes.docker.get_container(netmaster_unit.name, ip)

        if !container
          logger.debug "no container for #{unit.name}"
          unit.set_state(:off)
          unit.set_all(cluster_info: {}, machine_ip: nil, port: nil)
          unit.save
          next
        end

        port_map = container.port_mapping
        port = port_map[unit.primary_private_port]
        unit.set_state(cluster_unit[:cluster_unit].active_state)
        unit.set_all(cluster_info: cluster_unit, machine_ip: ip, port: port)
        logger.debug "updating #{unit.name} with cluster unit info <#{unit.state.inspect}>"
        unit.save
      end
    end

    # @api private
    def set_state(new_state)
      new_state = new_state.to_sym
      return if state == new_state
      set_all(state: new_state, state_updated_at: Time.now)
    end

    # @api private
    def new_sha
      set_all(sha: Digest::SHA1.hexdigest(Time.now.to_i.to_s))
      refresh_logger
    end


    #
    # association helpers
    #

    def netmaster_unit
      units_dataset.where(service_name: Pancakes::Services.netmaster).first
    end

    # @api private
    def non_netmaster_units
      # sort setup units to the top
      units_dataset.exclude(service_name: Pancakes::Services.netmaster).to_a
        .sort { |a,b| (a.name['setup'] && -1) || (b.name['setup'] && 1) || 0 }
    end

    # @api private
    def pingable_units
      units_dataset.exclude(ping_url: nil)
    end

    # @api private
    def running_units
      units_dataset.where(state: 'active')
    end

    # @api private
    def running_unit_names
      running_units.map(&:service_name).to_set
    end

    def unit_with_service_name(service_name)
      units_dataset.first(service_name: service_name.to_s)
    end
    alias :unit_named :unit_with_service_name

    def mysql_unit
      unit_named('mysql')
    end

    def commit_for_codebase(codebase)
      commits_dataset.first(repo: Pancakes.repo_name(codebase))
    end

    # @api private
    def add_freezer_unit
      add_unit(Unit.create_with_service_def(service_def: Services.get('freezer')))
    end

    # @api private
    def destroy_freezer_unit
      unit_with_service_name('freezer').destroy
      self.refresh
      nil
    end

    # @api private
    def freezer_unit
      fu = units_dataset.where(service_name: 'freezer').first
      if fu.nil?
        add_freezer_unit
      else
        fu
      end
    end


    #
    # association helpers
    #

    def running?
      human_state == :running
    end

    def off?
      human_state == :off
    end

    def starting?
      human_state == :starting
    end

    def stopping?
      human_state == :stopping
    end

    def failed?
      human_state == :failed
    end

    def all_services_up?
      pingable_units.map do |unit|
        is_service_up?(unit)
      end
      .reduce(true){|memo,val| memo && val }
    end

    def clear_events
      units.each do |unit|
        unit.clear_events
      end

      events_dataset.destroy
    end

    def service_events
      units.map(&:events).flatten.sort{|a,b| a.created_at <=> b.created_at }
    end

    def all_events
      (units.map(&:events).flatten + events).sort{|a,b| a.created_at <=> b.created_at }
    end

    # @api private
    def self.has_only_states(actual, *allowed)
      allowed = Array(allowed)
      actual = actual.map{|s| allowed.include?(s) }.to_set
      return actual.size == 1 && actual.first == true
    end

    # @api private
    def self.has_any_states(states, *query)
      query = Array(query)
      !!states.detect{|s| query.include?(s) }
    end

    private def block_until_stack_states(states:, timeout:)
      Pancakes.block_until_values(obj: self, method: :state_from_cluster!, values: states, timeout: timeout)
    end

    private def is_service_up?(unit)
      name = unit.service_name
      raise "service #{name} is not pingable" unless unit.pingable?
      url = unit.ping_url
      desired_status = unit.ping_http_status

      begin
        if url.start_with?('http')
          resp = if desired_status == 302
            Net::HTTP.get_response(URI(url))
          else
            RestClient::Request.execute(method: :get, url: url, timeout: 5, open_timeout: 5)
          end

          code = resp.code.to_i

          if code == desired_status
            logger.info "service #{name}(#{desired_status}) reached at #{url} (#{code})"
            return true
          else
            logger.info "service #{name}(#{desired_status}) at #{url} is unreachable with #{code}"
            return false
          end
        else
          logger.warn "service #{name} at #{url} cannot be pinged due to url scheme #{url}"
        end
      rescue StandardError => e
        logger.info "service #{name} at #{url} is unreachable due to #{e.class} '#{e.message}'"
        return false
      end
    end

    private def logger_name
      "#{self.class}[#{self.name}]"
    end

    # CargoGroup
    def before_run_containers
      refresh_commits
      clear_service_addrs
    end

    # CargoGroup
    def after_run_containers
      refresh_service_addrs
    end

    # CargoGroup
    def after_destroy_containers
      clear_service_addrs
    end

    # CargoGroup
    def cargo_list
      units.to_a
    end

    # CargoGroup
    def cargo_group_type
      'pancakes-stack'
    end

    # CargoGroup
    def cargo_group_id
      self.id
    end

    def clear_service_addrs
      units_dataset.update(machine_ip: nil, port: nil)
    end

    def refresh_service_addrs
      logger.info 'refreshing service addresses'
      units_with_health_and_container.each do |unit,_,container|
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
      units.map do |unit|
        next(nil) unless unit.tcp_str
        { unit.service_type => unit.tcp_str }
      end
        .compact
        .reduce(&:merge)
    end

    def containers_mapped_by_service_name
      containers.map do |container|
        [
          Pancakes::Unit.parse_unit_name(container.name).service_name,
          container
        ]
      end.to_h
    end

    def units_with_health_and_container
      mapped_containers = containers_mapped_by_service_name
      units.sort do |a,b|
        a.service_name <=> b.service_name
      end
      .map do |unit|
        [
          unit,
          unit.last_health_check_event,
          mapped_containers[unit.service_name]
        ]
      end
    end

    # HealthCheckable
    def current_health
      status_checks = units.map do |unit|
        unit.check_health!
      end
        .compact
        .map(&:to_status)
      HonestyCluster::Health::HealthCheck.new(status_checks, name)
    end
  end
end
