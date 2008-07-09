__DIR__ = File.dirname(__FILE__)
$:.unshift "#{__DIR__}/sinatra/lib", "#{__DIR__}/integrity", "#{__DIR__}/core_ext", "#{__DIR__}/ui"

require "rubygems"
require "string"

module Integrity
  def root
    File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end
  
  module_function :root

  autoload :Builder, 'builder'
  autoload :SCM,     'scm'
end
