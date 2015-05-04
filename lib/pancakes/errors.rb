module Pancakes
  class TimeoutError < StandardError ; end

  class ClusterError < StandardError
    attr_accessor :original

    def self.new_with_original(orig_err)
      me = new
      me.original = orig_err
      me
    end

    def class
      @original ? @original.class : super
    end

    def message
      @original ? @original.message : super
    end
  end
end
