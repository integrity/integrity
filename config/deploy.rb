require 'bundler/capistrano'
require 'erb'

set :branch, 'master'

set :user, 'ubuntu'
set :use_sudo, false

set :application, 'integrity'
set :repository,  "git@github.com:ConsultingMD/#{application}.git"
set :deploy_to, "/home/ubuntu/app/#{application}"
set :deploy_via, :remote_cache
set :ssh_options, {forward_agent: true}

set :rvm_type, :system

set :rvm_require_role, :rvm
set :rvm_ruby_string, lambda {File.read('.ruby-version').strip + "@" + File.read('.ruby-gemset').strip}

require 'rvm/capistrano'

load 'config/overrides'
load 'config/upstart'
load 'config/restart'
load 'config/db_setup'
load 'config/workers'

before 'deploy:setup', 'rvm:install_ruby'
after  'deploy:setup', 'write_upstart_envs'

before 'deploy:restart', 'workers:restart'

set :rails_env, 'test'
server 'integrity-2014-12-02-1b.test', :rvm, :worker, :webapp, :db
