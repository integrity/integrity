module Integrity
  class Checkout
    def initialize(repo, commit, directory, logger)
      @repo      = repo
      @commit    = commit == "HEAD" ? head : commit
      @directory = directory
      @logger    = logger
    end

    def run
      runner.run! "git clone #{@repo.uri} #{@directory}"

      in_dir do |c|
        c.run! "git fetch origin"
        c.run! "git checkout origin/#{@repo.branch}"
        c.run! "git reset --hard #{@commit}"
      end
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
      in_dir { |r| r.run(command) }
    end

    def in_dir(&block)
      runner.cd(@directory, &block)
    end

    def runner
      @runner ||= CommandRunner.new(@logger)
    end
  end
end
