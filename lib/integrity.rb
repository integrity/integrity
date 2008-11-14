__DIR__ = File.dirname(__FILE__)
$:.unshift "#{__DIR__}/integrity", *Dir["#{__DIR__}/../vendor/**/lib"].to_a

require 'rubygems'
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

%w(project build builder scm scm/git notifier version).each &method(:require)

module Integrity
  def self.new
    DataMapper.setup(:default, config[:database_uri])
  end

  def self.root
    File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  def self.default_configuration
    @defaults ||= { :database_uri => 'sqlite3::memory:',
                    :export_directory => root / 'exports',
                    :base_uri => 'http://localhost:8910',
                    :use_basic_auth => false,
                    :port => 8910 }
  end

  def self.config
    @config ||= default_configuration
  end

  def self.config=(file)
    @config = default_configuration.merge(YAML.load_file(file))
  end
end
