module Pancakes
  class Unit
    include Mongoid::Document

    #UNIT_GROUP_STATES = %i[nominal off starting failed incomplete unknown]
    STATES = %i[off failed active inactive activating deactivating]

    field :service_def,      type: Hash
    field :state,            type: Symbol, default: :off
    field :state_updated_at, type: Time
    #field :desired_state,    type: Symbol
    field :ip,               type: String
    field :port,             type: Integer
    field :info,             type: Hash

    #attr_readonly :service_def

    embedded_in :stack, class_name: 'Pancakes::Stack', inverse_of: :units

    validates :service_def, presence: true
    validates :state, inclusion: { in: STATES }, allow_blank: false, allow_nil: false
    validates :port, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
    validate :is_ip_addr?

    def is_ip_addr?
      self.ip.nil? || IPAddr.new(self.ip).ipv4?
    end

    def active?
      state == :active
    end

    def name
      "#{stack.name}_#{service_name}"
    end

    def tcp_str
      if ip &&port
        format('%s:%d', ip, port)
      else
        ''
      end
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

    #def get_container
      #if ip
        #Pancakes.docker.get_container(name, ip)
      #end
      #nil
    #end

    def set_state(new_state)
      assign_attributes(state: new_state.to_sym, state_updated_at: Time.now)
    end

    def service_def
      sd = self['service_def']
      st = self.class.subtype(sd['name'])
      sd = sd.merge(subtype: st) if st
      cb = Pancakes.codebase_name(sd['repo'])
      sd = sd.merge(codebase: cb) if cb
      @__sd ||= Hashie::Mash.new(sd)
    end

    def service_name
      service_def.name
    end

    def ping_url
      return nil unless pingable?
      service_def.ping_url.sub('$ip', ip).sub('$port', port.to_s)
    end

    def pingable?
      !!(service_def.ping_url && ip && port)
    end

    def self.subtype(service_name)
      if service_name['-']
        service_name.split('-')[1].to_sym
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
      name = name.to_s
      #match = name.match((/\/?(?:pancakes)_(?<branch_id>[0-9a-f]+)_no(?<serialno>\d+)_(?<service>\w+)/))
      match = name.match(/\/?(?<stack_name>#{Pancakes::NAMESPACE}_[0-9a-f]+)_(?<service_name>[a-z0-9\-_]+)(?:\.service)?/i)

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

    #def self.new_with_service_name(name)
      #new(
        #service_def: Services.get(name)
      #)
    #end

    #attr_reader :conf, :stack, :name, :service, :service_type, :branch_id, :serialno, :codebase

    #def initialize(stack:, name:)
      #@stack = stack
      ##@name = name.sub(/\.service$/, '')
      ##@name = name.to_sym
      #name_info = parse_unit_name(name)
      #@codebase, @service_type = @service.to_s.split('-').map(&:to_sym)
      #@conf = Services.service_configuration[name]
    #end
  end
end
