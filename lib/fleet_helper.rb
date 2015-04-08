module Integrity
  module FleetHelper

    BUILD_REGEX = /\A(?<build>\w+_[0-9a-f]{7}_\d+)_(?<type>\w+)\.service\z/

    @client = ::Fleet.new

    def self.running_build_count_by_machine
      group_by_machine(unit_zen[:running]).reduce({}){|m,(mach,units)| m[mach] = units.count ; m }
    end

    # @api private
    def self.unit_zen
      units = @client.list
      { running: running_builds(units) }
    end

    # @api private
    def self.group_by_machine(units)
      units.group_by do |k,v|
        v[:machine_ip]
      end
    end

    # @api private
    def self.running_builds(units)
      units.select do |unit|
        unit[:name] =~ BUILD_REGEX &&
        unit[:active_state] == 'active' &&
        unit[:sub_state] == 'running'
      end
      .reduce({}) do |memo,unit|
        match = unit[:name].match(BUILD_REGEX)
        build, type = match[:build], match[:type]
        memo[build] ||= { units: [], unit_types: [], machine_ip: unit[:machine_ip] }
        memo[build][:units] << unit
        memo[build][:unit_types] << type
        memo
      end
      .select do |build,info|
        info[:unit_types].sort == %w[app mysql]
      end
    end
  end
end
