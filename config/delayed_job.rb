require File.join(File.dirname(__FILE__), 'utils')

desc "Start delayed job"
task :dj_start do
  jobs :start
end

desc "Stop delayed job"
task :dj_stop do
  jobs :stop
end

desc "Re-start delayed job"
task :dj_restart, roles: :dj_worker do
  jobs :restart
end
