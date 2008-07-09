module Integrity
  module SCM
    # Adapter from Capistrano.
    def self.new(scm, config={})
      scm_file = "scm/#{scm}"
      Kernel.require(scm_file)

      klass = scm.to_s.capitalize.gsub(/_(.)/) { $1.upcase }
      if const_defined?(klass)
        const_get(klass).new(config)
      else
        raise "could not find `#{name}::#{klass}' in `#{scm_file}'"
      end
    rescue LoadError
      raise "could not find any SCM named `#{scm}'"
    end
  end
end
