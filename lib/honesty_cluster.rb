module HonestyCluster
  def self.cluster
    Pancakes.cluster
  end

  module Turds

    REPOS_WHICH_CANT_BUILD = %w[
      engineering
      twinkleshine
      warehouse
      metal
      puppet
    ]

    def self.deturd_all
      %w[
        deturd_reset_failed
        deturd_orphaned_mysqls
        deturd_fleet_units_for_repos_which_cant_build
        deturd_fleet_failed_units
      ].each do |turd|
        puts format('*** DETURDING %s ***', turd)
        send(turd)
        puts
        puts
      end
      nil
    end

    def self.deturd_reset_failed
      HonestyCluster.cluster.reset_failed_all
    end

    def self.deturd_orphaned_mysqls
      worker_ips = HonestyCluster.cluster.worker_machine_ips.join(' ')
      system <<-HERE
for ip in #{worker_ips}; do
    echo "cleaning ${ip}"
    docker -H tcp://${ip}:2375 ps | grep mysql | grep -v pancakes | grep 'hours\\|days' | awk '{print $1}' | xargs -r docker -H tcp://${ip}:2375 rm -f
done
      HERE
    end

    def self.deturd_search_and_destroy(&block)
      HonestyCluster.cluster.build_units.select do |unit|
        block.call(unit)
      end
      .each do |unit|
        puts "destroying unit #{unit.name} active_state=#{unit.active_state} sub_state=#{unit.sub_state}"
        HonestyCluster.cluster.client.destroy(unit.name)
      end
    end

    def self.deturd_fleet_units_for_repos_which_cant_build
      deturd_search_and_destroy do |unit|
        REPOS_WHICH_CANT_BUILD.map do |repo|
          unit.name.start_with?("#{repo}_")
        end
        .reduce(false) do |memo,val|
          memo || val
        end
      end
    end

    def self.deturd_fleet_failed_units
      deturd_search_and_destroy do |unit|
        (unit.active_state == 'inactive' && unit.sub_state == 'dead') ||
        (unit.active_state == 'failed' && unit.sub_state == 'failed')
      end
    end
  end
end


require 'coreext/docker/container'
require 'honesty_cluster/aws_clients'
require 'honesty_cluster/bundle_cache'
require 'honesty_cluster/honesty_event'
require 'honesty_cluster/swarm_backend'
require 'honesty_cluster/swarm_backend/service'
require 'honesty_cluster/swarm_backend/stack'
