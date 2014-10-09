require File.join(File.dirname(__FILE__), 'utils')

namespace :db do
  task :setup, roles: :db, except: {no_release: true} do
    Utils.with_servers do |servers|
      run "cd '#{current_path}' && ln -s ../shared/db"
    end
  end
end

