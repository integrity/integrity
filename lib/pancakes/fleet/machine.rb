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
        "10.0.80.7" => 2,
        "10.0.80.9" => 2,
      }

      def add_unit(unit)
        units << unit
      end

      def builds
        @__builds ||= units.select do |unit|
          unit.name =~ Pancakes::Fleet::Cluster::BUILD_REGEX#&& unit.active_state == 'active' && unit.sub_state == 'running'
        end
        .reduce({}) do |memo,unit|
          match = unit.name.match(Pancakes::Fleet::Cluster::BUILD_REGEX)
          build_name = match[:name]
          memo[build_name] ||= Hashie::Mash.new(
            build_name: build_name,
            build_codebase: match[:codebase],
            build_sha: match[:sha],
            build_id: match[:id].to_i,
            units: [],
            unit_types: [],
            machine: self
          )
          memo[build_name].units << unit
          memo[build_name].unit_types << match[:type]
          memo
        end
        .select do |_,build_info|
          # i think this select doesnt do anything
          rv = build_info.unit_types.sort == %w[app mysql] || build_info.unit_types.sort == %w[app db]
          puts "it does something!" if rv == false
          rv
        end
      end

      def has_capacity?
        capacity > 0
      end

      def capacity
        max_builds - builds.size
      end

      def worker?
        metadata.role == 'worker'
      end

      def etcd?
        metadata.role == 'etcd'
      end

      def max_builds
        if worker?
          PROD_WORKERS_MAX_BUILDS[ip] || 1
        else
          0
        end
      end

      def clear_worker_cache_for_codebase(codebase)
        raise("codebase must be real") unless codebase
        raise("codebase can't have dots") if codebase['.']
        system %Q[ssh core@#{ip} "sudo find /var/lib/docker/tmp/bundler -maxdepth 1 -name #{codebase}-* -exec rm -rfv {} \\;"]
      end

      def clear_aws_cache_for_codebase(codebase)
        raise("codebase must be real") unless codebase
        raise("codebase can't have dots") if codebase['.']
      end

      def to_s
        format(
          '#<Machine:0x%x id=%s ip=%s %d/%d',
          object_id << 1,
          id,
          ip,
          capacity,
          max_builds,
        )
      end
    end
  end
end
