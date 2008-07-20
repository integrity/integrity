module Integrity
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

      def with_revision(revision, &block)
        fetch_code
        checkout(revision)
        chdir(&block)
      ensure
        checkout('origin/HEAD')
      end
      
      def head
        @head ||= commit_info("HEAD")
      end
      
      private
        
        def fetch_code
          clone unless cloned?
          checkout unless on_branch?
          pull
        end
        
        def chdir(&in_working_copy)
          Dir.chdir(working_directory, &in_working_copy)
        end
    
        def clone
          system "git clone #{uri} #{working_directory}"
        end
        
        def checkout(treeish=nil)
          if treeish
            chdir { system "git checkout #{treeish}" }
          else
            chdir { system "git checkout -b #{branch} origin/#{branch}" }
          end
        end
        
        def pull
          chdir { system "git pull" }
        end

        def commit_info(treeish)
          format  = "---%n:identifier: %H%n:author: %an <%ae>%n:message: %s%n"
          chdir { YAML.load(`git show -s --pretty=format:"#{format}" #{treeish}`) }
        end
        
        def cloned?
          File.directory?(working_directory / ".git")
        end
        
        def on_branch?
          chdir { File.basename(`git symbolic-ref HEAD`).chomp == branch }
        end
    end
  end
end
