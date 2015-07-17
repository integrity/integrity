namespace :tracker do
  namespace :db do
    desc 'Seed users table'
    task :seed_users do
      db = Sequel.connect(ENV.fetch('DATABASE_URL'))
      db.run('truncate tracker_users')

      client = TrackerApi::Client.new(token: ENV['PIVOTAL_TRACKER_TOKEN'])
      project = client.project(ENV['PIVOTAL_TRACKER_PROJECT_ID'])

      memberships = project.memberships.map(&:person)
      memberships.map{|u| Tracker::User.create(u)}
    end

    desc 'Seed stories table from existing integrity branches'
    task :seed_stories do
      db = Sequel.connect(ENV.fetch('DATABASE_URL'))
      db.run('truncate tracker_stories')
      db.run('truncate tracker_story_users')

      Rake::Task["tracker:db:seed_users"].invoke

      client = TrackerApi::Client.new(token: ENV['PIVOTAL_TRACKER_TOKEN'])
      project = client.project(ENV['PIVOTAL_TRACKER_PROJECT_ID'])

      stories = project.stories
      story_ids = stories.map(&:id)

      branches = Integrity::Branch.select{|branch| branch.name.try(:match, /\d{6,}/).try(:[],0)}
      branches.each do |branch|
        story_id = branch.name.scan(/\d{6,}/).last.to_i
        if story_ids.include?(story_id)
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

      current_stories = stories.select{|s| ["started", "finished"].include?(s.current_state)}
      current_stories.each do |story|
        unless Tracker::Story.get(story.id)
          Tracker::Story.create(story.id, story)
        end
      end
    end
  end
end
