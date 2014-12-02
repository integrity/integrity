$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

begin
  require ".bundle/environment"
rescue LoadError
  require "bundler/setup"
end

require 'integrity'

# Don't modify this file.
# Please use local.rb to configure your Integrity instance.

Integrity.configure do |c|
  # Options are explained in local.rb.example
  c.database                    = 'sqlite3:db/integrity.db'
  c.directory                   = 'builds'
  c.base_url                    = 'http://ci.example.org'
  c.build_all                   = true
  c.auto_branch                 = false
  c.trim_branches               = false
  c.builder                     = :threaded, 5
  c.project_default_build_count = 10
  c.build_output_interval       = 5
  c.status_image_always_public  = false
end

local_config = File.expand_path('../local.rb', __FILE__)
if File.exist?(local_config)
  load local_config
end
