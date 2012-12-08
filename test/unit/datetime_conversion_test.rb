require "helper"

class DatetimeConversionTest < IntegrityTest
=begin We no longer care but leave this for debugging purposes
  setup do
    assert !Object.const_defined?(:ActiveSupport), 'activesupport should not be loaded'
  end
=end
  
  it 'converts DateTime.now to Time' do
    dt = DateTime.now
    time = Integrity.datetime_to_utc_time(dt)
    assert time.is_a?(Time)
  end
  
  it 'converts DateTime with 0 offset to Time' do
    dt = DateTime.now
    dt = dt.new_offset(0)
    assert_equal 0, dt.offset
    time = Integrity.datetime_to_utc_time(dt)
    assert time.is_a?(Time)
  end
  
  it 'converts DateTime with non-0 offset to Time' do
    dt = DateTime.now
    dt = dt.new_offset(Rational(-5, 24))
    assert_equal Rational(-5, 24), dt.offset
    time = Integrity.datetime_to_utc_time(dt)
    assert time.is_a?(Time)
  end
end
