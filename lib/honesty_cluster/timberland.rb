module HonestyCluster
  module Timberland
    NAME = 'timberland'

    class Cmd
      attr_reader :boot_type, :sha, :repo, :debug, :branch, :setup_db, :service_type, :parallel_spec_jobs, :sleep

      def initialize(boot_type:, service_type:, sha:, repo:, branch:nil, debug:nil, setup_db:nil, parallel_spec_jobs:nil, sleep:nil)
        @timberland_branch = Pancakes::Fleet::Templating.config.timberland_branch
        @boot_type    = boot_type
        @service_type = service_type
        @parallel_spec_jobs = parallel_spec_jobs
        @sleep        = sleep
        @sha          = sha
        @repo         = repo
        @branch       = branch
        @debug       ||= Pancakes.timberland_debug?
        @setup_db    ||= true
      end

      def to_s
        run_cmd
      end

      def to_docker_api_cmd
        bash_minus_c(clone_and_run_cmd)
      end

      def clone_and_run_cmd
        bash_and(
          clone_cmd,
          "cd #{Timberland::NAME}",
          run_cmd,
        )
      end

      def clone_cmd
        join_args(
          'git', 'clone',
          '--depth', 1,
          '--branch', @timberland_branch,
          "https://#{Pancakes.gh_read_token}@github.com/consultingmd/#{Timberland::NAME}",
          Timberland::NAME,
        )
      end

      def run_cmd
        join_args(
          "./#{Timberland::NAME}",
          '--boot-type', boot_type,
          '--service-type', service_type,
          '--sha', sha,
          '--repo', repo,
          !setup_db ? '--no-setup-db' : nil,
          debug ? '--debug' : nil,
          parallel_spec_jobs ? "--parallel-spec-jobs #{parallel_spec_jobs}" : nil,
          sleep ? "--sleep #{sleep}" : nil,
          (branch && !branch.empty?) ? ['--branch', branch] : nil
        )
      end

      private def bash_minus_c(cmd)
        ['/bin/bash', '-c', cmd]
      end

      private def bash_and(*cmds)
        cmds.join(' && ')
      end

      private def join_args(*args)
        args.flatten.compact.map(&:to_s).map(&:strip).join(' ').strip
      end
    end
  end
end
