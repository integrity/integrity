require File.join(File.dirname(__FILE__), 'utils')

namespace :jobs do
  desc 'Start delayed job workers'
  task :start, roles: :worker, except: {no_release: true} do
    with_servers{ jobs :start }
  end

  desc 'Stop delayed job workers'
  task :stop, roles: :worker, except: {no_release: true} do
    with_servers{ jobs :stop }
  end

  desc 'Re-start delayed job workers'
  task :restart, roles: :worker, except: {no_release: true} do
    with_servers{ jobs :restart }
  end
end
