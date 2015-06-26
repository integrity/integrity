namespace :tracker do
  namespace :db do
    desc 'Seed users table'
    task :seed do
      db = Sequel.connect(ENV.fetch('DATABASE_URL'))
      db.run('truncate tracker_users')
      db.run('truncate tracker_stories')
      db.run('truncate tracker_story_users')

      client = TrackerApi::Client.new(token: ENV['PIVOTAL_TRACKER_TOKEN'])
      project = client.project(ENV['PIVOTAL_TRACKER_PROJECT_ID'])
      stories = project.stories

      memberships = project.memberships.map(&:person)
      memberships.map{|u| Tracker::User.create(u)}

      branches = Integrity::Branch.select{|branch| branch.name.try(:match, /\d{6,}/).try(:[],0)}

      branches.each do |branch|
        story_id = branch.name.try(:match, /\d{6,}/).try(:[],0)
        if story_id
          tracker_story = stories.select{|s| s.id == story_id}.first

          if Tracker::Story.get(story_id)
            story = Tracker::Story.get(story_id)
          else
            story = Tracker::Story.create(story_id, tracker_story)
          end

          branch.story = story
          branch.save
        end
      end
    end
  end
end
