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
  ps_dj = "ps -ef | grep delayed_job | grep -v grep | grep -v logger"
  run "#{ps_dj} && #{ps_dj} | awk '{print $2}' | xargs kill || true"
  #run "cd #{current_path} && #{rake} jobs:daemons:restart || #{rake} jobs:daemons:start"
  run "cd #{current_path} && bundle exec /home/ubuntu/app/integrity/current/script/delayed_job restart || bundle exec /home/ubuntu/app/integrity/current/script/delayed_job start"
end
