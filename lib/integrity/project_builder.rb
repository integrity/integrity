module Integrity
  class ProjectBuilder
    attr_reader :build_script

    def initialize(project)
      @uri = project.uri
      @build_script = project.command
      @branch = project.branch
      @scm = SCM.new(@uri, @branch, export_directory)
      @build = Build.new(:project => project)
    end

    def build(commit)
      Integrity.log "Building #{commit} (#{@branch}) of #{@build.project.name} in #{export_directory} using #{scm_name}"
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
        Integrity.config[:export_directory] / "#{SCM.working_tree_path(@uri)}-#{@branch}"
      end

      def scm_name
        @scm.name
      end

      def run_build_script
        Integrity.log "Running `#{build_script}` in #{@scm.working_directory}"

        IO.popen "(cd #{@scm.working_directory} && #{build_script}) 2>&1", "r" do |pipe|
          @build.output = pipe.read
        end
        @build.successful = $?.success?
      end
  end
end
