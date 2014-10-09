require File.join(File.dirname(__FILE__), 'utils')

namespace :deploy do
  include Utils
  task :restart, roles: :webapp, except: {no_release: true} do
    with_servers do |servers|
      run "sudo restart integrity || sudo start integrity"
    end
  end
end

