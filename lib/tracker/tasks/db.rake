namespace :tracker do
  namespace :db do
    desc 'Run migrations'
    task :migrate, [:version] do |t, args|
      require 'sequel'
      Sequel.extension :migration
      db = Sequel.connect(ENV.fetch('DATABASE_URL'))
      if args[:version]
        puts "Migrating to version #{args[:version]}"
        Sequel::Migrator.run(db, 'db/migrations', target: args[:version].to_i)
      else
        puts 'Migrating to latest'
        Sequel::Migrator.run(db, 'db/migrations')
      end
    end

    desc 'Seed users table'
    task :seed do
      db = Sequel.connect(ENV.fetch('DATABASE_URL'))
      db.run('truncate tracker_users')
      db.run('truncate tracker_stories')
      db.run('truncate tracker_story_users')

      PivotalTracker::Client.token = ENV['PIVOTAL_TRACKER_TOKEN']
      PivotalTracker::Client.timeout = 50
      project = PivotalTracker::Project.find(ENV['TRACKER_PROJECT_ID'])

      memberships = project.memberships
      memberships.all.map{|u| Tracker::User.create(u)}

      Integrity::Branch.each do |branch|
        story_id = branch.name.try(:match, /\d{6,}/).try(:[],0)
        if story_id
          branch.story = Tracker::Story.get(story_id) || Tracker::Story.create(story_id)
          branch.save
        end
      end
    end
  end
end
