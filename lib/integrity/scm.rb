module Integrity
  module SCM
    def self.new(scm, *args)
      klass = scm.to_s.capitalize.gsub(/_(.)/) { $1.upcase }
      const_get(klass).new(*args)
    rescue LoadError, NameError
      raise "could not find any SCM named `#{scm}'"
    end

    Result = Struct.new(:output, :error, :status) do
      %w(success failure).each do |state|
        define_method("#{state}?") { self.status == state }
        define_method("#{state}!") do
          self.status = state
          self
        end
      end
    end
  end
end
