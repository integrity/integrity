module Matchy::Expectations
  class ChangeExpectation < Base
    def initialize(receiver=nil, message=nil, test_case=nil, &block)
      @message = message || "result"
      @value_proc = block || lambda {
        receiver.__send__(message)
      }
      @test_case = test_case
    end

    def matches?(event_proc)
      raise_block_syntax_error if block_given?

      @before = evaluate_value_proc
      event_proc.call
      @after = evaluate_value_proc

      return false if @from unless @from == @before
      return false if @to unless @to == @after
      return (@before + @amount == @after) if @amount
      return ((@after - @before) >= @minimum) if @minimum
      return ((@after - @before) <= @maximum) if @maximum
      return @before != @after
    end

    def raise_block_syntax_error
      raise ArgumentError, "block passed to should or should_not change must use {} instead of do/end"
    end

    def evaluate_value_proc
      @value_proc.call
    end

    def failure_message
      if @to
        "#{@message} should have been changed to #{@to.inspect}, but is now #{@after.inspect}"
      elsif @from
        "#{@message} should have initially been #{@from.inspect}, but was #{@before.inspect}"
      elsif @amount
        "#{@message} should have been changed by #{@amount.inspect}, but was changed by #{actual_delta.inspect}"
      elsif @minimum
        "#{@message} should have been changed by at least #{@minimum.inspect}, but was changed by #{actual_delta.inspect}"
      elsif @maximum
        "#{@message} should have been changed by at most #{@maximum.inspect}, but was changed by #{actual_delta.inspect}"
      else
        "#{@message} should have changed, but is still #{@before.inspect}"
      end
    end

    def actual_delta
      @after - @before
    end

    def negative_failure_message
      "#{@message} should not have changed, but did change from #{@before.inspect} to #{@after.inspect}"
    end

    def by(amount)
      @amount = amount
      self
    end

    def by_at_least(minimum)
      @minimum = minimum
      self
    end

    def by_at_most(maximum)
      @maximum = maximum
      self
    end

    def to(to)
      @to = to
      self
    end

    def from (from)
      @from = from
      self
    end
  end


  module TestCaseExtensions
    def change(receiver=nil, message=nil, &block)
      Matchy::Expectations::ChangeExpectation.new(receiver, message, self, &block)
    end
  end
end
