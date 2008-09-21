require 'fileutils'

module Integrity
  class Builder
    attr_reader :build_script

    def initialize(project)
      @uri = project.uri
      @build_script = project.command
      @branch = project.branch
      @scm = SCM.new(@uri, @branch, export_directory)
      @build = Build.new(:project => project)
    end

    def build(commit)
      @scm.with_revision(commit) { run_build_script }
      @build
    ensure
      @build.commit_identifier = @scm.commit_identifier(commit)
      @build.commit_metadata = @scm.commit_metadata(commit)
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
          @uri.path[1..-1].sub('/', '-').chomp(@uri.extname) + "-#{@branch}"
      end

      def run_build_script
        IO.popen "(#{build_script}) 2>&1", "r" do |pipe|
          @build.output = pipe.read
        end
        @build.successful = $?.success?
      end
  end
end
