ROOT_DIR = File.expand_path('..', __FILE__)

$LOAD_PATH.unshift(File.join(ROOT_DIR, 'lib'))

begin
  require '.bundle/environment'
rescue LoadError
  require 'bundler/setup'
end

require 'i18n'
I18n.load_path << "#{ROOT_DIR}/config/locale/dates.en.yml"

require 'integrity'

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

base_url = %x{ hostname }
base_url << env.rack unless base_url['.local']

Integrity.configure do |c|
  c.database                    = env.database.url        # DataMapper database connection URI
  c.username                    = env.auth.username       # Admin username
  c.password                    = env.auth.password       # Admin password
  c.directory                   = '/tmp/docker/builds'    # Parent directory for builds, relative to Integrity root
  c.base_url                    = base_url
  # # URL to the root of Integrity installation, used in notification emails.
  c.log                         = 'integrity.log'         # Where to write the log file.
  c.github_read_token           = env.github.tokens.read  # Enable GitHub post-receive hook
  c.github_write_token          = env.github.tokens.write # Auth for posting to GitHub (statuses)
  c.github_secret               = env.github.tokens.secret # Auth for GitHub post-receive hook
  c.github_account              = env.github.account      # Name of primary github account, usually owner of token.
  c.build_all                   = false                   # If true, build all commits. If false, only build HEAD after each push
  c.auto_branch                 = true                    # Automatically create projects for newly pushed branches
  c.trim_branches               = true                    # Automatically delete projects when their corresponding branches are deleted
  c.builder                     = :threaded               # Which builder to use [:threaded, :delayed_job, :resque, :explicit]
  c.project_default_build_count = 10                      # How many builds to show by default on project pages
  c.build_output_interval       = 5                       # How often to collect build output from running builds (in secs)
  c.status_image_always_public  = false                   # Make status public for all projects? If false, login required to see status for private projects.

  # Use https://github.com/grahamc/git-cachecow to cache repository locally
  # c.checkout_proc             = Proc.new do |runner, repo_uri, branch, sha1, target_directory|
  #   runner.run! "git scclone #{repo_uri} #{target_directory} #{sha1}"
  # end
end
