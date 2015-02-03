require File.join(File.dirname(__FILE__), 'utils')

desc 'Start delayed job'
task :dj_start, roles: :dj_worker do
  run "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} delayed_job:start"
end

desc 'Stop delayed job'
task :dj_stop, roles: :dj_worker do
  run "cd '#{current_path}' && RAILS_ENV=#{rails_env} #{rake} delayed_job:stop"
end

desc 'Re-start delayed job'
task :dj_restart, roles: :dj_worker do
  run "cd '#{current_path}' && RAILS_ENV=#{rails_env} rake delayed_job:restart"
end
