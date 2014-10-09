require 'utils'

namespace :workers do
  task :start, roles: :worker, except: {no_release: true} do
    Utils.with_servers do |servers|
      run "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} "
    end
  end
end

