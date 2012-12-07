module Integrity
  class Checkout
    def initialize(repo, commit, directory, logger)
      @repo      = repo
      @commit    = commit
      @directory = directory
      @logger    = logger
      @setup_script = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'git_ssh'))
    end

    def run
      if ENV['DEPLOY_PRIVATE_KEY']
        puts "running script"
        puts runner.run!("#{@setup_script} run #{@repo.uri} #{@directory} #{@repo.branch} #{sha1}").output
      else
        puts runner.run!("git clone #{@repo.uri} #{@directory} #{@repo.branch} #{sha1}").output

        in_dir do |c|
          c.run! "git fetch origin"
          c.run! "git checkout origin/#{@repo.branch}"
          c.run! "git reset --hard #{sha1}"
          # run init separately for compatibility with old versions of git
          c.run! "git submodule init"
          c.run! "git submodule update"
        end
      end
    end

    def metadata
      format = "---%n" \
        "identifier: %H%n" \
        "author: %an <%ae>%n" \
        "message: >-%n  %s%n" \
        "committed_at: %ci%n"
      if ENV['DEPLOY_PRIVATE_KEY']
        result = runner.run!("#{@setup_script} show #{@directory} \"#{format}\" #{sha1}")
      else
        result = run_in_dir!("git show -s --pretty=format:\"#{format}\" #{sha1}")
      end
      dump   = YAML.load(result.output)
      message = dump['message']

      if ENV['DEPLOY_PRIVATE_KEY']
        result = runner.run!("#{@setup_script} show #{@directory} \"%b\" #{sha1}")
      else
        result = run_in_dir!("git show -s --pretty=format:\"%b\" #{sha1}")
      end
      dump['full_message'] = message + "\n\n" + result.output
      
      # message (subject in git parlance) may be over 255 characters
      # which is our limit for the column; if so, truncate it intelligently
      if message.length > 255
        # leave 3 characters for ellipsis
        message = message[0...253]
        # if the truncated message ends in the middle of a word,
        # delete the word; if commit messages are sane words should
        # not be too long for us to worry about being left with nothing
        if message =~ /\w\w$/
          message.sub!(/\w+$/, '')
        else
          message = message[0...252]
        end
        message += '...'
        dump['message'] = message
      end

      unless dump["committed_at"].kind_of? Time
        dump["committed_at"] = Time.parse(dump["committed_at"])
      end

      dump
    end

    def sha1
      @sha1 ||= @commit == "HEAD" ? head : @commit
    end

    def head
      if ENV['DEPLOY_PRIVATE_KEY']
        out = runner.run!("#{@setup_script} head #{@repo.uri} #{@repo.branch}")
          .output.split
        out[out.size - 2]
      else
        runner.run!("git ls-remote --heads #{@repo.uri} #{@repo.branch}").
          output.split.first
      end
    end

    def run_in_dir(command)
      in_dir { |r| r.run("INTEGRITY_BRANCH=\"#{@repo.branch}\" " + command) }
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
