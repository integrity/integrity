require 'bundler/capistrano'
require 'capistrano/ext/multistage'
require 'capistrano-deploytags'
require 'erb'

set :stages, %w(development)
set :default_stage, 'development'
set :branch, 'master'

set :user, 'ubuntu'
set :use_sudo, false

set :application, 'integrity'
set :repository,  'git@github.com:ConsultingMD/integrity.git'
set :deploy_to, '/home/ubuntu/app/integrity'
set :deploy_via, :remote_cache
set :ssh_options, {forward_agent: true}

set :rvm_require_role, :rvm
set :rvm_ruby_string, lambda {File.read('.ruby-version').strip + "@" + File.read('.ruby-gemset').strip}
set :rvm_install_ruby_params, '--disable-binary'

require 'rvm/capistrano'
load 'config/overrides'
load 'config/upstart'
load 'config/restart'
load 'config/db_setup'

before 'deploy:setup', 'rvm:install_rvm'
before 'deploy:setup', 'rvm:install_ruby'
after  'deploy:setup', 'write_upstart_envs'
before 'deploy:restart', 'db:setup'
