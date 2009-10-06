module Matchy::Expectations
  class BeAExpectation < Base
    def matches?(receiver)
      @receiver = receiver
      @receiver.is_a?(@expected)
    end

    def failure_message
      "Expected #{@receiver.inspect} to be a #{@expected.inspect}."
    end

    def negative_failure_message
      "Expected #{@receiver.inspect} to not be a #{@expected.inspect}."
    end
  end

  module TestCaseExtensions
    def be_a(obj)
      Matchy::Expectations::BeAExpectation.new(obj, self)
    end
    alias :be_an :be_a
  end
end
