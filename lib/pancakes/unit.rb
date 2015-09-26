module Pancakes
  class Unit < Sequel::Model
    include HonestyCluster::SwarmBackend::Service

    set_dataset :pancakes_units
    plugin :timestamps
    plugin :serialization, :json, :service_def, :cluster_info
    plugin :validation_helpers

    serialize_attributes :symbolize, :state

    STATES = %i[off failed active inactive activating deactivating]
    PANCAKES_UNIT_REGEX = /\/?(?<stack_name>#{Pancakes::NAMESPACE}_[0-9a-f]+_\d+)_(?<service_name>[a-z0-9\-_]+)(?:\.service)?/i
    # other versions of this regex that may be useful at some point
    # /\/?(?:pancakes)_(?<branch_id>[0-9a-f]+)_no(?<serialno>\d+)_(?<service>\w+)/
    # /\/?(?<stack_name>#{Pancakes::NAMESPACE}_[0-9a-f]+)_(?<service_name>[a-z0-9\-_]+)(?:\.service)?/i

    many_to_one :stack, key: :stack_id, class: :"Pancakes::Stack"

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
      me
    end

    def commit
      stack.commit_for_codebase(codebase)
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

    def env
      (service_def.env || {}).merge(
        if codebase == 'jarvis'
          #self.stack.jarvis_env
          {}
        else
          {}
        end
      )
    end

    def container
      if machine_ip
        Pancakes.docker.set_machine_ip(machine_ip)
        cc = Pancakes.docker.get_container(name)
        if !cc
          Pancakes.logger.warn "unit(service_name=#{service_name}) has no container, but does have a machine_ip(#{machine_ip})"
        end
        cc
      else
        Pancakes.logger.warn "unit(service_name=#{service_name}) has no machine_ip, but one was likely expected"
        nil
      end
    end

    def netmaster?
      service_def.netmaster
    end

    def ports
      service_def.ports
    end

    def active?
      !!tcp_str
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

    def tcp_str
      (machine_ip && port) ? format('%s:%d', machine_ip, port) : nil
    end

    def to_s
      name
    end

    def primary_private_port
      if p = service_def.ports
        p.first
      else
        nil
      end
    end

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

    def dbs
      service_def.dbs
    end

    def ping_url
      return nil unless pingable?
      service_def.ping_url.sub('$ip', machine_ip).sub('$port', port.to_s)
    end

    def ping_http_status
      return nil unless pingable?
      service_def.http_status
    end

    def pingable?
      !!(service_def.ping_url && machine_ip && port)
    end

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
        stack_name: match[:stack_name],
        service_name: match[:service_name]
      )
    end
  end
end
