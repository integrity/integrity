module IntegrityTest
  class BuilderStub < Integrity::Builder
    def self.for(repo, commit)
      new(
        "scm"    => repo.scm,
        "uri"    => repo.uri,
        "branch" => repo.branch,
        "commit" => commit,
        "command" => repo.command
      )
    end

    attr_reader :status, :output, :commit_info

    def initialize(buildable)
      super

      @status = nil
      @output = ""
      @commit_info = {}
    end

    def started(commit_info)
      @commit_info = commit_info
    end

    def completed(status, output)
      @status = status ? :successful : :failed
      @output = output
    end
  end
end
