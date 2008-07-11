module Integrity
  class Builder
    def initialize(uri, branch, command)
      @uri = uri
      @command = command
      @scm = SCM.new(@uri.scheme, branch)
    end

    def build
      result = @scm.checkout(export_directory)
      build = Build.new
      build.error = result.error
      build.output = result.output
      build.result = result.success?
      return false if result.failure?
      Dir.chdir(export_directory) do
        Kernel.system(@command)
      end
    end

    private
      def export_directory
        Integrity.scm_export_directory /
          @uri.path[1..-1].sub('/', '-').chomp(@uri.extname)
      end
  end
end
