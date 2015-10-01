module Docker
  class Container

    RUNNING_REGEXP = /Up \d+ \w+/
    EXITED_REGEXP  = /Exited \((?<exit_code>\d+)\) \d+ \w+ ago/

    def info
      Hashie::Mash.new(super)
    end

    def full_name
      info.Names.first
    end

    def name
      name_parts[1]
    end

    def ip
      first_port_mapping ? first_port_mapping.IP : nil
    end

    def public_port
      first_port_mapping ? first_port_mapping.PublicPort : nil
    end

    def status
      info.Status
    end

    def exited?
      !!status.match(EXITED_REGEXP)
    end

    def exit_code
      exited? ? status.match(EXITED_REGEXP)[:exit_code].to_i : nil
    end

    def running?
      !!status.match(RUNNING_REGEXP)
    end

    private def first_port_mapping
      info.Ports.first
    end

    private def name_parts
      full_name.sub(/^\//, '').split('/')
    end

    # possibly deprecated
    def port_mapping
      info.Ports.map do |port_mapping|
        { port_mapping.PrivatePort => port_mapping.PublicPort }
      end.reduce(&:merge)
    end
  end
end
