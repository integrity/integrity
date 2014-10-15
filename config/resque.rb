require File.join(File.dirname(__FILE__), 'utils')

namespace :workers do
  task :start, roles: :worker, except: {no_release: true} do
    with_servers do |servers|
      run "source .bash_profile && pkill resque-1.25.2 && cd '#{current_path}' && rq integrity"
    end
  end
end

