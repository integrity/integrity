module Integrity
  class ProjectBuilder
    def initialize(project)
      @project = project
      @uri = project.uri
      @build_script = project.command
      @branch = project.branch
      @scm = SCM.new(@uri, @branch, export_directory)
    end

    def build(commit)
      @commit = commit
      @build = commit.build
      @build.start!
      Integrity.log "Building #{commit.identifier} (#{@branch}) of #{@project.name} in #{export_directory} using #{@scm.name}"
      @scm.with_revision(commit.identifier) { run_build_script }
      @build
    ensure
      @build.complete!
      @commit.update_attributes(@scm.info(commit.identifier))
      @project.notifiers.each { |notifier| notifier.notify_of_build(@build) }
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

      def run_build_script
        Integrity.log "Running `#{@build_script}` in #{@scm.working_directory}"

        IO.popen "(cd #{@scm.working_directory} && #{@build_script}) 2>&1", "r" do |pipe|
          @build.output = pipe.read
        end
        @build.successful = $?.success?
      end
  end
end
