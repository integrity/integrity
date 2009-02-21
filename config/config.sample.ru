#!/usr/bin/env ruby
require "rubygems"
require "integrity"

# If you want to add any notifiers, install the gems and then require them here
# For example, to enable the Email notifier: install the gem (from github:
#
#   sudo gem install -s http://gems.github.com foca-integrity-email
#
# And then uncomment the following line:
#
# require "notifier/email"

# Load Integrity's configuration.
Integrity.config = File.dirname(__FILE__) + "/config.yml")

# You probably don't want to edit anything below
Integrity::App.set :environment, ENV["RACK_ENV"] || :production
Integrity::App.set :port,        8910

run Integrity::App
