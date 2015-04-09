require 'bundler/capistrano'
require 'erb'

set :deploy_env, ENV['DEPLOY_ENV']

if deploy_env == 'production'
  set :branch, 'master'
  set :server_host, 'integrity-2014-12-02-1b.test.grandrounds.com'
elsif deploy_env == 'dtest'
  set :branch, 'dtest'
  set :server_host, 'integrity-2015-02-25-1b.test.grandrounds.com'
else
  puts "i dont know about this...'#{env}' environment."
  exit 1
end

set :user, 'ubuntu'
set :use_sudo, false

set :application, 'integrity'
set :repository,  "git@github.com:ConsultingMD/#{application}.git"
set :deploy_to, "/home/ubuntu/app/#{application}"
set :deploy_via, :remote_cache
set :ssh_options, {forward_agent: true}
set :default_run_options, {shell: '/bin/bash', pty: true}

set :rvm_type, :system

set :rvm_require_role, :rvm
set :rvm_ruby_string, lambda {File.read('.ruby-version').strip + "@" + File.read('.ruby-gemset').strip}

require 'rvm/capistrano'

load 'config/overrides'
load 'config/upstart'
load 'config/restart'
load 'config/db_setup'
load 'config/delayed_job'

before 'deploy:setup', 'rvm:install_ruby'
after  'deploy:setup', 'write_upstart_envs'

# before 'deploy:restart', 'dj_restart'
after 'deploy:restart', 'dj_restart'

set :rails_env, 'production'
server server_host, :rvm, :dj_worker, :webapp, :db
