module Integrity
  module SCM
    autoload :Git, "integrity/scm/git"
    autoload :Svn, "integrity/scm/svn"

    class Error < StandardError; end

    # Factory to return appropriate SCM instances
    def self.new(scm, uri, branch)
      const_get(scm.to_s.capitalize).new(uri, branch)
    end
  end
end
