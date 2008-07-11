require 'open4'

module Integrity
  module SCM
    Result = Struct.new(:output, :error, :status) do
      %w(success failure).each do |state|
        define_method("#{state}?") { self.status == state }
        define_method("#{state}!") do
          self.status = state
          self
        end
      end
    end

    class Git
      def initialize(uri, options={})
        @uri = uri
        @options = options
      end

      def branch
        @options['branch'] || 'master'
      end

      def checkout(destination)
        result = Result.new

        execute "clone --depth 1 #{@uri.to_s} #{destination}", result
        execute "--git-dir=#{destination} checkout #{branch}", result
        execute "--git-dir=#{destination} pull", result
        result.success!
      rescue
        result.failure!
      end

      private
        def execute(command, logger)
          Open4.spawn "git #{command}",
            'stdout' => logger.output, 'stderr' => logger.error
        end
    end
  end
end
