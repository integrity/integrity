#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/lib/integrity"
require "sinatra"

Sinatra::Application.default_options.merge!(
  :run  => false,
  :port => 8910,
  :env  => :production
)
 
require 'ui'
run Sinatra.application