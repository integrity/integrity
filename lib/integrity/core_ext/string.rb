class String
  def /(other)
    File.join(self, other)
  end
end