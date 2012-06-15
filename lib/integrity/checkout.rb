require 'md5'
require 'pathname'

module Integrity
  class Checkout
    def initialize(repo, commit, directory, logger)
      @repo      = repo
      @commit    = commit
      @directory = directory
      @logger    = logger
      @cache_directory = Pathname.new(@directory).join('../../cache', MD5.hexdigest(@repo.uri)).cleanpath
      @cache_directory.mkpath
    end

    def run
      update_cache
      runner.run! "git clone #{@cache_directory} #{@directory}"

      in_dir do |c|
        # should be useless since we're using a cache dir
        # c.run! "git fetch origin"
        c.run! "git checkout origin/#{@repo.branch}"
        c.run! "git reset --hard #{sha1}"
        # run init separately for compatibility with old versions of git
        c.run! "git submodule init"
        c.run! "git submodule update"
      end
    end

    def update_cache
      with_lock("#{@cache_directory}.lock") do
        unless @cache_directory.exist?
          clone_directory = "#{@cache_directory}.cloning"
          runner.run! "rm -rf #{clone_directory}"
          runner.run! "git clone --mirror #{@repo.uri} #{clone_directory}"
          runner.run! "mv #{clone_directory} #{@cache_directory}"
        end

        in_dir(@cache_directory) do |c|
          c.run! "git fetch origin"
        end
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
      message = dump['message']

      result = run_in_dir!("git show -s --pretty=format:\"%b\" #{sha1}")
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
      runner.run!("git ls-remote --heads #{@repo.uri} #{@repo.branch}").
        output.split.first
    end

    def run_in_dir(command)
      in_dir { |r| r.run("INTEGRITY_BRANCH=\"#{@repo.branch}\" " + command) }
    end

    def run_in_dir!(command)
      in_dir { |r| r.run!(command) }
    end

    def in_dir(dir=nil, &block)
      dir ||= @directory
      runner.cd(dir, &block)
    end

    def runner
      @runner ||= CommandRunner.new(@logger)
    end


    private


    def with_lock(path)
      File.open(path,'w') do |file|
        begin
          file.flock(File::LOCK_EX)
          yield
        ensure
          file.flock(File::LOCK_UN)
        end
      end
    end

  end
end
