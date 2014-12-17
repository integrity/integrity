require File.join(File.dirname(__FILE__), 'utils')

namespace :workers do
  desc 'Start delayed job workers'
  task :start, roles: :worker, except: {no_release: true} do
    with_servers do
      run "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} jobs:daemons:start"
    end
  end

  desc 'Stop delayed job workers'
  task :stop, roles: :worker, except: {no_release: true} do
    with_servers do
      run "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} jobs:daemons:stop"
    end
  end

  desc 'Re-start delayed job workers'
  task :restart, roles: :worker, except: {no_release: true} do
    with_servers do
      run "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} jobs:daemons:restart"
    end
  end
end

