require File.join(File.dirname(__FILE__), 'utils')

desc 'Start delayed job'
task :dj_start, roles: :dj_worker do
  run "cd '#{current_path}' && #{rake} delayed_job:start"
end

desc 'Stop delayed job'
task :dj_stop, roles: :dj_worker do
  run "cd '#{current_path}' && #{rake} delayed_job:stop"
end

desc 'Re-start delayed job'
task :dj_restart, roles: :dj_worker do
  # run "cd '#{current_path}' && #{rake} jobs:daemons:restart"
  # run "cd '#{current_path}'; #{rake} jobs:daemons:restart"
  check_jobs
  kill_delayed_job
  check_jobs
  run "cd '#{current_path}' && #{rake} jobs:daemons:start"
  check_jobs
end
