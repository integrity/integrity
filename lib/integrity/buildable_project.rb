module Integrity
  class BuildableProject
    extend Forwardable
    include Bob::Buildable

    def_delegators :@project, :scm, :uri, :branch, :command

    alias_method :build_script, :command

    def self.call(payload)
      project = Project.first(:scm => payload["scm"],
        :uri => payload["uri"],
        :branch => payload["branch"]
      )

      return [] unless project

      payload["commits"].map { |commit| new(project, commit["id"]) }
    end

    attr_reader :commit

    def initialize(project, commit)
      @project = project
      @commit  = commit
    end

    def start_building(commit_id, commit_info)
      @project.commits.first_or_create({:identifier => commit_id},
        commit_info.merge(:build => Build.new(:started_at => Time.now)))
    end

    def finish_building(commit_id, status, output)
      if build = @project.commits.first(:identifier => commit_id).build
        # TODO
        build.successful = status
        build.output = output
        build.completed_at = Time.now
        build.save
        @project.enabled_notifiers.each { |n| n.notify_of_build(build) }
      end
    end
  end
end
