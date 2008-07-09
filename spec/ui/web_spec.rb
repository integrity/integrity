require File.dirname(__FILE__) + '/../spec_helper'

require 'sinatra'
require 'spec/interop/test'
require 'sinatra/test/unit'

describe 'Web UI using Sinatra' do
  require File.dirname(__FILE__) + '/../../lib/integrity/ui/web'

  it 'should be success' do
    get_it '/'
    @response.should be_ok
  end
end
