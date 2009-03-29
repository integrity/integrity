module Integrity
  class Project
    module Helpers
      module Deprecated
        def last_build
          warn "Project#last_build is deprecated, use Project#last_commit (#{caller[0]})"
          last_commit
        end

        def previous_builds
          warn "Project#previous_builds is deprecated, use Project#previous_commits (#{caller[0]})"
          previous_commits
        end
      end
    end
  end
end
