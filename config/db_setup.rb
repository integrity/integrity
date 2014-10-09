require File.join(File.dirname(__FILE__), 'utils')

namespace :db do
  task :setup, roles: :db, except: {no_release: true} do
    Utils.with_servers do |servers|
      run "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} db"
    end
  end
end

