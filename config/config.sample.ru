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

# Load integrity's configuration.
Integrity.config = File.expand_path("./config.yml")

#######################################################################
##                                                                   ##
## == DON'T EDIT ANYTHING BELOW UNLESS YOU KNOW WHAT YOU'RE DOING == ##
##                                                                   ##
#######################################################################
require Integrity.root / "app"

set     :public,  Integrity.root / "public"
set     :views,   Integrity.root / "views"
set     :port,    8910
set     :env,     :production
disable :run,     :reload

use Rack::CommonLogger, Integrity.logger if Integrity.config[:log_debug_info]
run Sinatra::Application
