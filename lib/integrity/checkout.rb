module Integrity
  class Checkout
    def initialize(repo, commit, directory)
      @repo      = repo
      @commit    = commit == "HEAD" ? head : commit
      @directory = directory
    end

    def checkout
      unless cloned?
        run! "git clone #{@repo.uri} #{@directory}"
      end

      run_in_dir! "git fetch origin"
      run_in_dir! "git checkout origin/#{@repo.branch}"
      run_in_dir! "git reset --hard #{@commit}"
    end

    def metadata
      format = "---%nidentifier: %H%nauthor: %an " \
        "<%ae>%nmessage: >-%n  %s%ncommitted_at: %ci%n"

      dump = YAML.load(`cd #{@directory} && git show -s \
        --pretty=format:"#{format}" #{@commit}`)

      dump.update("committed_at" => Time.parse(dump["committed_at"]))
    end

    def head
      `git ls-remote --heads #{@repo.uri} #{@repo.branch} | cut -f1`.chomp
    end

    def run_in_dir(command)
      run("cd #{@directory} && #{command}")
    end

    def run_in_dir!(command)
      run!("cd #{@directory} && #{command}")
    end

    def run(command)
      cmd    = "(#{command} 2>&1)"
      Integrity.logger.debug(cmd)
      output = ""
      IO.popen(cmd, "r") { |io| output = io.read }

      [$?.success?, output]
    end

    def run!(command)
      success, output = run(command)

      unless success
        Integrity.logger.error(output.inspect)
        fail "Failed to run '#{cmd}'"
      end
    end

    def cloned?
      @directory.join(".git").directory?
    end
  end
end
