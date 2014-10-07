require 'bundler/capistrano'
require 'capistrano/ext/multistage'
require 'capistrano-deploytags'
require 'erb'

set :stages, %w(ci)
set :default_stage, "ci"
set :branch, 'master'

set :user, "ubuntu"
set :use_sudo, false

set :application, 'integrity'
set :repository,  'git@github.com:ConsultingMD/integrity.git'
set :deploy_to, "/home/ubuntu/app/integrity"
set :deploy_via, :remote_cache
set :ssh_options, { :forward_agent => true }

set :rvm_require_role, :rvm
set :rvm_ruby_string, lambda {File.read(".ruby-version").chop + "@" + File.read(".ruby-gemset").chop}
set :rvm_install_ruby_params, '--disable-binary'
set :rvm_install_ruby, :reinstall

require "rvm/capistrano"

before 'deploy:setup', 'rvm:install_rvm'
before 'deploy:setup', 'rvm:install_ruby'
