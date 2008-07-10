require 'open4'

module Integrity
  module SCM
    class Git
      def initialize(uri, options={})
        @uri = uri
        @options = options
      end

      def branch
        @options['branch'] || 'master'
      end

      def error
        @error ||= ''
      end

      def output
        @error ||= ''
      end

      def checkout(destination)
        execute "clone --depth 1 #{@uri.to_s} #{destination}"
        execute "--git-dir=#{destination} checkout #{branch}"
        execute "--git-dir=#{destination} pull"
      end

      private
        def execute(command)
          Open4.spawn "git #{command}", 'stdout' => output, 'stderr' => error
        end
    end
  end
end
