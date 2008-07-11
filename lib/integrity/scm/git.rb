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
        execute "clone --depth 1 #{@uri.to_s} #{destination}"
        execute "--git-dir=#{destination}/.git checkout #{@branch}"
        execute "--git-dir=#{destination}/.git pull"
        true
      rescue RuntimeError
        false
      end

        def execute(command)
          Open3.popen3 "git #{command}" do |_, stdout, stderr|
            @logger.output << stdout.read
            @logger.error << stderr.read
            raise unless $?.success?
          end
        end
    end
  end
end
