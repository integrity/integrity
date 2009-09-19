module Integrity
  class BuildableProject
    extend Forwardable
    include Bob::Buildable

    def_delegators :@project, :scm, :uri, :branch, :command

    alias_method :build_script, :command

    def self.call(payload)
      project = Project.first(
        :scm    => payload["scm"],
        :uri    => payload["uri"],
        :branch => payload["branch"]
      )

      return [] unless project

      payload["commits"].map { |commit| new(project, commit["id"]) }
    end

    def initialize(project, commit_id)
      @project   = project
      @commit    = project.commits.first_or_create(:identifier => commit_id)
      @commit_id = commit_id
    end

    def commit
      @commit_id
    end

    def start_building
      @build = Build.create(:commit => @commit, :started_at => Time.now)
    end

    def finish_building(commit_info, status, output)
      if commit == :head
        @project.commits.first(:identifier => "head").destroy
        @commit = @project.commits.first_or_create(:identifier => commit_info["identifier"])
      end

      @commit.update(commit_info)
      @build.update(
        :commit       => @commit,
        :successful   => status,
        :output       => output,
        :completed_at => Time.now
      )
      @project.enabled_notifiers.each { |n| n.notify_of_build(@build) }
    end
  end
end
