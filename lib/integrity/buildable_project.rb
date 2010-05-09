module Integrity
  def self.auto_branch?
    auto_branch == true
  end

  class BuildableProject
    def self.call(buildable)
      projects = Project.all(:uri.like => "#{buildable["uri"]}%")

      # OMG WTF
      if ! Integrity.auto_branch?
        projects = projects.all(:branch => buildable["branch"])
      elsif project = projects.first(:branch => buildable["branch"])
        projects = [project]
      elsif project = projects.first(:branch => "master")
        projects = Array(
          Project.create(
            project.attributes.update(
              :id     => nil,
              :name   => "#{project.name} (#{buildable["branch"]})",
              :branch => buildable["branch"]
            )
          )
        )
      else
        return []
      end

      projects.inject([]) { |acc, p|
        acc.concat buildable["commits"].collect { |c| new(p, c["id"]) }
      }
    end

    def initialize(project, commit)
      @build = project.builds.create(:commit => {:identifier => commit})
    end

    def build
      @build.tap { |b| Integrity.builder.call(b) }
    end
  end
end
