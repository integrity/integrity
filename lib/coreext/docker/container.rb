class Docker::Container

  RUNNING_REGEXP = /Up .+/
  EXITED_REGEXP  = /Exited \((?<exit_code>\d+)\) .+/

  def info
    Hashie::Mash.new(super)
  end

  def full_name
    info.Names.detect do |name|
      name.split('/').size == 3
    end
  end

  def name
    full_name.split('/').last
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

  def unclean_exit?
    exited? && exit_code != 0
  end

  def clean_exit?
    exited? && exit_code == 0
  end

  def exit_code
    exited? ? status.match(EXITED_REGEXP)[:exit_code].to_i : nil
  end

  def running?
    !!status.match(RUNNING_REGEXP)
  end

  def force_remove
    remove(force: true)
  end

  # possibly deprecated
  def port_mapping
    info.Ports.map do |port_mapping|
      { port_mapping.PrivatePort => port_mapping.PublicPort }
    end.reduce(&:merge)
  end

  private def first_port_mapping
    info.Ports.first
  end
end
