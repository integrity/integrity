module Matchy::Expectations
  class PredicateExpectation < Base
    def initialize(predicate, *arguments)
      @test_case = arguments.pop
      @predicate = predicate
      @arguments = arguments
    end

    def matches?(receiver)
      @receiver = receiver
      @receiver.send("#{@predicate}?", *@arguments)
    end

    def failure_message
      message = "Expected #{@receiver.inspect} to be #{@predicate}"
      message << " with #{@arguments.map {|e| e.inspect }.join(", ")}" unless @arguments.empty?
      message
    end

    def negative_failure_message
      message = "Expected #{@receiver.inspect} not to be #{@predicate}"
      message << " with #{@arguments.map {|e| e.inspect }.join(", ")}" unless @arguments.empty?
      message
    end
  end

  module TestCaseExtensions
    def method_missing(method, *args, &block)
      if method.to_s =~ /^be_(.*)/
        args << self
        Matchy::Expectations::PredicateExpectation.new($1, *args)
      else
        super
      end
    end
  end
end
