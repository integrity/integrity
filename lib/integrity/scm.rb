module Integrity
  module SCM
    def self.new(scm, config={})
      klass = scm.to_s.capitalize.gsub(/_(.)/) { $1.upcase }
      const_get(klass).new(config)
    rescue LoadError, NameError
      raise "could not find any SCM named `#{scm}'"
    end
  end
end
