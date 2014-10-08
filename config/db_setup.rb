namespace :db do

  task :setup, :roles => :db, :except => { :no_release => true } do
    with_servers do |servers|
      run 'rake db'
    end
  end

  def with_servers(&block)
    raise 'need to pass a block' unless block_given?
    servers = find_servers_for_task(current_task)

    if servers.any?
      yield servers
    end
  end

end

