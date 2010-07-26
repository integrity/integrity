module Integrity
  class CommandRunner
    class Error < StandardError; end

    def initialize(logger)
      @logger = logger
    end

    def cd(dir)
      @dir = dir
      yield self
    ensure
      @dir = nil
    end

    def run(command)
      cmd = normalize(command)

      @logger.debug(cmd)

      output = ""
      IO.popen(cmd, "r") { |io| output = io.read }

      [$?.success?, output.chomp]
    end

    def run!(command)
      success, output = run(command)

      unless success
        @logger.error(output.inspect)
        raise Error, "Failed to run '#{command}'"
      end

      output
    end

    def normalize(cmd)
      if @dir
        "(cd #{@dir} && #{cmd} 2>&1)"
      else
        "(#{cmd} 2>&1)"
      end
    end
  end
end
