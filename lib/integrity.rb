__DIR__ = File.dirname(__FILE__)
$:.unshift "#{__DIR__}/integrity", *Dir["#{__DIR__}/../vendor/**/lib"].to_a

require "rubygems"
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-types'
require 'dm-timestamps'
require 'dm-aggregates'

require 'yaml'
require 'digest/sha1'

require "core_ext/object"
require "core_ext/string"
require "core_ext/time"

%w(project build builder scm scm/git notifier).each &method(:require)

module Integrity
  def self.new(configuration_file=root/'config/config.yml')
    @config ||= default_configuration.merge load_config_file(configuration_file)
    DataMapper.setup(:default, config[:database_uri])
  end

  def self.root
    File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  def self.default_configuration
    { :database_uri => 'sqlite3::memory:',
      :export_directory => root / 'exports',
      :base_url => 'http://localhost:4567' }
  end

  def self.config
    @config
  end

  def self.load_config_file(file)
    YAML.load_file(file)
  rescue Errno::ENOENT
    {}
  end
end
