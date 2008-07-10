__DIR__ = File.dirname(__FILE__)
Dir["#{__DIR__}/../vendor/**/lib"].each { |dependency| $: << dependency }
$: << "#{__DIR__}/integrity"

require "rubygems"
require 'dm-core'
require 'yaml'
require "core_ext/string"

module Integrity
  def self.root
    File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  def self.new(configuration_file=self.root + '/../config.yml')
    config = YAML.load_file(configuration_file)
    DataMapper.setup(:default, config[:database_uri])
  end

  autoload :Models,  'models'
  autoload :Builder, 'builder'
  autoload :SCM,     'scm'

  module SCM
    autoload :Git, 'scm/git'
  end
end
