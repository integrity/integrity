namespace :deploy do

  task :restart, :roles => :webapp, :except => { :no_release => true } do
    with_servers do |servers|
      run "sudo restart integrity || sudo start integrity"
    end
  end

end
