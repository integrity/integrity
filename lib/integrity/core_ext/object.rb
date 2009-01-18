class Object
  def tap
    yield self
    self
  end
  
  def singleton_class
    class << self; self; end
  end
  
  def singleton_def(name, &block)
    singleton_class.instance_eval do
      define_method(name, &block)
    end
  end
end