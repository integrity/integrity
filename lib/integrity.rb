__DIR__ = File.dirname(__FILE__)
Dir["#{__DIR__}/../vendor/**/lib"].each { |dependency| $: << dependency }
$: << "#{__DIR__}/integrity"

require "rubygems"
require "core_ext/string"

module Integrity
  def root
    File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end
  
  module_function :root

  autoload :Builder, 'builder'
  autoload :SCM,     'scm'

  module SCM
    autoload :Git, 'scm/git'
  end
end
