module Interface
  def interface_method(name)
    define_method(name) { |*args|
      raise "interface method #{name} not implemented"
    }
  end
end
