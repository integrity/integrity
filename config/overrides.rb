# this file overrides the default task in capistrano-2.15.4/lib/capistrano/recipes/deploy.rb

namespace :deploy do
  desc 'Our override to prevent absent directories public/images, public/stylesheets, and public/javascripts from raising No such file or directory'
  task :finalize_update, except: {no_release: true} do
    escaped_release = latest_release.to_s.shellescape
    commands = []
    commands << "chmod -R -- g+w #{escaped_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    shared_children.map do |dir|
      d = dir.shellescape
      commands << "rm -rf -- #{escaped_release}/#{d}"
      if pos = dir.rindex('/')
        commands << "mkdir -p -- #{escaped_release}/#{dir.slice(0..pos).shellescape}"
      end
      commands << "ln -s -- #{shared_path}/#{dir.split('/').last.shellescape} #{escaped_release}/#{d}"
    end

    run commands.join(' && ') if commands.any?
  end
end
