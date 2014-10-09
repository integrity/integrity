require File.join(File.dirname(__FILE__), 'utils')

namespace :workers do
  task :start, roles: :worker, except: {no_release: true} do
    with_servers do |servers|
      run "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} "
    end
  end
end

