module Docker
  class Container
    def port_mapping
      @info['Ports'].map{|p| { p['PrivatePort'] => p['PublicPort']  } }.reduce(&:merge)
    end
  end
end

module Pancakes
  class Docker
    API_PORT = 2375

    def initialize
      @machine_ip = '127.0.0.1'
      @last_containers = nil
      @last_containers_timestamp = nil
    end

    # @api private
    def logger
      return @__lgr if @__lgr
      #Logging.logger[self.class].appenders = Pancakes.log_appender
      #Logging.logger[self.class].level = Pancakes.log_level
      @__lgr = Logging.logger[self.class]
    end

    # @api private
    def with_ip(log_message)
      "docker_ip=#{@machine_ip} #{log_message}"
    end

    def set_machine_ip(new_machine_ip)
      raise("machine ip can't be nil") unless new_machine_ip
      @machine_ip = new_machine_ip
      ::Docker.url = "tcp://#{@machine_ip}:#{API_PORT}"
      ::Docker.validate_version!
    end

    def all_containers
      if @last_containers.nil? || (Time.now - @last_containers_timestamp) > 1.0
        logger.info with_ip 'getting all containers'
        @last_containers_timestamp = Time.now
        @last_containers = ::Docker::Container.all
      else
        @last_containers
      end
    end

    # @param pattern [String, Regexp] pattern to match
    def get_container(pattern, machine_ip=nil)
      set_machine_ip(machine_ip) if machine_ip
      containers = all_containers

      container = containers.detect do |container|
        name = self.class.get_container_name(container)
        if pattern.is_a?(String)
          pattern == name
        elsif pattern.is_a?(Regexp)
          pattern =~ name
        end
      end
    end

    # @api private
    def self.get_container_name(container)
      container.info['Names'].first.sub(/^\//, '')
    end

    def get_running_container(name, machine_ip=nil)
      container = get_container(name, machine_ip)

      if container
        status = container.info['Status']
        if status.start_with?('Up ')
          container
        else
          nil
        end
      else
        nil
      end
    end

    def block_until_container_running(name:, timeout:)
      Pancakes.block_until_values(
        obj: self,
        method: :get_running_container,
        args: name,
        values: ::Docker::Container,
        timeout: timeout
      )
    end

    #def tcp_info(service_name=nil)
      #stack_info =  Pancakes::Docker::ClassMethods.all_tcp_info[@stack_id]
      #if stack_info && info = stack_info[:tcp_info]
        #service_name ? info[service_name.to_sym] : info
      #else
        #nil
      #end
    #end

    #def self.all_tcp_info
      #return refresh_tcp_info! unless @cached_tcp_info
      #@cached_tcp_info
    #end

    #def self.refresh_tcp_info
      #worker_ips = Pancakes.cluster.machine_ips

      #if worker_ips.empty?
        #@cached_tcp_info = {}
        #return @cached_tcp_info
      #end

      #@cached_tcp_info = worker_ips.map do |worker_ip|
        #get_tcp_info_for_machine_grouped_by_branch_id!(worker_ip)
      #end
      #.reduce(&:merge)

      #return @cached_tcp_info
    #end


    # @api private
    #def self.get_tcp_info_for_machine_grouped_by_branch_id!(machine_ip)
      #set_machine_ip(machine_ip)

      #Pancakes.logger.debug "getting latest containers from docker on #{machine_ip}"
      #network_containers = ::Docker::Container.all.select do |container|
        #name = get_container_name(container)
        #next false if !Pancakes::Unit.is_pancakes_unit?(name)
        #parsed_unit_info = Pancakes::Unit.parse_unit_name(name)
        #!parsed_unit_info.nil? && parsed_unit_info[:service].to_sym == Pancakes::Services.netmaster
      #end

      #if network_containers.empty?
        #Pancakes.logger.warn "no netmaster containers found on worker with addr #{machine_ip}"
        #return {}
      #end

      #return network_containers.map do |container|
        #parsed_unit_info = Pancakes::Unit.parse_unit_name(get_container_name(container))
        #tcp_info = service_names_mapped_to_public_port_and_host(container.info['Ports'], machine_ip)

        #{
          #Pancakes::Stack.make_stack_id(parsed_unit_info[:branch_id], parsed_unit_info[:serialno]) => {
            #tcp_info: tcp_info,
            #worker_ip: machine_ip,
          #}
        #}
      #end
      #.reduce(&:merge)
    #end


    ## @api private
    ## @return a hash like { :"jarvis-server" => { host: "10.0.80.1", port: 43631 }, ... }
    #def self.service_names_mapped_to_public_port_and_host(docker_ports, machine_ip)
      #docker_ports.map do |port_pair|
        #public_port, private_port = port_pair['PublicPort'], port_pair['PrivatePort']
        #service_name = service_name_with_private_port(private_port)
        #service_name ? { service_name => { host: machine_ip, port: public_port } } : {}
      #end
      #.reduce(&:merge)
    #end

    ## @api private
    ## @return a symbol like :"jarvis-server" or :"frick-server"
    #def self.service_name_with_private_port(private_port)
      #Pancakes::Services.service_configuration.each do |name,conf|
        #if conf[:ports] && conf[:ports].include?(private_port)
          #return name
        #end
      #end
      #return nil
    #end
  end
end
