module Pancakes
  module Fleet
    class Machine < Hashie::Trash
      property :id, required: true
      property :ip, required: true, from: 'primaryIP'
      property :metadata, required: true, transform_with: lambda { |v| Hashie::Mash.new(v)  }
      property :units, required: true, default: []

      PROD_WORKERS_MAX_BUILDS = {
        "10.0.80.21" => 2,
        "10.0.80.31" => 2,
      }

      def add_unit(unit)
        units << unit
      end

      def running_builds
        @__running_builds ||= units.select do |unit|
          unit.name =~ Pancakes::Fleet::Cluster::BUILD_REGEX && unit.active_state == 'active' && unit.sub_state == 'running'
        end
        .reduce({}) do |memo,unit|
          match = unit[:name].match(Pancakes::Fleet::Cluster::BUILD_REGEX)
          build, type = match[:build], match[:type]
          memo[build] ||= { units: [], unit_types: [], machine: self }
          memo[build][:units] << unit
          memo[build][:unit_types] << type
          memo
        end
        .select do |build,info|
          info[:unit_types].sort == %w[app mysql] || info[:unit_types].sort == %w[app db]
        end
      end

      def has_capacity?
        capacity > 0
      end

      def capacity
        max_builds - running_builds.size
      end

      def worker?
        metadata.role == 'worker'
      end

      def max_builds
        if worker?
          PROD_WORKERS_MAX_BUILDS[ip] || 1
        else
          0
        end
      end
    end
  end
end
