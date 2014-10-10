# http://kavassalis.com/2013/04/unicorn-hot-restarts-my-definitive-guide/
worker_processes 4
timeout 30
pid 'tmp/pids/unicorn.pid'
listen '/tmp/integrity.sock', backlog: 64
stderr_path 'log/unicorn.stderr.log'
stdout_path 'log/unicorn.stdout.log'
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
GC.copy_on_write_friendly = true

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = '/home/ubuntu/app/integrity/current/Gemfile'
end
