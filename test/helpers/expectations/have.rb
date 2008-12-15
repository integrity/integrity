module Matchy::Expectations
  class HaveExpectation < Base
    def initialize(expected, relativity=:exactly, test_case = nil)
      @expected = (expected == :no ? 0 : expected)
      @relativity = relativity
      @test_case = test_case
    end

    def relativities
      @relativities ||= {
        :exactly => "",
        :at_least => "at least ",
        :at_most => "at most "
      }
    end

    def matches?(collection_owner)
      if collection_owner.respond_to?(@collection_name)
        collection = collection_owner.__send__(@collection_name, *@args, &@block)
      elsif (@plural_collection_name && collection_owner.respond_to?(@plural_collection_name))
        collection = collection_owner.__send__(@plural_collection_name, *@args, &@block)
      elsif (collection_owner.respond_to?(:length) || collection_owner.respond_to?(:size))
        collection = collection_owner
      else
        collection_owner.__send__(@collection_name, *@args, &@block)
      end
      @given = collection.size if collection.respond_to?(:size)
      @given = collection.length if collection.respond_to?(:length)
      raise not_a_collection if @given.nil?
      return @given >= @expected if @relativity == :at_least
      return @given <= @expected if @relativity == :at_most
      return @given == @expected
    end

    def not_a_collection
      "expected #{@collection_name} to be a collection but it does not respond to #length or #size"
    end

    def failure_message
      "expected #{relative_expectation} #{@collection_name}, got #{@given}"
    end

    def negative_failure_message
      if @relativity == :exactly
        return "expected target not to have #{@expected} #{@collection_name}, got #{@given}"
      elsif @relativity == :at_most
        return <<-EOF
Isn't life confusing enough?
Instead of having to figure out the meaning of this:
should_not have_at_most(#{@expected}).#{@collection_name}
We recommend that you use this instead:
should have_at_least(#{@expected + 1}).#{@collection_name}
EOF
      elsif @relativity == :at_least
        return <<-EOF
Isn't life confusing enough?
Instead of having to figure out the meaning of this:
should_not have_at_least(#{@expected}).#{@collection_name}
We recommend that you use this instead:
should have_at_most(#{@expected - 1}).#{@collection_name}
EOF
      end
    end

    def description
      "have #{relative_expectation} #{@collection_name}"
    end

    def respond_to?(sym)
      @expected.respond_to?(sym) || super
    end

    private

    def method_missing(sym, *args, &block)
      @collection_name = sym
      if inflector = (defined?(ActiveSupport::Inflector) ? ActiveSupport::Inflector : (defined?(Inflector) ? Inflector : nil))
        @plural_collection_name = inflector.pluralize(sym.to_s)
      end
      @args = args
      @block = block
      self
    end

    def relative_expectation
      "#{relativities[@relativity]}#{@expected}"
    end
  end

  
  module TestCaseExtensions
    def have(n)
      HaveExpectation.new(n, :exactly, self)
    end
    alias :have_exactly :have
    
    def have_at_least(n)
      HaveExpectation.new(n, :at_least, self)
    end
    
    def have_at_most(n)
      HaveExpectation.new(n, :at_most, self)
    end
  end
end