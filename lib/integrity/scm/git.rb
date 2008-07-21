module Integrity
  module SCM
    class Git
      attr_reader :uri, :branch, :working_directory
      
      def initialize(uri, branch, working_directory)
        @uri = uri.to_s
        @branch = branch.to_s
        @working_directory = working_directory
      end
      
      def with_revision(revision, &block)
        fetch_code
        checkout(revision)
        chdir(&block)
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
          `git clone #{uri} #{working_directory}`
        end
        
        def checkout(treeish=nil)
          strategy = case
            when treeish                         then treeish
            when local_branches.include?(branch) then branch
            else                                      "-b #{branch} origin/#{branch}"
          end
          
          chdir { `git checkout #{strategy}` }
        end
        
        def pull
          chdir { `git pull` }
        end
        
        def local_branches
          chdir do
            `git branch`.split("\n").map {|b| b.delete("*").strip }
          end
        end

        def commit_info(treeish)
          format  = %Q(---%n:identifier: %H%n:author: %an <%ae>%n:message: >-%n  %s%n)
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
