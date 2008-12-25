require "rubygems"
require "sinatra"
require File.dirname(__FILE__) + "/authorization"

get "/" do
  "hello world"
end

post "/" do
  request.body.read
end

put "/" do
  request.body.read
end

delete "/" do
  params[:rev]
end

get "/private" do
  login_required
end

get "/more" do
  params[:more]
end

helpers do
  include Sinatra::Authorization

  def authorize(username, password)
    username == "admin" && password == "password"
  end
end
