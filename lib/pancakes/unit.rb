module Pancakes
  class Unit < Sequel::Model
    include HonestyCluster::HealthCheckable
    include HonestyCluster::SwarmBackend::Cargo

    set_dataset :pancakes_units
    plugin :timestamps
    plugin :serialization, :json, :service_def, :cluster_info
    plugin :validation_helpers

    serialize_attributes :symbolize, :state

    STATES = %i[off failed active inactive activating deactivating]
    PANCAKES_UNIT_REGEX = /\/?(?<stack_name>#{Pancakes::NAMESPACE}_[0-9a-f]+_(?<stack_id>\d+))_(?<service_name>[a-z0-9\-_]+)(?:\.service)?/i
    # other versions of this regex that may be useful at some point
    # /\/?(?:pancakes)_(?<branch_id>[0-9a-f]+)_no(?<serialno>\d+)_(?<service>\w+)/
    # /\/?(?<stack_name>#{Pancakes::NAMESPACE}_[0-9a-f]+)_(?<service_name>[a-z0-9\-_]+)(?:\.service)?/i

    many_to_one :stack, key: :stack_id, class: :"Pancakes::Stack"
    one_to_many :events, key: :service_id, class: :"HonestyCluster::Event", order: :timestamp

    def validate
      super
      validates_presence :service_def
      validates_includes STATES, :state, allow_blank: false, allow_nil: false
      validates_integer :port, allow_nil: true
      errors.add(:machine_ip, "machine_ip '#{machine_ip}' is not an ip address") if (machine_ip && !IPAddr.new(machine_ip).ipv4?)
    end

    #
    # hooks
    #

    def before_validation
      self.state = :off unless self.state
    end

    #
    # constructors
    #

    def self.create_with_service_def(service_def: nil)
      me = new(service_def: service_def, ping_url: service_def[:ping_url], service_name: service_def[:name], cluster_info: {})
      me.save
      #me.initial_health_check!
      me
    end

    def commit
      stack.commit_for_codebase(codebase)
    end

    def sha
      commit.sha
    end

    def branch
      commit.branch
    end

    def stack_id
      stack.id
    end

    def requires
      req = service_def.requires.to_s
      if req.end_with?('.service')
        req
      else
        stack.unit_with_service_name(req).service_file_name
      end
    end

    def machine_of
      mo = service_def.machineof
      if mo
        stack.unit_with_service_name(mo).service_file_name
      else
        nil
      end
    end

    def image
      service_def.image
    end

    #def env
      #(service_def.env || {}).merge(
        #if codebase == 'jarvis'
          ##self.stack.jarvis_env
          #{}
        #else
          #{}
        #end
      #)
    #end

    #def container
      #if machine_ip
        #Pancakes.docker.set_machine_ip(machine_ip)
        #cc = Pancakes.docker.get_container(name)
        #if !cc
          #Pancakes.logger.warn "unit(service_name=#{service_name}) has no container, but does have a machine_ip(#{machine_ip})"
        #end
        #cc
      #else
        #Pancakes.logger.warn "unit(service_name=#{service_name}) has no machine_ip, but one was likely expected"
        #nil
      #end
    #end

    #def netmaster?
      #service_def.netmaster
    #end

    def ports
      service_def.ports
    end

    def active?
      !!tcp_str
    end

    #def is_setup_container?
      #subtype == 'setup'
    #end

    def addr_known?
      machine_ip && port
    end

    def name
      if self.stack
        "#{self.stack.name}_#{service_name}"
      else
        raise "stack is nil for unit #{service_name}"
      end
    end

    def dumb_sibling_name
      "#{name}-dumb_sibling"
    end

    def dumb_sibling_service_file_name
      "#{dumb_sibling_name}.service"
    end

    def service_file_name
      "#{name}.service"
    end
    alias :service_fname :service_file_name

    def repo
      service_def.repo
    end

    def tcp_str(port_to_use=port)
      (machine_ip && port_to_use) ? format('%s:%d', machine_ip, port_to_use) : nil
    end

    def lookup_public_port(private_port)
      _container = container
      if _container
        _container.port_mapping[private_port.to_i]
      else
        nil
      end
    end

    def to_s
      name
    end

    #def primary_private_port
      #if p = service_def.ports
        #p.first
      #else
        #nil
      #end
    #end

    def service_type
      service_name.split('-')[0]
    end

    def codebase
      return nil unless service_def
      service_def.codebase
    end

    def subtype
      service_def.subtype
    end

    def set_state(new_state)
      set_all(state: new_state.to_sym, state_updated_at: Time.now)
    end

    def service_def
      return @__sd if @__sd

      sd = super.deep_symbolize_keys
      st = self.class.subtype(sd[:name])
      sd = sd.merge(subtype: st) if st
      cb = Pancakes.codebase_name(sd[:repo])
      sd = sd.merge(codebase: cb) if cb
      @__sd ||= Hashie::Mash.new(sd)
    end

    def service_name
      service_def.name
    end
    alias :resource_name :service_name

    def dbs
      service_def.dbs
    end

    def clear_events
      events_dataset.destroy
    end

    def mysql?
      service_name == 'mysql'
    end

    def postgres?
      service_name == 'postgres'
    end

    def mailcatcher?
      service_name == 'mailcatcher'
    end

    def setup?
      subtype == 'setup' || subtype == 'orchestra'
    end

    def server?
      subtype == 'server'
    end

    def delayed_job?
      subtype == 'delayed_job'
    end

    #def ping_url
      #return nil unless pingable?
      #service_def.ping_url.sub('$ip', machine_ip).sub('$port', port.to_s)
    #end

    #def ping_http_status
      #return nil unless pingable?
      #service_def.http_status
    #end

    #def pingable?
      #!!(service_def.ping_url && machine_ip && port)
    #end

    def self.subtype(service_name)
      srv_name = Services.parse_service_name(service_name)
      if srv_name.size == 2
        srv_name.last
      else
        nil
      end
    end

    def self.pancakes_unit?(name)
      name.start_with?(Pancakes::NAMESPACE)
    end

    def self.parse_unit_name(name)
      return nil unless name
      name = name.to_s
      match = name.match(PANCAKES_UNIT_REGEX)

      if !match
        Pancakes.logger.warn "unit name '#{name}' didnt match the expected format"
        return nil
      end

      Hashie::Mash.new(
        name: name,
        stack_id: match[:stack_id].to_i,
        stack_name: match[:stack_name],
        service_name: match[:service_name]
      )
    end


    # health checking

    def container_health_check
      cnt = container
      if !cnt
        [false, 'container not found']
      elsif cnt.clean_exit?
        [true, 'container exited cleanly']
      elsif cnt.unclean_exit?
        [false, "container exited with failure (#{cnt.exit_code})"]
      elsif cnt.running?
        [true, 'container running']
      else
        [false, 'container neither running nor exited']
      end
    end

    def ping_url
      if service_def.ping_url
        if addr_known?
          service_def.ping_url.sub('$ip', machine_ip).sub('$port', port.to_s)
        else
          nil
        end
      else
        nil
      end
    end

    def healthy_ping_http_status
      service_def.http_status
    end

    def user_facing?
      !!service_def.ping_url
    end

    private def ping(url, desired_response)
      resp =
        if desired_response == 302
          Net::HTTP.get_response(URI(url))
        else
          RestClient::Request.execute(method: :get, url: url, timeout: 5, open_timeout: 5)
        end

      if (resp_code = resp.code.to_i) == healthy_ping_http_status
        [true, nil]
      else
        [false, "http health check failed. required=#{healthy_ping_http_status} got=#{code} url=#{url}"]
      end
    end

    private def http_health_check
      url = ping_url
      return nil unless url
      name = service_name
      if url
        begin
          ping(url, healthy_ping_http_status)
        rescue StandardError => e
          [false, "unreachable at #{url} due to #{e.class} '#{e.message}'"]
        end
      else
        [false, "http health check url is unavailable"]
      end
    end

    private def update_health(curr_health, new_health)
      [
        curr_health[0] && new_health[0],
        [curr_health[1], new_health[1]].compact.join(', '),
      ]
    end

    # HealthCheckable
    def current_health
      health = [true, nil]
      health = update_health(health, container_health_check)
      if health[0] && http_check = http_health_check
        health = update_health(health, http_check)
      end
      HonestyCluster::HealthCheck.new(*health)
    end

    private def timberland_command
      HonestyCluster::Timberland::Cmd.new(
        boot_type:    'pancakes',
        service_type: subtype,
        sha:          sha,
        repo:         repo,
        branch:       branch,
        debug:        Pancakes.timberland_debug?,
        setup_db:     true,
      )
    end

    def timberlandified?
      !(mysql? || postgres? || mailcatcher?)
    end

    # Cargo
    #def container_healthy?
    #end

    # Cargo
    #def cargo_healthy?
    #end

    # Cargo
    def cargo_group_type
      'pancakes-stack'
    end

    # Cargo
    def cargo_group_id
      stack_id
    end

    # Cargo
    def cargo_type
      'pancakes-service'
    end

    # Cargo
    def cargo_id
      id
    end

    # Cargo
    def container_name
      name
    end

    # Cargo
    def container_links
      nil
    end

    # Cargo
    def image_name
      image
    end

    # Cargo
    def docker_command
      if timberlandified?
        timberland_command.to_docker_api_cmd
      else
        nil
      end
    end

    # Cargo
    def exposed_ports
      ports
    end

    # Cargo
    def container_env
      _env = {
        'PANCAKES_ID'      => stack_id,
        'STACK_ID'         => stack_id,
        'SERVICE_ID'       => id,
        'PANCAKES_SHA'     => stack.short_sha,
        'HONESTY_BASE_URL' => HonestyCluster::SwarmBackend.base_url,
      }

      if timberlandified?
        _env.merge('TIMBERLAND_CMD' => timberland_command.run_cmd)
      else
        _env
      end
    end

    # Cargo
    def container_labels
      nil
    end

    # Cargo
    def cpu_cores
      1
    end

    # Cargo
    def memory
      MB(512)
    end
  end
end
