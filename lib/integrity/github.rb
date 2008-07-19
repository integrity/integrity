require 'rubygems'
require 'json'

require File.dirname(__FILE__) + '/../integrity'
require 'sinatra'

configure do
  Integrity.new
end

include Integrity

post '/' do
  content_type 'text/plain'
  begin
    payload = JSON.parse(params[:payload] || '')
    unless project = Project.first(:name => payload['repository']['name'])
      throw :halt, [400, "Unknown project `#{payload['repository']['name']}'"]
    else
      payload['commits'].each_key { |commit| project.build(commit) }
    end
    'Thanks, build started.'
  rescue JSON::ParserError => exception
    throw :halt, [422, exception.to_s]
  end
end
