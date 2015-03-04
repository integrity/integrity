DATABASE_URL = ENV['DATABASE_URL'] ||= ENV['INTEGRITY_DATABASE_URL'].to_s.gsub('mysql:', 'mysql2:') unless defined?(DATABASE_URL)
ROOT_DIR     = File.expand_path('..', __FILE__) unless defined?(ROOT_DIR)
RACK_ENV     = ENV['RACK_ENV'] = (app.environment || :production).to_s

$LOAD_PATH.unshift(File.join(ROOT_DIR, 'lib'))

require 'setup'
require 'integrity'
require 'notifiers'

app = RConfig.application

if app.environment.to_sym == :production
  base_url = 'https://integrity.test.grandrounds.com/'
else
  base_url = 'http://' << %x{ hostname }
  base_url << app.rack.to_s unless base_url['.local']
end

Integrity.configure do |c|
  c.environment                 = app.environment           # Environment to run in (i.e. development, production, etc).
  c.database                    = app.database.url          # DataMapper database connection URI
  c.auth                        = app.auth.type
  c.username                    = app.auth.username         # Admin username
  c.password                    = app.auth.password         # Admin password
  c.directory                   = app.builds.dir            # Parent directory for builds, relative to Integrity root
  c.base_url                    = base_url                  # URL to the root of Integrity installation, used in notification emails.
  c.github_read_token           = app.github.tokens.read    # Enable GitHub post-receive hook
  c.github_write_token          = app.github.tokens.write   # Auth for posting to GitHub (statuses)
  c.github_secret               = app.github.tokens.secret  # Auth for GitHub post-receive hook
  c.github_account              = app.github.account        # Name of primary github account, usually owner of token.
  c.trim_branches               = app.builds.trim_branches  # Automatically delete projects when their corresponding branches are deleted
  c.builder                     = :dj, app.database         # Which builder to use [:threaded, :delayed, :resque, :explicit]
  c.max_running_builds          = app.builds.max_running    # Maximum number of builds to run per worker machine
  c.max_run_time                = app.builds.max_run_time   # Maximum number of minutes a build can run before being orphaned.
  c.project_default_build_count = app.builds.display_count  # How many builds to show by default on project pages
  c.build_output_interval       = app.builds.interval       # How often to collect build output from running builds (in secs)
  c.status_image_always_public  = false                     # ake status public for all projects? If false, login required to see status for private projects.

  # Logging: Defaults to STDOUT which it captured by logentries
  #  * logs_url - Set a url for papertrail to log build/container output.
  #  * log - Set a file to log to and use the standard ruby logger.
  #  * logger - Create a custom logger if you dont want to just log to a file or use integrity logger
  c.logs_url                    = app.logs.url              # URL to papertrail logs for containers
  # c.log                       = app.logs.file             # Where to write the log file.
  # c.logger                    = logger                    # Custom logger class to use.

  # Use https://github.com/grahamc/git-cachecow to cache repository locally
  # c.checkout_proc             = Proc.new do |runner, repo_uri, branch, sha1, target_directory|
  #   runner.run! "git scclone #{repo_uri} #{target_directory} #{sha1}"
  # end
end

require 'users'
