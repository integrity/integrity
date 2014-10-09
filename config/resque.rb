require File.join(File.dirname(__FILE__), 'utils')

namespace :workers do
  task :start, roles: :worker, except: {no_release: true} do
    with_servers do |servers|
      run "cd '#{current_path}' && BACKGROUND=1 bundle exec rake resque:work"
    end
  end
end

