namespace :tracker do
  namespace :db do
    desc 'Seed users table'
    task :seed do
      db = Sequel.connect(ENV.fetch('DATABASE_URL'))
      db.run('truncate tracker_users')
      db.run('truncate tracker_stories')
      db.run('truncate tracker_story_users')

      PivotalTracker::Client.token = ENV['PIVOTAL_TRACKER_TOKEN']
      PivotalTracker::Client.timeout = 50
      project = PivotalTracker::Project.find(ENV['TRACKER_PROJECT_ID']).first
      stories = project.stories.all(offset: 6000)

      memberships = project.memberships
      memberships.all.map{|u| Tracker::User.create(u)}

      Integrity::Branch.each do |branch|
        story_id = branch.name.try(:match, /\d{6,}/).try(:[],0)
        if story_id
          tracker_story = stories.select{|s| s.id = story_id}.first
          branch.story = Tracker::Story.get(story_id) || Tracker::Story.create(story_id, tracker_story)
          branch.save
        end
      end
    end
  end
end
