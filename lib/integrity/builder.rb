require 'open3'

module Integrity
  class Builder
    def initialize(uri, branch, command)
      @uri = uri
      @command = command
      @build = Build.new
      @scm = SCM.new(@uri, branch, @build)
    end

    def build
      @scm.checkout(export_directory)
      return false if @build.failure?
      run_command
      @build
    end

    private
      def export_directory
        Integrity.config[:export_directory] /
          @uri.path[1..-1].sub('/', '-').chomp(@uri.extname)
      end

      def run_command
        Dir.chdir(export_directory) do
          Open3.popen3(@command) do |_, stdout, stderr|
            @build.output << stdout.read
            @build.error  << stderr.read
            @build.status = successful_command?
          end
        end
      end
      
      def successful_command?
        $?.success?
      end
  end
end
