# Helper method for tasks
def with_servers(&block)
  raise "need to pass a block" unless block_given?
  servers = find_servers_for_task(current_task)

  if servers.any?
    yield servers
  end
end

def db_path
  File.join(shared_path, 'db')
end

def db_url
  ENV['DATABASE_URL']
end

def integrity_db_url
  ENV['INTEGRITY_DATABASE_URL']
end

def jobs(action = :start)
  run "cd '#{current_path}' && RACK_ENV=#{rails_env} #{rake} delayed_job:#{action}"
end
