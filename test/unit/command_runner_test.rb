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
    assert result.output =~ /Syntax error/i
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
  
  test "collecting output chunks when timeout happens before first output" do
    logger = Logger.new('/dev/null')
    runner = CommandRunner.new(logger, 0.1)
    
    chunked_output = ''
    result = runner.run('sleep 0.5; echo hello world') do |chunk|
      chunked_output += chunk
    end
    assert result.success
    assert_equal 'hello world', result.output
    # newline is removed from final output by CommandRunner
    assert_equal "hello world\n", chunked_output
  end
  
  test "collecting output chunks - threaded intermediate check" do
    logger = Logger.new('/dev/null')
    runner = CommandRunner.new(logger)
    
    chunked_output = ''
    result = nil
    worker_thread = Thread.new do
      result = runner.run('echo before sleep; sleep 1; echo after sleep') do |chunk|
        chunked_output += chunk
      end
    end
    
    worker_thread.run
    sleep(0.5)
    assert_nil result
    assert_equal "before sleep\n", chunked_output
    
    worker_thread.join
    
    assert result
    assert result.success
    assert_equal "before sleep\nafter sleep", result.output
    # newline is removed from final output by CommandRunner
    assert_equal "before sleep\nafter sleep\n", chunked_output
  end
end
