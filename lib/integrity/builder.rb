module Integrity
  class Builder
    attr_reader :build, :logger

    # A little context for this:
    #
    # Before the scheduler, when a build was started, it was started because it
    # wons the race of all pending builds being started in a loop in quick
    # succession. As soon as the winner had it's DB record updated, no other
    # pending build would be started, because the value for build capacity was
    # hardcoded and therefore instantly and accurately available.
    #
    # In comparison, with the scheduler, the information about build capacity is
    # delayed. The cluster operation ("delete the old build's units") before
    # starting a build will not be reflected in the scheduler's inquiries for a
    # free machine until after a delay. The delay comes from Fleet (which
    # probably comes from just a lot of shit happening between major system
    # components, of which Fleet is at the top).
    #
    def self.scheduler_wait_for_cluster(build)
      wait_t = Integrity.config.scheduler_wait_for_fleet_time
      log_build(:scheduler_wait_for_cluster, build, "sleeping for scheduler_wait_for_fleet_time=#{wait_t}s")
      sleep(wait_t)
    end

    def self.scheduler_select_machine(build, nickname: nil, machine_id: nil)
      machine =
        if machine_id
          Integrity.cluster.select_machine_for_build_with_id(machine_id)
        else
          Integrity.cluster.select_machine_for_build
        end
      log_build(:scheduler_select_machine, build, "#{nickname || 'selected'} machine=#{machine}")
      machine
    end

    # if pending_builds.count > cluster.capacity then wait
    # - requires round robin on top of current strategy so that, and even that might not work
    #
    # if pending_builds.count > 1 (this 1 includes the current canidate for start_build) then wait
    #
    # if pending_builds.count > any_machine.capacity then wait
    #def self.scheduler_should_wait?(build)
      #log_build(:scheduler_should_wait?, build, "")
    #end

    #def self.scheduler_claimed_machines
      #@__scheduler_claimed_machines ||= {}
    #end

    #def self.scheduler_add_claim(build_id, machine_id)
      #scheduler_claimed_machines[build_id] = machine_id
    #end

    ## policy for removing entries?
    #def self.scheduler_rm_claim(build_id)
      #scheduler_claimed_machines.delete(build_id)
    #end

    # Whenever it's time to look at intents, expire the old ones.
    def self.cluster_intents_init
      @__cluster_intents ||= []
    end

    def self.cluster_intents
      cluster_intents_init
      cluster_expire_intents
      @__cluster_intents
    end

    def self.cluster_intent_ttl_sec
      10000
    end

    def self.cluster_expire_intents
      #expired = []
      @__cluster_intents.reject! do |intent|
        if intent.created_at && (Time.now - intent.created_at) > intent.ttl
          #expired << intent
          true
        else
          false
        end
      end

      # we would potentially want to call events.rb { Builder.queue_builds! } on this trigger
      #Integrity::Event.trigger('intents:expired', {expired_intents: expired})
    end

    def self.cluster_mk_intent(build_id, type, machine)
      intent = Hashie::Mash.new(
        build_id: build_id,
        type: type,
        ttl: cluster_intent_ttl_sec,
        created_at: Time.now,
        machine: machine,
      )
    end

    def self.cluster_query_intents(build_id: nil, type: nil, machine_id: nil, not_machine_id: nil)
      results = cluster_intents.select do |intent|
        (build_id.nil?   || intent.build_id   == build_id) &&
        (type.nil?       || intent.type       == type) &&
        (machine_id.nil? || (intent.machine && intent.machine.id == machine_id))
      end
      .reject do |intent|
        (not_machine_id && intent.machine.id == not_machine_id)
      end

      results.empty? ? nil : results

      #results = cluster_intents.select do |intent|
        #intent.build_id == build_id && (type == nil || intent.type == type)
      #end

      #if type && results.size > 1
        #raise "expected only one intent with build_id=#{build_id} and type=#{type}. got: #{results.inspect}"
      #end

      #results
    end

    def self.cluster_query_first_intent(**args)
      intents = cluster_query_intents(**args)
      intents ? intents.first : intents
    end

    def self.cluster_get_machine_for_start_build(build_id)
      intent = cluster_query_first_intent(build_id: build_id, type: :build_start)
      intent ? intent.machine : intent
    end

    # :build_start intents ideally should expire/resolve exactly when the units
    # show up to clients of the fleet API.
    # :build_destroy intents similarly should resolve when the units diappear.
    #
    # These situations can be ignored for now by using a conservatiely estimated
    # hard ttl. The ClusterWatcher component would need to be written to get
    # the exact functionality defined above.
    #
    # The trade off is that resources which are available may not be considered
    # available (the delete case), and resources that are not available are
    # considered available (the start case)
    def self.cluster_add_intent(build_id:, type:, machine: nil)
      raise("intent build_id can't be nil") unless build_id
      raise("bad intent type for build_id=#{build_id} (type=#{type})") unless [:build_start, :build_destroy].include?(type)

      if type == :build_destroy && cluster_query_intents(build_id: build_id, type: :build_start)
        raise("expected no :build_start intent to exist during add :build_destroy for build_id=#{build_id} type=#{type}")
      end

      if cluster_query_intents(build_id: build_id, type: type)
        raise("existing intent found with build_id=#{build_id} type=#{type}")
      end

      cluster_intents << cluster_mk_intent(build_id, type, machine)
    end

    #def self.cluster_rm_intent(build_id, type)
      #raise("expected build_id and type but got build_id=#{build_id} and type=#{type}") if !build_id || !type

      #pre_size = cluster_intents.size
      #cluster_intents.reject! do |intent|
        #intent.build_id == build_id && intent.type == type
      #end
      #post_size = cluster_intents.size

      #raise("expected intent to be removed but none were. build_id=#{build_id} type=#{type}") if post_size == pre_size
      #nil
    #end

    def self.start_build(build)
      if build.started?
        log_build(:start_build, build, "not running because build started already, in #{build.status} state")
      #elsif first_inquiry_machine.nil?
        #log_build(:start_build, build, "not running because there are no machines with build capacity")
      else
        # If another build wins the race against this one for the same first_inquiry_machine,
        # then the loser fill not start until the next github push, finished build, or manual start.
        # This is not desired behavior. Instead, we want the loser to try a new machine.
        #
        # - approaches:
        #   - intents
        #     - pro
        #       - direct assignment control over packing, which is strategic for autoscaling
        #       - fastest
        #     - con
        #       - state
        #       - more moving parts
        #   - retry loop
        #     - pro
        #       - stateless
        #       - control over packing by nature of how the _next_ machine is chosen, which is strategic for autoscaling
        #     - con
        #       - slow
        #       - ugly
        #   - round-robin with worker MRU list
        #     - pro
        #       - simple state
        #     - con
        #       - packing is spread out :(
        intended_machine = cluster_get_machine_for_start_build(build.id)

        if intended_machine
          log_build(:start_build, build, "intended scheduled machine ip=#{intended_machine.ip}")
          log_build(:start_build, build, "Clear builds on branch: #{build.branch_name}") { Integrity::Event.trigger('branch:cleanup', build.id) }
          log_build(:start_build, build, "Running build"){ launch_build(build, intended_machine) }
        else
          log_build(:start_build, build, "not running because no :build_start intent was found for build.id=#{build.id}")
        end
      end
    end

    def self.queue_builds!
      log "queue_builds: - #{Build.pending.count} builds pending. Attempting to queue remaining builds..."
      # TODO schedule everything at once, making sure there is room before running the build
      # add number of :build_destroy intents to the cluster capactity.
      # subtract number of :build_start intents from cluster capacity
      Build.pending.map do |b|
        cluster_add_intent(build_id: b.id, type: :build_start, machine: :foo)
        log_build(:queue_builds!, b, :queueing) { b.run }
      end
    end

    # Launches the passed build on fleet. Before starting, it kills
    # older builds from same branch (and itself if it was a re-run)
    def self.launch_build(build, scheduled_machine)
      log_execution(:launch_build, build) do
        log_build(:launch_build, build, :cleanup) { Integrity.cluster.destroy_build(build.service_options) }
        log_build(:launch_build, build, "starting on worker ip=#{scheduled_machine.ip} id=#{scheduled_machine.id}") do
          Integrity.cluster.start_build(build.service_options, scheduled_machine.id)
        end
        log_build(:launch_build, build, :started) { build.reload.started! }
        log_build(:launch_build, build, 'Updating fleet'){ Build.update_fleetctl_status }
      end
    end

    # Kill fleet unit and destroy service matching build that was passed.
    def self.destroy_build(build)
      cluster_add_intent(build_id: build.id, type: :build_destroy)
      log_execution(:destroy_build, build){ Integrity.cluster.destroy_build(build.service_options) }
      # TODO Here, wait for units to disappear, then remove intent.
    end

    def self.log_execution(action, build)
      log_build action, build, 'starting'
      yield
      log_build action, build, 'completed'
    end

    def self.log_build(action, build, msg)
      log "#{action}: [Build:#{build.try(:id)}] (#{build.service_vars.inspect}) - #{msg}"
      yield if block_given?
    end

    def self.log(msg)
      msg = "[Integrity::Builder]: #{msg}"
      Integrity.logger.info msg
    end
  end
end
