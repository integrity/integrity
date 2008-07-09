module Integrity
  class Builder
    def initialize(uri, options={})
      @uri = URI.parse(uri)
      @options = options
      @scm = SCM.new(@uri.scheme, options[:scm])
    end
  end
end
