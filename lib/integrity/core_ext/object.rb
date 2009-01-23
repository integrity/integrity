class Object
  def tap
    yield self
    self
  end
end
