module Integrity
  module Helpers
    def build_payload
      payload  = Payload.new(params[:payload])
      projects = ProjectFinder.find(payload.uri, payload.branch)
      builds   = []
      projects.each { |project|
        if Integrity.config.build_all?
          payload.commits.each { |commit|
            builds << project.builds.create(:commit => commit)
          }
        else
          builds << project.builds.create(:commit => payload.head)
        end
      }
      builds.each { |b| b.run }
      builds.size.to_s
    end
  end
end
