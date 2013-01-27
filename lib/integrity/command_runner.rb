module Integrity
  class CommandRunner
    class Error < StandardError; end

    Result = Struct.new(:success, :output)

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
      with_clean_env do
        IO.popen(cmd, "r") { |io| output = io.read }
      end
      
      # output may be invalid UTF-8, as it is produced by the build command.
      output = Integrity.clean_utf8(output)

      Result.new($?.success?, output.chomp)
    end

    def run!(command)
      result = run(command)

      unless result.success
        @logger.error(result.output.inspect)
        raise Error, "Failed to run '#{command}'"
      end

      result
    end

    def normalize(cmd)
      # bash requires lists to end with a semicolon (or a newline).
      # see http://wiki.bash-hackers.org/syntax/ccmd/grouping_plain
      # zsh has no such restriction.
      unless cmd[-1] == ?;
        cmd += ';'
      end
      if @dir
        "cd #{@dir} && { #{cmd} } 2>&1"
      else
        "{ #{cmd} } 2>&1"
      end
    end

    SIDE_EFFECT_VARS = %w(BUNDLE_GEMFILE RUBYOPT BUNDLE_BIN_PATH RBENV_DIR)

    # The idea is shamelessly stolen from Bundler.
    #
    # In general, Bundler sets several environment variables to operate,
    # the issue is that parent shell propogate its evironment to
    # subshells, which breaks builds, because your build is
    # trying to use Integrity's gemfile.
    #
    # So here we unset some of that environment variables to let
    # build's bundler create its own environment.
    #
    # When build is done we rollback to previous environment.
    #
    # Bundler team will probably create a way to avoid this, but
    # most likely it won't be sooner than Bundler 1.1
    #
    # FIXME:
    # If you're using RVM gemsets and runnig Integrity in RVM shell,
    # make sure that Bundler gem is installed into current gemset,
    # not global. Otherwise, Bundler will drop path to your global
    # gemset.
    def with_clean_env
      bundled_env = ENV.to_hash
      SIDE_EFFECT_VARS.each{ |var| ENV.delete(var) }
      yield
    ensure
      ENV.replace(bundled_env.to_hash)
    end
  end
end
