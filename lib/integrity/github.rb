require File.dirname(__FILE__) + '/../integrity'
require 'sinatra'
require 'json'

configure do
  Integrity.new
end

include Integrity

post '/:project' do
  content_type 'text/plain'

  project = Project.first(:permalink => params[:project])
  unknown_project! if project.nil?
  
  begin
    payload = JSON.parse(params[:payload] || "")
    payload['commits'].each_key { |commit| project.build(commit) }
    'Thanks, build started.'
  rescue JSON::ParserError => exception
    invalid_payload!(exception.to_s)
  end
end

helpers do
  def unknown_project!
    throw :halt, [404, "Unknown project `#{params[:project]}'"]
  end
  
  def invalid_payload!(msg=nil)
    throw :halt, [422, msg || 'No payload given']
  end
end