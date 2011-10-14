module Integrity
  class Checkout
    def initialize(repo, commit, directory, logger)
      @repo      = repo
      @commit    = commit
      @directory = directory
      @logger    = logger
    end

    def run
      runner.run! "git clone #{@repo.uri} #{@directory}"

      in_dir do |c|
        c.run! "git fetch origin"
        c.run! "git checkout origin/#{@repo.branch}"
        c.run! "git reset --hard #{sha1}"
        # run init separately for compatibility with old versions of git
        c.run! "git submodule init"
        c.run! "git submodule update"
      end
    end

    def metadata
      format = "---%n" \
        "identifier: %H%n" \
        "author: %an <%ae>%n" \
        "message: >-%n  %s%n" \
        "committed_at: %ci%n"
      result = run_in_dir!("git show -s --pretty=format:\"#{format}\" #{sha1}")
      dump   = YAML.load(result.output)

      unless dump["committed_at"].kind_of? Time
        dump.update("committed_at" => Time.parse(dump["committed_at"]))
      end
    end

    def sha1
      @sha1 ||= @commit == "HEAD" ? head : @commit
    end

    def head
      runner.run!("git ls-remote --heads #{@repo.uri} #{@repo.branch}").
        output.split.first
    end

    def run_in_dir(command)
      in_dir { |r| r.run(command) }
    end

    def run_in_dir!(command)
      in_dir { |r| r.run!(command) }
    end

    def in_dir(&block)
      runner.cd(@directory, &block)
    end

    def runner
      @runner ||= CommandRunner.new(@logger)
    end
  end
end
