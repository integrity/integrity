ROOT_DIR = File.expand_path('..', __FILE__)

ENV['DATABASE_URL'] = 'mysql2://dtest:MyPassword@gruzii5m6o5mis.c61hxobewq2s.us-east-1.rds.amazonaws.com/integrity_dtest'

$LOAD_PATH.unshift(File.join(ROOT_DIR, 'lib'))

begin
  require '.bundle/environment'
rescue LoadError
  require 'bundler/setup'
end

require 'i18n'
I18n.load_path << "#{ROOT_DIR}/config/locale/dates.en.yml"
require 'integrity'

logger = DataMapper::Logger.new(STDOUT, :debug)

# I18n Translations
translations = YAML.load_file(File.join(File.dirname(__FILE__), 'config', 'locale', 'en.yml'))
I18n.backend.store_translations(:en, translations)

# Notifiers - Uncomment as appropriate for the notifier you want to use
require 'integrity/notifier/github'     # = Github commit status
require 'integrity/notifier/email'      # = Email
# require 'integrity/notifier/ses'      # = SES Email
# require 'integrity/notifier/campfire' # = Campfire
# require 'integrity/notifier/flowdock' # = Flowdock
# require 'integrity/notifier/tcp'      # = TCP
# require 'integrity/notifier/http'     # = HTTP
# require 'integrity/notifier/amqp'     # = AMQP
# require 'integrity/notifier/shell'    # = Shell
# require 'integrity/notifier/coop'     # = Co-op

app = RConfig.application

ENV['RACK_ENV'] = (app.environment || :production).to_s

if app.environment.to_sym == :production
  base_url = 'https://integrity.test.grandrounds.com/'
else
  base_url = 'http://' << %x{ hostname }
  base_url << app.rack.to_s unless base_url['.local']
end

Integrity.configure do |c|
  c.environment                 = app.environment           # Environment to run in (i.e. development, production, etc).
  c.database                    = app.database.url          # DataMapper database connection URI
  c.username                    = app.auth.username         # Admin username
  c.password                    = app.auth.password         # Admin password
  c.directory                   = app.builds.dir            # Parent directory for builds, relative to Integrity root
  c.base_url                    = base_url                  # URL to the root of Integrity installation, used in notification emails.
  c.logs_url                    = app.logs.url              # URL to papertrail logs for containers
  c.log                         = app.logs.file             # Where to write the log file.
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
  c.logger                      = logger
  # Use https://github.com/grahamc/git-cachecow to cache repository locally
  # c.checkout_proc             = Proc.new do |runner, repo_uri, branch, sha1, target_directory|
  #   runner.run! "git scclone #{repo_uri} #{target_directory} #{sha1}"
  # end
end

# Try to queue pending builds on start
Integrity.start
