class TrackerWrapper
  PivotalTracker::Client.token = ENV['PIVOTAL_TRACKER_TOKEN']
  PivotalTracker::Client.timeout = 50
  @project = PivotalTracker::Project.find(ENV['TRACKER_PROJECT_ID'])
end
