module Integrity
  class Builder
    def initialize(uri, options={})
      @uri = uri
      @scm = SCM.new(@uri.scheme, options[:scm])
    end

    def build
      result = @scm.checkout(export_directory)
      build = Build.new
      build.error = result.error
      build.output = result.output
      build.result = result.success?
    end

    private
      def export_directory
        Integrity.scm_export_directory /
          @uri.path[1..-1].sub('/', '-').chomp(@uri.extname)
      end
  end
end
