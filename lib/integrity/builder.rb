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
      build_script.each do |command|
        execute command
        break unless successful_execution?
      end
      @build
    end

    private
      def export_directory
        Integrity.config[:export_directory] /
          @uri.path[1..-1].sub('/', '-').chomp(@uri.extname)
      end

      def execute(command)
        Open3.popen3 command do |_, stdout, stderr|
          @build.output << stdout.read
          @build.error << stderr.read
          @build.status = successful_execution?
        end
      end
    
      def successful_execution?
        $?.success?
      end
      
      def build_script
        [@scm.checkout_script(export_directory), "cd #{export_directory}", @command].flatten
      end
  end
end
