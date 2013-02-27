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
      @logger.debug(command)

      output = ""
      rd, wr = IO.pipe
      with_clean_env do
        if pid = fork
          # parent
          wr.close
          while true
            fds, = IO.select([rd], nil, nil, Integrity.config.build_output_interval)
            unless fds.empty?
              # should have some data to read
              begin
                chunk = rd.read_nonblock(10240)
                if block_given?
                  yield chunk
                end
                output += chunk
              rescue Errno::EAGAIN, Errno::EWOULDBLOCK
                # do select again
              rescue EOFError
                break
              end
            end
            # if fds are empty, timeout expired - run another iteration
          end
          rd.close
          Process.waitpid(pid)
        else
          # child
          rd.close
          STDOUT.reopen(wr)
          wr.close
          STDERR.reopen(STDOUT)
          if @dir
            Dir.chdir(@dir)
          end
          exec(command)
        end
      end
      
      # output may be invalid UTF-8, as it is produced by the build command.
      output = Integrity.clean_utf8(output)

      Result.new($?.success?, output.chomp)
    end

    def run!(command)
      result = run(command)

      unless result.success
        @logger.error(result.output.inspect)
        raise Error, "Failed to run '#{command}': #{result.output}"
      end

      result
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
