#!/usr/bin/env ruby
require "rubygems"
require "integrity"

# Load configuration and initialize Integrity
Integrity.new(File.dirname(__FILE__) + "/config.yml")

# You probably don't want to edit anything below
Integrity::App.set :environment, ENV["RACK_ENV"] || :production
Integrity::App.set :port,        8910

run Integrity::App
