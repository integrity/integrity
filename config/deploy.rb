require 'bundler/capistrano'
require 'erb'
require 'rvm/capistrano'

set :deploy_env, ENV['DEPLOY_ENV']
set :branch, 'master'

if deploy_env == 'production'
  set :server_host, 'honesty-2015-04-13-1b.test.grandrounds.com'
elsif deploy_env == 'dtest'
  set :branch, 'develop'
  set :server_host, 'honesty-dtest-2015-04-13-1b.test.grandrounds.com'
else
  puts "i dont know about this...'#{deploy_env}' environment."
  exit 1
end

set :user, 'ubuntu'
set :use_sudo, false
set :application, 'honesty'
set :repository,  "git@github.com:ConsultingMD/#{application}.git"
set :deploy_to, "/home/ubuntu/app/#{application}"
set :deploy_via, :remote_cache
set :ssh_options, {forward_agent: true}
set :default_run_options, {shell: '/bin/bash', pty: true}
set :rvm_type, :system
#set :rvm_require_role, :rvm
set :rvm_ruby_string, lambda {File.read('.ruby-version').strip + "@" + File.read('.ruby-gemset').strip}
set :rails_env, 'production'
server server_host, :rvm, :dj_worker, :webapp, :db

before 'deploy:setup', 'rvm:install_ruby'
after  'deploy:setup', 'write_upstart_envs'

namespace :db do
  task :setup, roles: :db, except: {no_release: true} do
    run "cd #{current_path} && bundle exec rake db"
  end
end

namespace :pancakes do
  namespace :db do
    task :migrate, roles: :db, except: {no_release: true} do
      run "cd #{current_path} && bundle exec rake pancakes:db:migrate"
    end
  end
end

namespace :tracker do
  namespace :db do
    task :seed_users, roles: :db, except: {no_release: true} do
      run "cd #{current_path} && bundle exec rake tracker:db:seed_users"
    end

    task :seed_epics, roles: :db, except: {no_release: true} do
      run "cd #{current_path} && bundle exec rake tracker:db:seed_epics"
    end

    task :seed_stories, roles: :db, except: {no_release: true} do
      run "cd #{current_path} && bundle exec rake tracker:db:seed_stories"
    end
  end
end

desc 'Write upstart environment file'
task :write_upstart_envs do
  ruby_gemset  = File.read('.ruby-gemset').strip
  ruby_version = File.read('.ruby-version').strip
  template = File.read('upstart-envs.erb')
  File.new('upstart-envs', 'w').write(ERB.new(template).result(binding))
end

namespace :deploy do
  task :restart, roles: :webapp, except: {no_release: true} do
    run "sudo restart #{application} || sudo start #{application}"
  end

  desc 'Our override to prevent absent directories public/images, public/stylesheets, and public/javascripts from raising No such file or directory'
  task :finalize_update, except: {no_release: true} do
    escaped_release = latest_release.to_s.shellescape
    commands = []
    commands << "chmod -R -- g+w #{escaped_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    shared_children.map do |dir|
      d = dir.shellescape
      commands << "rm -rf -- #{escaped_release}/#{d}"
      if pos = dir.rindex('/')
        commands << "mkdir -p -- #{escaped_release}/#{dir.slice(0..pos).shellescape}"
      end
      commands << "ln -s -- #{shared_path}/#{dir.split('/').last.shellescape} #{escaped_release}/#{d}"
    end

    run commands.join(' && ') if commands.any?
  end
end
