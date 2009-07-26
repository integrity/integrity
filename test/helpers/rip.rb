module Haml
  module Version
    @@version = "2.2.2"
  end
end

# There is only one way to fight the devil: be even more evil.
# Less-evil solutions more than welcome ;-)

module Gem
  class Exception; end
  def gem(*args); false; end
end

include Gem

module Kernel
  alias :__integrity_orig_require :require

  def require(lib)
    return false if lib == "rubygems"
    __integrity_orig_require(lib)
  end
end
