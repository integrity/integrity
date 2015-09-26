module Pancakes
  class Docker
    include Pancakes::ClassLogger

    API_PORT = 2375

    def initialize
      @machine_ip = '127.0.0.1'
    end

    # @api private
    def with_ip(log_message)
      "docker_ip=#{@machine_ip} #{log_message}"
    end

    def set_machine_ip(new_machine_ip)
      raise("machine ip can't be nil") unless new_machine_ip
      @machine_ip = new_machine_ip
      ::Docker.url = "tcp://#{@machine_ip}:#{API_PORT}"
      logger.info "setting Docker.url to #{::Docker.url}"
      ::Docker.validate_version!
    end

    def all_containers
      logger.info with_ip 'getting all containers'
      ::Docker::Container.all
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
  end
end
