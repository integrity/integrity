module Pancakes
  module Fleet
    class Machine < Hashie::Trash
      property :id, required: true
      property :ip, required: true, from: 'primaryIP'
      property :metadata, required: true, transform_with: lambda { |v| Hashie::Mash.new(v)  }

      PROD_WORKERS_MAX_BUILDS = {
        "10.0.80.21" => 2,
        "10.0.80.31" => 2,
      }

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
