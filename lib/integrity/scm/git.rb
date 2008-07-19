module Integrity
  module RubyGit # name collissions! :-\
    require Integrity.root / "vendor" / "ruby-git" / "lib" / "git"
    
    def self.open(*args)
      Git.open(*args)
    end
    
    def self.clone(*args)
      Git.clone(*args)
    end
  end

  module SCM
    class Git
      attr_reader :uri, :branch, :working_directory
      
      def initialize(uri, branch, working_directory)
        @uri = uri.to_s
        @branch = branch.to_s
        @working_directory = working_directory
      end
      
      def with_latest_code(&block)
        fetch_code
        chdir(&block)
      end
      
      def head
        if @head
          @head
        else
          commit = repo.object("HEAD")
          @head = { :author => "#{commit.author.name} <#{commit.author.email}>",
                    :identifier => repo.revparse("HEAD"),
                    :message => commit.message }
        end
      end
      
      private

        def repo
          @repo ||= RubyGit.open(working_directory)
        rescue ArgumentError
          @repo = RubyGit.clone(uri, working_directory)
        end
        
        def fetch_code
          repo.checkout(branch) unless repo.branch.name == branch
          repo.pull
        end
      
        def chdir(&in_working_copy)
          repo.chdir(&in_working_copy)
        end
    end
  end
end
