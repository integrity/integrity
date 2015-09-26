require 'spec_helper'
require 'honesty_cluster/swarm_backend'

describe HonestyCluster::SwarmBackend::Pancakes do

  class MockStack
    include HonestyCluster::SwarmBackend::Pancakes::InstanceMethods

    def name
      'foo'
    end
  end

  describe 'works' do
    pass
  end
end

