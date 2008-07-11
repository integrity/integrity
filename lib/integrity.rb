__DIR__ = File.dirname(__FILE__)
Dir["#{__DIR__}/../vendor/**/lib"].each { |dependency| $: << dependency }
$: << "#{__DIR__}/integrity"

require "rubygems"
require 'dm-core'
require 'addressable/uri'

require 'yaml'

require "core_ext/string"

module Integrity
  @@root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
  @@default_configuration_file = @@root / 'config/config.sample.yml'
  @@default_configuration = {
    :database_uri => 'sqlite3://memory',
    :export_directory => @@root / 'exports'
  }

  def self.root
    @@root
  end

  def self.default_configuration
    @@default_configuration
  end

  def self.config
    # TODO: @config ||= YAML.load_file(@configuration_file)
    default_configuration.merge(YAML.load_file(@configuration_file))
  end

  def self.new(configuration_file=@@default_configuration_file)
    @configuration_file = configuration_file
    DataMapper.setup(:default, config[:database_uri])
  end


  autoload :Project, 'project'
  autoload :Build,   'build'
  autoload :Builder, 'builder'
  autoload :SCM,     'scm'

  module SCM
    autoload :Git, 'scm/git'
  end
end
