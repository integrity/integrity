#!/usr/bin/env ruby
require File.dirname(__FILE__) + "/integrity-config"

Integrity::App.set(:environment, ENV["RACK_ENV"] || :production)
Integrity::App.disable(:run, :reload)
run Integrity::App

