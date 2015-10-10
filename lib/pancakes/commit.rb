module Pancakes
  class Commit < Sequel::Model
    set_dataset :pancakes_commits
    plugin :timestamps
    plugin :validation_helpers

    many_to_one :stack, key: :stack_id, class: :"Pancakes::Stack"

    def validate
      super
      validates_exact_length 40, :sha
      validates_presence %i[sha author message date repo locked at_head]
    end

    def self.new_from_git_string(repo, git_str)
      new(get_model_fields_from_git_string(repo, git_str))
    end

    def self.create_from_git_string(repo, git_str)
      new_from_git_string(repo, git_str).save
    end

    # @api private
    def self.get_model_fields_from_git_string(repo, git_str)
      sha, branch, locked = parse_git_string(git_str)
      get_model_fields_for_sha(
        repo:   repo,
        locked: locked,
        branch: branch,
        sha:    get_sha(repo, branch, sha),
      )
    end

    # @api private
    def self.get_model_fields_for_sha(repo:, branch:, sha:, locked:)
      ci = Octokit.commit(repo, sha)
      {
        repo:    repo,
        branch:  branch,
        sha:     sha,
        locked:  locked,
        at_head: is_at_head?(repo, branch, sha),
        message: ci[:commit][:message],
        author:  ci[:commit][:author][:name],
        date:    ci[:commit][:author][:date],
      }
    end

    # @api private
    def self.get_sha(repo, branch, sha)
      return sha if sha
      raise "new_from_git_string() requires branch and/or sha" unless repo && branch
      head_sha(repo, branch)
    end

    def refresh_branch_head(force: false)
      return if !force && locked?
      update_all(
        self.class.get_model_fields_for_sha(
          repo:   repo,
          locked: locked,
          branch: branch,
          sha:    self.class.get_sha(repo, branch, nil),
        )
      )
      self
    end

    def codebase
      Pancakes.codebase_name(repo)
    end

    def short_sha
      self.sha[0..6]
    end

    def locked?
      locked
    end

    def toggle_lock!
      self.locked = !self.locked
      save
    end

    def refresh_at_head
      self.at_head = self.class.is_at_head?(repo, branch, sha)
      save
    end

    def self.is_at_head?(repo, branch, sha)
      return false unless repo && branch && sha
      sha == head_sha(repo, branch)
    end

    def git_string
      if branch
        locked_str = locked ? '+' : '-'
        if locked
          format('%s:L%s%s', sha, locked_str, branch)
        else
          #format('L%s%s', locked_str, branch)
          branch
        end
      else
        sha
      end
    end

    def build
      if icommit = Integrity::Commit.get(identifier: sha)
        icommit.build
      else
        nil
      end
    end


    ######
    #     #  #####      #    #    #    ##     #####  ######
    #     #  #    #     #    #    #   #  #      #    #
    ######   #    #     #    #    #  #    #     #    #####
    #        #####      #    #    #  ######     #    #
    #        #   #      #     #  #   #    #     #    #
    #        #    #     #      ##    #    #     #    ######
    private

    # @api private
    def self.head_sha(repo, branch)
      ref = Octokit.ref(repo, Pancakes.heads_str(branch))
      ref[:object][:sha]
    end

    # commit_string formats
    # - 'SHA40'
    # - 'SHA40:branch/with:name'
    #   - only the first colon is used in parsing
    # - 'branch/with:name'
    #
    # for any branch name, including those with a sha before it, if it starts with a L+, it will be locked.
    # if it starts with L-, it will be unlocked, which is the default.
    # - 'L+branch/with:name'
    # - 'L-branch/with:name'
    #
    # @return [Array] returns an array of [sha, branch, locked]
    #
    # @api private
    def self.parse_git_string(str)
      return nil unless str
      locked = false
      branch = nil
      sha = nil

      if m = str.match(/\A(?<sha>[0-9a-f]{40})(?::(?<branch>.+))?\z/i)
        sha = m[:sha]
        branch = m[:branch]
      else
        branch = str
      end

      if branch && branch.start_with?('L-')
        branch = branch.sub(/\AL-/, '')
        return nil if branch.empty?
        locked = false
      elsif branch && branch.start_with?('L+')
        branch = branch.sub(/\AL\+/, '')
        return nil if branch.empty?
        locked = true
      elsif sha
        locked = true
      end

      return sha, branch, locked
    end
  end
end
