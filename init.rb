$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

begin
  require ".bundle/environment"
rescue LoadError
  require "bundler/setup"
end

require "integrity"

# Uncomment as appropriate for the notifier you want to use
# = Email
# require "integrity/notifier/email"
# = SES Email
# require "integrity/notifier/ses"
# = Campfire
# require "integrity/notifier/campfire"
# = TCP
# require "integrity/notifier/tcp"
# = HTTP
# require "integrity/notifier/http"
# = AMQP
# require "integrity/notifier/amqp"
# = Shell
# require "integrity/notifier/shell"
# = Co-op
# require "integrity/notifier/coop"

Integrity.configure do |c|
  # DataMapper database connection URI
  c.database                    = "sqlite3:db/integrity.db"
  # PostgreSQL via the local socket to "integrity" database:
  # c.database                  = "postgres:///integrity"
  # PostgreSQL via a more full specification:
  # c.database                  = "postgres://user:pass@host:port/database"
  # On Heroku:
  # c.database                  = ENV['DATABASE_URL']
  
  # Parent directory for builds, relative to Integrity root
  c.directory                   = "builds"
  # If running on Heroku:
  # c.directory                 = File.dirname(__FILE__) + '/tmp/builds'
  
  # URL to the root of Integrity installation, used in notification emails:
  c.base_url                    = "http://ci.example.org"
  
  # Where to write the log file.
  # If running on Heroku, comment out c.log
  c.log                         = "integrity.log"
  
  # Enable GitHub post-receive hook
  c.github_token                = "SECRET"
  
  # If true, build all commits. If false, only build HEAD after each push
  c.build_all                   = true
  
  # Automatically create projects for newly pushed branches
  c.auto_branch                 = false
  
  # When auto_branch is enabled, automatically delete projects when
  # their corresponding branches are deleted
  c.trim_branches               = false
  
  # Which builder to use. Please refer to the documentation for the list
  # of builders and their limitations
  c.builder                     = :threaded, 5
  
  # How many builds to show by default on project pages
  c.project_default_build_count = 10
  
  # How often to collect build output from running builds
  c.build_output_interval       = 5

  # Make status badge public for all projects? Otherwise, login is
  # required to see status badge for private projects.
  c.status_image_always_public  = true

  # Use https://github.com/grahamc/git-cachecow to cache repository locally
  # c.checkout_proc             = Proc.new do |runner, repo_uri, branch, sha1, target_directory|
  #   runner.run! "git scclone #{repo_uri} #{target_directory} #{sha1}"
  # end
end
