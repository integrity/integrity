module Integrity
  module SCM
    class Git
      require File.dirname(__FILE__) / "git/uri"

      attr_reader :uri, :branch, :working_directory

      def self.working_tree_path(uri)
        Git::URI.new(uri).working_tree_path
      end

      def initialize(uri, branch, working_directory)
        @uri = uri.to_s
        @branch = branch.to_s
        @working_directory = working_directory
      end
      
      def with_revision(revision)
        fetch_code
        checkout(revision)
        yield
      end

      def commit_identifier(sha1)
        `cd #{working_directory} && git show -s --pretty=format:%H #{sha1}`.chomp
      end

      def commit_metadata(sha1)
        format  = %Q(---%n:author: %an <%ae>%n:message: >-%n  %s%n:date: %ci%n)
        YAML.load(`cd #{working_directory} && git show -s --pretty=format:"#{format}" #{sha1}`)
      end
      
      private

        def fetch_code
          clone unless cloned?
          checkout unless on_branch?
          pull
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
          
          `cd #{working_directory} && git checkout #{strategy}`
        end

        def pull
          `cd #{working_directory} && git pull`
        end

        def local_branches
          `cd #{working_directory} && git branch`.split("\n").map {|b| b.delete("*").strip }
        end

        def cloned?
          File.directory?(working_directory / ".git")
        end

        def on_branch?
          File.basename(`cd #{working_directory} && git symbolic-ref HEAD`).chomp == branch
        end
    end
  end
end
