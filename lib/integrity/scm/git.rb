require 'open3'

module Integrity
  module SCM
    class Git
      def initialize(uri, branch, logger)
        @uri = uri.to_s
        @logger = logger
        @branch = branch
      end

      def checkout(destination)
        execute "clone --depth 1 #{@uri.to_s} #{destination}" unless cloned?(destination)
        execute "--git-dir=#{destination}/.git checkout #{@branch}" unless on_branch?(destination)
        execute "--git-dir=#{destination}/.git pull"
        true
      rescue RuntimeError
        false
      end

      private
        def execute(command)
          Open3.popen3 "git #{command}" do |_, stdout, stderr|
            @logger.output << stdout.read
            @logger.error << stderr.read
            raise unless $?.success?
          end
        end

        def cloned?(working_directory)
          File.exists?(working_directory / '.git')
        end

        def on_branch?(working_directory)
          File.read(working_directory).split('/').last.chomp == @branch
        end
    end
  end
end
