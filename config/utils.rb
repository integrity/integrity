# Helper method for tasks
def with_servers(&block)
  raise "need to pass a block" unless block_given?
  servers = find_servers_for_task(current_task)

  if servers.any?
    yield servers
  end
end

def shared_path
  current_path.gsub('current', 'shared')
end

def db_path
  File.join(shared_path, 'db')
end
