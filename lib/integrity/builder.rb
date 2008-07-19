require 'open3'
require 'fileutils'

module Integrity
  class Builder
    attr_reader :build_script
    
    def initialize(project)
      @uri = project.uri
      @build_script = project.command
      @scm = SCM.new(@uri, project.branch, export_directory)
      @build = Build.new(:project => project)
    end

    def build
      @scm.with_latest_code { run_build_script }
      @build
    ensure
      @build.commit = @scm.head
      @build.save
    end
    
    def delete_code
      FileUtils.rm_r export_directory
    end

    private
      def export_directory
        Integrity.config[:export_directory] /
          @uri.path[1..-1].sub('/', '-').chomp(@uri.extname)
      end

      def run_build_script
        Open3.popen3 build_script do |_, stdout, stderr|
          @build.output << stdout.read
          @build.error << stderr.read
          @build.successful = successful_execution?
        end
      end
    
      def successful_execution?
        $?.success?
      end
  end
end
