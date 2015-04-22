module Pancakes
  class Stack
    include Mongoid::Document
    include Mongoid::Timestamps

    STATES = %i[off running starting incomplete unknown failed]

    field :sha,              type: String
    field :started_at,       type: Time
    field :destroyed_at,     type: Time
    field :state,            type: Symbol, default: :off
    field :state_updated_at, type: Time
    field :desired_state,    type: Symbol
    field :pocs,             type: Array
    field :services,         type: Array, default: []
    field :history,          type: Array, default: []

    embeds_many :commits, class_name: 'Pancakes::Commit', inverse_of: :stack do
      def for_codebase(cb)
        where(repo: Pancakes.repo_name(cb)).first
      end
    end

    embeds_many :units, class_name: 'Pancakes::Unit', inverse_of: :stack do
      def with_service_name(name)
        where('service_def.name' => name.to_s).first
      end

      def pingable
        exists('service_def.ping_url' => true)
      end

      def netmaster
        where('service_def.name' => Services.netmaster).first
      end

      def non_netmaster
        ne('service_def.name' => Services.netmaster)
      end
    end

    validates :state, inclusion: { in: STATES }, allow_blank: false, allow_nil: false
    validates :services, length: { minimum: 1 }, allow_blank: false, allow_nil: false
    validates :commits, associated: true
    validates :units, associated: true

    before_create do |doc|
      self.services = self.services.map(&:to_s)
      doc.new_sha
    end

    def self.create_with_git_strings(services: Services.all_names, pocs: [], default_master: false, branches: nil, **git_strings)
      me = new_with_git_strings(services: services, pocs: pocs, branches: branches, **git_strings)
      me.save!
      me.reload
      me
    end

    def self.new_with_git_strings(services: Services.all_names, pocs: [], default_master: false, branches: nil, **git_strings)
      services = services.to_set.to_a
      me = new(
        services: services,
        pocs: pocs,
      )
      me.set_state(:off)

      services.each do |name|
        me.units << Unit.new(service_def: Services.get(name))
      end

      git_strings = (branches || {}) if git_strings.nil? || git_strings.empty?

      me.commits = git_strings.map do |codebase,git_str|
        Pancakes.validate_codebase(codebase) || raise("unsupported codebase #{codebase}")
        git_str = 'master' if default_master && (git_str.nil? || git_str.empty?)
        Pancakes::Commit.new_from_git_string(Pancakes.repo_name(codebase), git_str)
      end

      me
    end

    # @param branches [Hash] hash like { jarvis: 'master', frick: 'foobar', codebase: 'branch_name' }
    def self.with_branches(branches)
      criteria = Pancakes::Stack
      return nil if branches.nil? || branches.empty?
      branches.each_pair do |codebase,branch|
        criteria = criteria.elem_match(commits: { repo: Pancakes.repo_name(codebase), branch: branch })
      end
      criteria.last
    end

    def id_s
      self.id.to_s
    end

    def short_sha
      self.sha[0..6]
    end

    def branch_sha
      @__bs ||= Digest::SHA1.hexdigest(self.commits.map{|j| [j.repo, j.branch].join(':') }.sort.join('|'))
    end

    def branch_sha_short
      branch_sha[0..6]
    end

    def name
      #format("%s_%s_no%d", Pancakes::NAMESPACE, self.short_sha, self.serialno)
      format("%s_%s", Pancakes::NAMESPACE, self.short_sha)
    end

    # TODO break this down into smaller pieces. it's also similar in structure to bring_down.
    def bring_up
      if running?
        logger.info "#{self.name} is already running"
        return false
      end

      dry_run = Pancakes.cluster.dry_run?
      logger.info "bring_up will be a dry run" if dry_run
      StatHatWrapper.pause if dry_run

      StatHatWrapper.post_count('pancakes stacks bring_up started', 1)
      new_sha
      assign_attributes(desired_state: :running, started_at: Time.now, destroyed_at: nil)
      save! unless dry_run
      logger.info "bring_up #{self.name}"

      # TODO doing this for every worker could be pretty inefficient
      Pancakes.cluster.reset_failed_all
      sleep 2

      begin
        nm = units.netmaster
        Pancakes.cluster.start_unit(nm)

        Pancakes.block_until_values(values: true, timeout: 60) do
          refresh_unit_states
          !netmaster.ip.nil?
        end

        Pancakes.docker.set_machine_ip(nm.ip)
        if !Pancakes.docker.block_until_container_running(name: nm.name, timeout: 60)
          raise Pancakes::ClusterError.new('timeout waiting for netmaster container run')
        end

        units.non_netmaster.each do |unit|
          Pancakes.cluster.start_unit(unit)
        end
      rescue Pancakes::ClusterError => e
        # this will never run during a dry_run, so we dont need to worry about re-enabling StatHatWrapper
        StatHatWrapper.post_count('pancakes stacks bring_up errors', 1)
        logger.error "error during bring_up. some units may have been started successfully. class=#{e.original.class} message='#{e.message}'"
        return false
      end

      StatHatWrapper.unpause if dry_run
      return if dry_run

      timeout = 60*4
      state = block_until_stack_states(stack: self, states: %i[running failed], timeout: timeout)

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

    def bring_down(force: false)
      if !force && self.state == :off
        logger.info "bring_down nothing to do for #{self.name}"
        return false
      end

      dry_run = Pancakes.cluster.dry_run?
      logger.info "bring_down will be a dry run" if dry_run
      StatHatWrapper.pause if dry_run

      logger.info "bring_down #{self.name}"
      start_time = Time.now
      update_attributes!(desired_state: :off) unless dry_run
      StatHatWrapper.post_count('pancakes stacks bring_down started', 1)

      self.units.each do |unit|
        Pancakes.cluster.destroy_unit(unit)
      end

      StatHatWrapper.unpause if dry_run
      return if dry_run

      timeout = 60
      state = block_until_stack_states(stack: self, states: %i[off], timeout: timeout)

      if state == :off
        now = Time.now
        destroy_time = now - start_time
        logger.info "bring_down took #{format('%.1f', destroy_time)}s"
        StatHatWrapper.post_value('pancakes stacks bring_down duration', destroy_time)
        StatHatWrapper.post_count('pancakes stacks bring_down success', 1)
        update_attributes!(destroyed_at: now)
        return true
      else
        logger.info "bring_down timeout after #{timeout}s"
        StatHatWrapper.post_count('pancakes stacks bring_down timeouts', 1)
        return false
      end

      # TODO
      # - backend_destroy
      # - remove_from_freezer(20) if rm_frozen == true
    end

    def restart_with_branch_heads
      logger.info 'restarting with branch heads'
      bring_down
      logger.info 'doing bring_up for restart with branch heads'
      refresh_commits_to_head
      save!
      bring_up
      logger.info 'done restarting with branch heads'
    end

    def restart_with_same_commits
      logger.info 'restarting with same commits'
      bring_down
      logger.info 'doing bring_up for restart with same commits'
      bring_up
      logger.info 'done restarting with same commits'
    end

    # states
    # - :running    units nominal and all pingable
    # - :starting   units nominal and any unpingable, or units starting
    # - :off        no units
    # - :failed     any unit failed
    # - :incomplete something is missing
    # - :unknown    fallback
    def state_from_cluster!
      _units_state = units_state

      new_state =
        if _units_state == :nominal
          if all_services_up?
            logger.info 'pancakes state is running'
            :running
          else
            logger.info 'pancakes state is starting'
            :starting
          end
        else
          _units_state
        end

      set_state(new_state)
      save!
      new_state
    end
    alias :state! :state_from_cluster!

    # states
    # - :nominal    all active
    # - :off        no units
    # - :starting   active | inactive
    # - :failed     anything failed
    # - :incomplete something is missing
    # - :unknown  fallback
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
        logger.debug 'units state is incomplete'
        return :incomplete
      end

      if self.class.has_only_states(states, :active)
        logger.debug 'units state is nominal'
        return :nominal
      end

      if self.class.has_only_states(states, :active, :inactive, :activating)
        logger.debug 'units state is starting'
        return :starting
      end

      logger.debug 'units state is unknown'
      return :unknown
    end

    def refresh_unit_states
      cluster_units = Pancakes.cluster.all_units.select do |u|
        u.name.start_with?(self.name)
      end
      .map do |u|
        name_info = Unit.parse_unit_name(u.name)
        { name_info.service_name => { cluster_unit: u, name_info: name_info } }
      end
      .reduce(&:merge) || {}

      units.each do |unit|
        cluster_unit = cluster_units[unit.service_name]
        # TODO dry this up

        if !cluster_unit
          logger.debug "no cluster unit for #{unit.name}"
          unit.set_state(:off)
          unit.assign_attributes(info: nil, ip: nil, port: nil)
          unit.save!
          next
        end

        ip = cluster_unit[:cluster_unit].machine_ip
        container = Pancakes.docker.get_container(units.netmaster.name, ip)

        if !container
          logger.debug "no container for #{unit.name}"
          unit.set_state(:off)
          unit.assign_attributes(info: nil, ip: nil, port: nil)
          unit.save!
          next
        end

        port_map = container.port_mapping
        port = port_map[unit.primary_private_port]
        unit.set_state(cluster_unit[:cluster_unit].active_state)
        unit.assign_attributes(info: cluster_unit, ip: ip, port: port)
        logger.debug "updating #{unit.name} with cluster unit info <#{unit.state}>"
        unit.save!
      end

      save!
    end

    def set_state(new_state)
      assign_attributes(state: new_state.to_sym, state_updated_at: Time.now)
    end

    def netmaster
      units.netmaster
    end

    def new_sha
      self.history << { sha: self.sha.to_s, started_at: self.started_at, destroyed_at: self.destroyed_at }
      self.sha = Digest::SHA1.hexdigest(Time.now.to_i.to_s)
      refresh_logger
    end

    def running?
      state == :running
    end

    def off?
      state == :off
    end

    def all_services_up?
      units.pingable.map do |unit|
        is_service_up?(unit)
      end
      .reduce(true){|memo,val| memo && val }
    end


    ######
    #     #  #####      #    #    #    ##     #####  ######
    #     #  #    #     #    #    #   #  #      #    #
    ######   #    #     #    #    #  #    #     #    #####
    #        #####      #    #    #  ######     #    #
    #        #   #      #     #  #   #    #     #    #
    #        #    #     #      ##    #    #     #    ######
    private

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

    # @api private
    def refresh_commits_to_head
      self.commits = self.commits.map do |ci|
        Pancakes::Commit.new_from_git_string(ci.repo, ci.git_string)
      end
    end

    # @api private
    def block_until_stack_states(stack:, states:, timeout:)
      Pancakes.block_until_values(obj: stack, method: :state_from_cluster!, values: states, timeout: timeout)
    end

    # @api private
    def is_service_up?(unit)
      name = unit.service_name
      raise "service #{name} is not pingable" unless unit.pingable?
      url = unit.ping_url

      begin
        if url.start_with?('http')
          resp = RestClient::Request.execute(method: :get, url: url, timeout: 5, open_timeout: 5)

          if resp.code == 200
            logger.info "service #{name} reached at #{url}"
            return true
          else
            logger.info "service #{name} at #{url} is unreachable"
            return false
          end
        else
          logger.warn "service #{name} at #{url} cannot be pinged due to url scheme"
        end
      rescue StandardError => e
        logger.info "service #{name} at #{url} is unreachable due to #{e.class} '#{e.message}'"
        return false
      end
    end

    # @api private
    def logger
      return @__lgr if @__lgr
      lg_name = "#{self.class}[#{self.name}]"
      #Logging.logger[lg_name].appenders = Pancakes.log_appender
      #Logging.logger[lg_name].level = Pancakes.log_level
      @__lgr = Logging.logger[lg_name]
    end

    # Use this method when the stack's name changes to get a new logger with the new name.
    #
    # @api private
    def refresh_logger
      @__lgr = nil
    end

    #def starting?
      #== :starting
    #end

    #def failed?
      #== :failed
    #end

    #def incomplete?
      #== :incomplete
    #end

    #def unknown?
      #== :unknown
    #end

    #def remove_from_freezer(delay=0)
      #sleep(delay)
      #logger.info "removing #{self.branch_id} from freezer"
      #Pancakes::Freezer.remove(self.branch_identifier)
    #end
  end
end
