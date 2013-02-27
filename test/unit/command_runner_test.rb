require "helper"

class CommandRunnerTest < IntegrityTest
  test "simple command output" do
    logger = Logger.new('/dev/null')
    runner = CommandRunner.new(logger)
    
    result = runner.run('echo hello world')
    assert result.success
    assert_equal 'hello world', result.output
  end
  
  test "command output to stderr" do
    logger = Logger.new('/dev/null')
    runner = CommandRunner.new(logger)
    
    result = runner.run('echo hello world 1>&2')
    assert result.success
    # standard error is collected with standard output
    assert_equal 'hello world', result.output
  end
  
  test "running a command that fails" do
    logger = Logger.new('/dev/null')
    runner = CommandRunner.new(logger)
    
    result = runner.run('(exit 1)')
    assert !result.success
    assert_equal '', result.output
  end
  
  test "running a malformed shell command" do
    logger = Logger.new('/dev/null')
    runner = CommandRunner.new(logger)
    
    result = runner.run('if (')
    assert !result.success
    assert result.output =~ /Syntax error/
  end
  
  test "collecting output chunks" do
    logger = Logger.new('/dev/null')
    runner = CommandRunner.new(logger)
    
    chunked_output = ''
    result = runner.run('echo hello world') do |chunk|
      chunked_output += chunk
    end
    assert result.success
    assert_equal 'hello world', result.output
    # newline is removed from final output by CommandRunner
    assert_equal "hello world\n", chunked_output
  end
end
