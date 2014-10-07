set :application, 'integrity'
set :repository,  'git@github.com:ConsultingMD/integrity.git'


# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, '54.69.222.45'
role :app, '54.69.222.45'
role :db,  '54.69.222.45', :primary => true # This is where Rails migrations will run

after "deploy:restart", "deploy:cleanup"

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end