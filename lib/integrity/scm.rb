module Integrity
  module SCM
    class SCMUnknownError < StandardError; end

    def self.new(uri, *args)
      scm_class_for(uri).new(uri, *args)
    end

    def self.working_tree_path(uri)
      scm_class_for(uri).working_tree_path(uri)
    end

    private
      def self.scm_class_for(uri)
        return Git if uri.scheme == "git" || uri.path =~ /\.git\/?/
        raise SCMUnknownError, "could not find any SCM based on URI '#{uri.to_s}'"
      end
  end
end