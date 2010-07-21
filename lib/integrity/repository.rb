module Integrity
  # TODO rename to checkout
  class Repository
    def initialize(id, uri, branch, commit)
      @id     = id
      @uri    = uri
      @branch = branch
      @commit = commit == "HEAD" ? head : commit
    end

    def checkout
      run "git clone #{@uri} #{directory}", false unless cloned?
      run "git fetch origin"
      run "git checkout origin/#{@branch}"
      run "git reset --hard #{@commit}"
    end

    def metadata
      format = "---%nid: %H%nauthor: %an " \
        "<%ae>%nmessage: >-%n  %s%ntimestamp: %ci%n"

      dump = YAML.load(`cd #{directory} && git show -s \
        --pretty=format:"#{format}" #{@commit}`)

      dump.update("timestamp" => Time.parse(dump["timestamp"]))
    end

    def head
      `git ls-remote --heads #{@uri} #{@branch} | cut -f1`.chomp
    end

    def directory
      @directory ||= Integrity.config.directory.join(@id.to_s)
    end

    private
      def cloned?
        directory.join(".git").directory?
      end

      def run(cmd, cd=true)
        output = ""
        cmd    = "(#{cd ? "cd #{directory} && " : ""}#{cmd} 2>&1)"
        # TODO
        Integrity.config.logger.debug(cmd)

        IO.popen(cmd, "r") { |io| output = io.read }

        unless $?.success?
          Integrity.config.logger.error(output.inspect)
          fail "Failed run '#{cmd}'"
        end
      end
  end
end
