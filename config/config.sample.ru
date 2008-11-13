#!/usr/bin/env ruby
require "lib/integrity"
require "sinatra"

# If you want to add any notifiers, install the gems and then require them here
# For example, to enable the Email notifier: install the gem (from github: 
#
#   sudo gem install -s http://gems.github.com foca-integrity-email
# 
# And then uncomment the following line:
# 
# require "notifier/email"

# Load integrity's configuration.
Integrity.config = File.expand_path("./config.yml")

#######################################################################
##                                                                   ##
## == DON'T EDIT ANYTHING BELOW UNLESS YOU KNOW WHAT YOU'RE DOING == ##
##                                                                   ##
#######################################################################

Sinatra::Application.default_options.merge!(
  :run  => false,
  :port => Integrity.config[:port],
  :env  => :production
)
 
require "app"
run Sinatra.application
