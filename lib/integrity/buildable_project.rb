module Integrity
  class BuildableProject
    def self.call(buildable)
      return [] unless project = Project.first(
        :scm    => buildable["scm"],
        :uri    => buildable["uri"],
        :branch => buildable["branch"]
      )
      buildable["commits"].collect { |c| new(project, c["id"]) }
    end

    def initialize(project, commit)
      @project = project
      @commit  = commit
    end

    def build
      b = @project.builds.create(:commit => {:identifier => @commit})
      Integrity.config.builder.build(b)
      b
    end
  end
end
