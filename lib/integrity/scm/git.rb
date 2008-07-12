require 'open3'

module Integrity
  module SCM
    class Git
      def initialize(uri, branch, logger)
        @uri = uri.to_s
        @logger = logger
        @branch = branch
      end

      def checkout_script(destination)
        [].tap do |script|
          script << "git clone --depth 1 #{@uri.to_s} #{destination}" unless cloned?(destination)
          script << "git --git-dir=#{destination}/.git checkout #{@branch}" unless on_branch?(destination)
          script << "git --git-dir=#{destination}/.git pull"
        end.compact
      end

      private
        def cloned?(working_directory)
          File.directory?(working_directory / '.git')
        end

        def on_branch?(working_directory)
          File.read(working_directory / '.git/HEAD').split('/').last.chomp == @branch
        end
    end
  end
end
