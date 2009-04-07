require "forwardable"

module Integrity
  class ProjectBuilder
    extend Forwardable

    attr_accessor  :project, :scm
    def_delegators :project, :name, :uri, :command, :branch

    def self.build(commit)
      new(commit.project).build(commit)
    end

    def self.delete_working_directory(project)
      new(project).delete_code
    end

    def initialize(project)
      @project = project
      @scm     = SCM.new(uri, branch, export_directory)
    end

    def build(commit)
      build = commit.build
      build.start!

      Integrity.log "Building #{commit.identifier} (#{branch}) of #{name} in" +
        "#{export_directory} using #{scm.name}"

      scm.with_revision(commit.identifier) do
        Integrity.log "Running `#{command}` in #{scm.working_directory}"

        IO.popen("(cd #{scm.working_directory} && #{command}) 2>&1", "r") {
          |output| build.output = output.read }
        build.successful = $?.success?
      end

      build
    ensure
      build.complete!
      commit.update_attributes(scm.info(commit.identifier) || {})
      project.notifiers.each { |notifier| notifier.notify_of_build(build) }
    end

    def delete_code
      FileUtils.rm_r export_directory
    rescue Errno::ENOENT
      nil
    end

    private
      def export_directory
        Integrity.config[:export_directory] / "#{SCM.working_tree_path(uri)}-#{branch}"
      end
  end
end
