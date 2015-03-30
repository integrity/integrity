require 'digest/sha1'

module Pancakes

  def self.repo_name(codebase)
    if codebase.to_sym == :jarvis
      'consultingmd/consultingmd'
    else
      "consultingmd/#{codebase}"
    end
  end

  def self.codebase_name(repo)
    if repo.downcase == 'consultingmd'
      :jarvis
    else
      repo.split('/').last
    end
  end

  class StackMaker

    # @param serialno [Integer] it's just a number
    # @param locks [Array] hash like [:jarvis]
    # @param branch_names [Hash] hash like { jarvis: 'master', ... }
    def self.new_with_branch_names(serialno: nil, locks: [], **branch_names)
      commits = commits_from_branch_names(branch_names)
      set_locks(commits, locks)

      Stack.new(
        branch_id: branch_names_sha(branch_names),
        serialno:  serialno || 1,
        commits:   commits
      )
    end

    # @param stack [Stack] the stack to restart
    def self.new_for_restart(stack)
      old_commits = stack.commits.to_a
      branch_names = old_commits.map{|codebase,commit| [codebase, commit.branch_name] }
      locks = old_commits.select{|codebase,commit| commit.locked? == true }.map(&:first)
      new_commits = commits_from_branch_names(branch_names)
      set_locks(new_commits, locks)
      new_sn = stack.serialno + 1

      Stack.new(
        branch_id: branch_names_sha(branch_names),
        serialno:  new_sn,
        commits:   new_commits,
      )
    end

    # @param locks [Array] hash like [:jarvis]
    def self.new_with_integrity_branch(branch, locks=[])
      branch_prj_name = branch.project.name
      jarvis_commit = commit_with_branch_name_or_master(project_name: 'jarvis', branch_name: branch.name, only_head: branch_prj_name == 'jarvis')
      frick_commit  = commit_with_branch_name_or_master(project_name: 'frick', branch_name: branch.name, only_head: branch_prj_name == 'frick')
      tim_commit    = commit_with_branch_name_or_master(project_name: 'tim', branch_name: branch.name, only_head: branch_prj_name == 'tim')

      if !jarvis_commit || !frick_commit || !tim_commit
        Pancakes.logp :warn, "commit was nil jarvis_commit=#{jarvis_commit.inspect} frick_commit=#{frick_commit.inspect} tim_commit=#{tim_commit.inspect}"
        return nil
      end

      commits = {
        jarvis: Pancakes::Commit.new_from_integrity_commit(jarvis_commit),
        frick:  Pancakes::Commit.new_from_integrity_commit(frick_commit),
        tim:    Pancakes::Commit.new_from_integrity_commit(tim_commit),
      }

      set_locks(commits, locks)

      Stack.new(
        branch_id: branch.id,
        serialno:  branch.pancakes_serialno,
        commits:   commits,
      )
    end

    def self.branch_names_sha(branch_names)
      Digest::SHA1.hexdigest(branch_names.to_a.map{|b| b.join(':') }.sort.join('+'))[0..7]
    end

    # @param branch_names [Hash] hash like { jarvis: 'master', ... }
    # @api private
    def self.commits_from_branch_names(branch_names)
      branch_names.map do |codebase,branch_name|
        {
          codebase =>
          Pancakes::Commit.new_from_github_api_commit(
            github_tip_commit_hash(
              Pancakes.repo_name(codebase),
              branch_name),
            branch_name)
        }
      end
      .reduce(&:merge)
    end

    # @api private
    def self.set_locks(commits, locks)
      locks.each do |lock|
        commits[lock].lock
      end
    end

    # @api private
    def self.heads_string(branch_name)
      "heads/#{branch_name}"
    end

    # @api private
    def self.github_tip_commit_hash(repo, branch_name)
      ref = Octokit.ref(repo, heads_string(branch_name))
      commit = Octokit.commit(repo, ref[:object][:sha])
    end

    # @api private
    def self.commit_with_branch_name_or_master(project_name:, branch_name:, only_head: false)
      branch = branch_of_project(project_name, branch_name)

      if !branch
        if only_head
          Pancakes.logp :warn, "can't find #{project_name} #{branch_name} and only_head=true"
          return nil
        end

        Pancakes.logp :info, "using #{project_name} master instead of #{branch_name}"
        branch_name = 'master'
        branch = branch_of_project(project_name, branch_name)
      end

      bu = branch.last_build

      if !bu
        Pancakes.logp :warn, "#{project_name} #{branch_name} has nil last_build"
        return nil
      elsif bu.successful?
        ci = bu.commit
        Pancakes.logp :warn, "using last_build commit(#{ci.identifier}) for #{project_name} #{branch_name}"
        return ci
      else
        Pancakes.logp :warn, "#{project_name} #{branch_name} tip commit(#{bu.commit.identifier}) isn't green. using latest green commit instead."
      end

      bu = branch.builds.first(successful: true, order: :completed_at.desc)

      if bu
        ci = bu.commit
        Pancakes.logp :warn, "using last green commit(#{ci.identifier}) for #{project_name} #{branch_name}"
        return ci
      else
        Pancakes.logp :warn, "#{project_name} #{branch_name} has no green commits I can use"
        return nil
      end
    end

    # @api private
    def self.branch_of_project(project_name, branch_name)
      Integrity::Project.first(name: project_name).branches.first(name: branch_name)
    end
  end
end
