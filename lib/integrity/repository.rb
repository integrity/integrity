module Integrity
  class Repository
    def initialize(uri, branch)
      @uri    = Addressable::URI.parse(uri)
      @branch = branch
    end

    def checkout(commit)
      run "git clone #{@uri} #{dir_for(commit)}" unless cloned?(commit)
      run "git fetch origin", dir_for(commit)
      run "git checkout origin/#{@branch}", dir_for(commit)
      run "git reset --hard #{commit}", dir_for(commit)
    end

    def metadata(commit)
      format = "---%nid: %H%nauthor: %an " \
        "<%ae>%nmessage: >-%n  %s%ntimestamp: %ci%n"

      dump = YAML.load(`cd #{dir_for(commit)} && git show -s \
        --pretty=format:"#{format}" #{commit}`)

      dump.update("timestamp" => Time.parse(dump["timestamp"]))
    end

    def head
      `git ls-remote --heads #{@uri} #{@branch} | cut -f1`.chomp
    end

    def dir_for(commit)
      Integrity.config.directory.join(path, resolve(commit))
    end

    private

      def cloned?(commit)
        dir_for(commit).join(".git").directory?
      end

      def run(cmd, dir=nil)
        cmd = "(#{dir ? "cd #{dir} && " : ""}#{cmd} > /dev/null 2>&1)"
        Integrity.config.logger.debug(cmd)
        system(cmd) || fail("Couldn't run `#{cmd}`")
      end

      def path
        @path ||= "#{@uri}-#{@branch}".
          gsub(/[^\w_ \-]+/i, '-').# Remove unwanted chars.
          gsub(/[ \-]+/i, '-').    # No more than one of the separator in a row.
          gsub(/^\-|\-$/i, '')     # Remove leading/trailing separator.
      end

      def resolve(commit)
        commit == "HEAD" ? head : commit
      end
  end
end
