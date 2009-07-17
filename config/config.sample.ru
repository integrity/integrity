#!/usr/bin/env ruby
require "rubygems"
require "integrity"

Integrity.new(File.dirname(__FILE__) + "/config.yml")
run Integrity::App
