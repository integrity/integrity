ROOT_DIR = File.expand_path('..', __FILE__)

$LOAD_PATH.unshift(File.join(ROOT_DIR, 'lib'))

begin
  require '.bundle/environment'
rescue LoadError
  require 'bundler/setup'
end

require 'integrity'

# Notifiers - Uncomment as appropriate for the notifier you want to use
# require "integrity/notifier/email"    # = Email
# require "integrity/notifier/ses"      # = SES Email
# require "integrity/notifier/campfire" # = Campfire
# require "integrity/notifier/flowdock" # = Flowdock
# require "integrity/notifier/tcp"      # = TCP
# require "integrity/notifier/http"     # = HTTP
# require "integrity/notifier/amqp"     # = AMQP
# require "integrity/notifier/shell"    # = Shell
# require "integrity/notifier/coop"     # = Co-op

Integrity.configure do |c|
  c.database                    = ENV['INTEGRITY_DATABASE_URL']  # DataMapper database connection URI
  c.username                    = ENV['INTEGRITY_USERNAME']      # Admin username
  c.password                    = ENV['INTEGRITY_PASSWORD']      # Admin password
  c.directory                   = '/tmp/docker/builds'           # Parent directory for builds, relative to Integrity root
  c.base_url                    = 'http://http://0.0.0.0:9292/'  # URL to the root of Integrity installation, used in notification emails.
  c.log                         = 'integrity.log'                # Where to write the log file.
  c.github_token                = ENV['GITHUB_TOKEN']            # Enable GitHub post-receive hook
  c.github_account              = 'ConsultingMD'                 # Name of primary github account, usually owner of token.
  c.build_all                   = false                          # If true, build all commits. If false, only build HEAD after each push
  c.auto_branch                 = true                           # Automatically create projects for newly pushed branches
  c.trim_branches               = true                           # Automatically delete projects when their corresponding branches are deleted
  c.builder                     = :resque                        # Which builder to use [:threaded, :delayed_job, :resque]
  c.project_default_build_count = 10                             # How many builds to show by default on project pages
  c.build_output_interval       = 5                              # How often to collect build output from running builds (in secs)
  c.status_image_always_public  = false                          # Make status public for all projects? If false, login required to see status for private projects.

  # Use https://github.com/grahamc/git-cachecow to cache repository locally
  # c.checkout_proc             = Proc.new do |runner, repo_uri, branch, sha1, target_directory|
  #   runner.run! "git scclone #{repo_uri} #{target_directory} #{sha1}"
  # end
end
