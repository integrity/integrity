# http://kavassalis.com/2013/04/unicorn-hot-restarts-my-definitive-guide/
require 'logger'
worker_processes 2
timeout 30
pid 'tmp/pids/unicorn.pid'
listen '/tmp/honesty.sock', backlog: 64
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
GC.copy_on_write_friendly = true

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = '/home/ubuntu/app/honesty/current/Gemfile'
end

#before_fork do |server,worker|
  #Pancakes.disconnect
#end

#after_fork do |server,worker|
  #Pancakes.connect
#end
