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

    def build(commit=nil)
      if commit
        @scm.with_revision(commit) { run_build_script }
      else
        @scm.with_latest_code { run_build_script }
      end
      @build
    ensure
      @build.commit = @scm.head
      @build.save
    end
    
    def delete_code
      FileUtils.rm_r export_directory
    rescue Errno::ENOENT
      nil
    end

    private
      def export_directory
        Integrity.config[:export_directory] /
          @uri.path[1..-1].sub('/', '-').chomp(@uri.extname)
      end

      def run_build_script
        IO.popen "(#{build_script}) 2>&1", "r" do |pipe|
          @build.output = pipe.read
        end
        @build.successful = $?.success?
      end
  end
end
