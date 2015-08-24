module HonestyCluster
  module BundleCache
    extend self
    extend HonestyCluster::AwsClients

    BUCKETS = {
      development: 'grnds-development-coreos',
      test:        'gr-test-coreos',
    }

    def clear_aws_cache(env:, codebase:)
      validate_codebase(codebase)
      s3_client = s3_client(env)
      s3_client.delete_object(bucket: BUCKETS[env], key: cache_key(codebase))
    end

    def clear_cache(codebase:)
      %i[development test].each do |env|
        clear_aws_cache(env: env, codebase: codebase)
      end

      Pancakes.cluster.worker_machine_ips.each do |machine_ip|
        clear_machine_cache(machine_ip: machine_ip, codebase: codebase)
      end
    end

    def clear_machine_cache(machine_ip:, codebase:)
      validate_codebase(codebase)
      system %Q[ssh -o 'StrictHostKeyChecking no' core@#{machine_ip} "sudo find /var/lib/docker/tmp/bundler -maxdepth 1 -name #{codebase}-* -exec rm -rfv {} \\;"]
    end

    private def validate_codebase(codebase)
      raise("codebase must be real") unless codebase
      raise("codebase can't have dots") if codebase['.']
    end

    private def cache_key(codebase)
      format('bundler/%s-master.tar.gz', codebase)
    end
  end
end
