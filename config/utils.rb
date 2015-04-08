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

def jobs(action = :start)
  run "cd '#{current_path}' && #{rake} jobs:daemons:#{action}"
end

def check_jobs
  run 'ps -ef | grep job | grep -v grep | grep -v logger'
end

def kill_delayed_job
  run "pid=`ps -ef | grep delayed_job | grep -v grep | grep -v logger | awk '{print $2}'`; kill $pid"
end
