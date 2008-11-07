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
  
      def self.scm_class_for(string)
        case string.to_s
          when /\.git\/?/ then Git
          else raise SCMUnknownError, "could not find any SCM based on string '#{string}'"
        end
      end
  end
end
