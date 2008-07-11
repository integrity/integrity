module Integrity
  class Builder
    def initialize(uri, options={})
      @uri = Addressable::URI.parse(uri)
      @scm = SCM.new(@uri.scheme, options[:scm])
    end

    def build
      @scm.checkout(export_directory)
    end

    private
      def export_directory
        Integrity.scm_export_directory /
          @uri.path[1..-1].sub('/', '-').chomp(@uri.extname)
      end
  end
end
