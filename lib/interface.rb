module Interface
  def interface_method(name)
    define_method(name) { |*args|
      raise "interface method #{name} not implemented in #{self.class}"
    }
  end
end
