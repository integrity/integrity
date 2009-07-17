#!/usr/bin/env ruby
require "rubygems"
require "integrity"

Integrity.new(File.dirname(__FILE__) + "/config.yml")

map "/github/SECRET_TOKEN" do
  use Bobette::GitHub
  run Bobette.new(Bobette::BuildableProject)
end

map "/" do
  run Integrity::App
end
