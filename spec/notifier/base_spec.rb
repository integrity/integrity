require File.dirname(__FILE__) + "/../spec_helper"

describe Integrity::Notifier::Base do
  include AppSpecHelper
  include NotifierSpecHelper

  it "should raise on #deliver!" do
    @notifier = Integrity::Notifier::Base.new(mock_build, {})
    lambda { @notifier.deliver! }.should raise_error(NoMethodError, /you need to implement this method in your notifier/)
  end
end