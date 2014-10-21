module Runnable

  def self.included(base)
    base.class_eval do
      attr_reader :repo, :directory, :logger, :runner
    end
  end

  def initialize(repo, directory, logger)
    @repo      = repo
    @directory = directory
    @logger    = logger
    @runner    = Integrity::CommandRunner.new(logger)
  end

  def run_in_dir(command, &block)
    _run_in_dir(:run, command, &block)
  end

  def run_in_dir!(command, &block)
    _run_in_dir(:run!, command, &block)
  end

  def in_dir(&block)
    runner.cd(@directory, &block)
  end

  private

  def _run_in_dir(method, command, &block)
    raise ArgumentError, "[#{method}] invalid run method" unless run?(method)
    command = "#{command_prefix}#{command}"
    if block_given?
      in_dir do |r|
        r.send(method, command) do |chunk|
          block.call chunk
        end
      end
    else
      in_dir do |r|
        r.send(method, command)
      end
    end
  end

  def run?(method)
    [:run, :run!].include?(method)
  end

  def command_prefix
    nil
  end
end
