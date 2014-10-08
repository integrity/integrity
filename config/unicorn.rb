# http://kavassalis.com/2013/04/unicorn-hot-restarts-my-definitive-guide/
worker_processes 4
timeout 30
pid "tmp/pids/unicorn.pid"
listen "/tmp/jarvis.sock", :backlog => 64
stderr_path "log/unicorn.stderr.log"
stdout_path "log/unicorn.stdout.log"
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
GC.copy_on_write_friendly = true

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "/home/ubuntu/app/jarvis/current/Gemfile"
end

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
