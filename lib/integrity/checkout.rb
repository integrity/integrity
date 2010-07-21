module Integrity
  class Checkout
    def initialize(uri, branch, commit, directory)
      @uri       = uri
      @branch    = branch
      @commit    = commit == "HEAD" ? head : commit
      @directory = directory
    end

    def run
      unless cloned?
        run_command "git clone #{@uri} #{@directory}", false
      end

      run_command "git fetch origin"
      run_command "git checkout origin/#{@branch}"
      run_command "git reset --hard #{@commit}"
    end

    def metadata
      format = "---%nid: %H%nauthor: %an " \
        "<%ae>%nmessage: >-%n  %s%ntimestamp: %ci%n"

      dump = YAML.load(`cd #{@directory} && git show -s \
        --pretty=format:"#{format}" #{@commit}`)

      dump.update("timestamp" => Time.parse(dump["timestamp"]))
    end

    def head
      `git ls-remote --heads #{@uri} #{@branch} | cut -f1`.chomp
    end

    private
      def cloned?
        @directory.join(".git").directory?
      end

      def run_command(cmd, cd=true)
        output = ""
        cmd    = "(#{cd ? "cd #{@directory} && " : ""}#{cmd} 2>&1)"
        # TODO
        Integrity.logger.debug(cmd)

        IO.popen(cmd, "r") { |io| output = io.read }

        unless $?.success?
          Integrity.logger.error(output.inspect)
          fail "Failed run '#{cmd}'"
        end
      end
  end
end
