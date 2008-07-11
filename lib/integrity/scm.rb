module Integrity
  module SCM
    def self.new(uri, *args)
      scm = uri.scheme
      klass = scm.capitalize.gsub(/_(.)/) { $1.upcase }
      const_get(klass).new(uri, *args)
    rescue LoadError, NameError
      raise "could not find any SCM named `#{uri.scheme}'"
    end
  end
end
