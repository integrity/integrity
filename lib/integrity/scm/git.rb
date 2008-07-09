require 'grit'

module Integrity
  module SCM
    class Git
      def initialize(uri, options={})
        @options = options
        @uri = uri.is_a?(URI) ? uri : URI.parse(uri)
        export_directory = Integrity.scm_export_directory / @uri.path.
          gsub(/^\//, '').gsub('/', '-').gsub('.git', '')
        @git = Grit::Git.new(export_directory)
      end

      def branch
        @options['branch'] || 'master'
      end

      def origin
        @uri.to_s
      end

      def destination
        @git.git_dir
      end

      def checkout
        @git.clone({:depth => 1}, origin, destination)
        @git.checkout(branch)
      end
    end
  end
end
