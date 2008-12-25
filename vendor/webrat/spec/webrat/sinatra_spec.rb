$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require "rubygems"
require "spec"

require "webrat/sinatra"

require File.dirname(__FILE__) + "/sinatra/app"

describe "Webrat with Sinatra" do
  it "should work" do
    get "/"
    status.should == 200
    body.should == "hello world"

    get "/", :more => "foo"
    status.should == 200
    body.should == "foo"

    post "/", "foo"
    status.should == 200
    body.should == "foo"

    put "/", "foo"
    status.should == 200
    body.should == "foo"

    delete "/", :rev => "foo"
    status.should == 200
    body.should == "foo"
  end

  specify "#basic_auth should work" do
    basic_auth "admin", "password"
    get "/private"
    status.should == 200
  end
end
