ROOT_DIR = File.expand_path('..', __FILE__)

ENV['DATABASE_URL'] = 'mysql2://integrity:MyPassword@gruzii5m6o5mis.c61hxobewq2s.us-east-1.rds.amazonaws.com/integrity'

$LOAD_PATH.unshift(File.join(ROOT_DIR, 'lib'))

begin
  require '.bundle/environment'
rescue LoadError
  require 'bundler/setup'
end

require 'i18n'
I18n.load_path << "#{ROOT_DIR}/config/locale/dates.en.yml"
require 'integrity'

DataMapper::Logger.new(STDOUT, :debug)

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

env = RConfig.application

base_url = 'http://' << %x{ hostname }
base_url << env.rack.to_s unless base_url['.local']

Integrity.configure do |c|
  c.database                    = env.database.url          # DataMapper database connection URI
  c.username                    = env.auth.username         # Admin username
  c.password                    = env.auth.password         # Admin password
  c.directory                   = env.builds.dir            # Parent directory for builds, relative to Integrity root
  c.base_url                    = base_url                  # URL to the root of Integrity installation, used in notification emails.
  c.logs_url                    = env.logs.url              # URL to papertrail logs for containers
  c.log                         = env.logs.file             # Where to write the log file.
  c.github_read_token           = env.github.tokens.read    # Enable GitHub post-receive hook
  c.github_write_token          = env.github.tokens.write   # Auth for posting to GitHub (statuses)
  c.github_secret               = env.github.tokens.secret  # Auth for GitHub post-receive hook
  c.github_account              = env.github.account        # Name of primary github account, usually owner of token.
  c.trim_branches               = env.builds.trim_branches  # Automatically delete projects when their corresponding branches are deleted
  c.builder                     = :dj, env.database         # Which builder to use [:threaded, :delayed, :resque, :explicit]
  c.max_running_builds          = env.builds.max_running    # Maximum umber of builds to run per worker machine
  c.project_default_build_count = env.builds.display_count  # How many builds to show by default on project pages
  c.build_output_interval       = env.builds.interval       # How often to collect build output from running builds (in secs)
  c.status_image_always_public  = false                     # ake status public for all projects? If false, login required to see status for private projects.

  # Use https://github.com/grahamc/git-cachecow to cache repository locally
  # c.checkout_proc             = Proc.new do |runner, repo_uri, branch, sha1, target_directory|
  #   runner.run! "git scclone #{repo_uri} #{target_directory} #{sha1}"
  # end
end
