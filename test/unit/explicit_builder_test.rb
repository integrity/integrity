require 'helper'

class ExplicitBuilderTest < IntegrityTest
  class DoubleBuildError < StandardError
  end
  
  test 'adding builds' do
    builder = Integrity::ExplicitBuilder.new
    builder.enqueue(Build.gen)
  end
  
  test 'building' do
    builder = Integrity::ExplicitBuilder.new
    build = Build.gen
    mock(build).run!
    builder.enqueue(build)
    builder.wait!
  end
  
  test 'runs each build only once' do
    builder = Integrity::ExplicitBuilder.new
    build = Build.gen
    mock(build).run!
    builder.enqueue(build)
    builder.wait!
    
    # run! should not be called again
    stub(build).run! do
      raise DoubleBuildError
    end
    builder.wait!
  end
end
