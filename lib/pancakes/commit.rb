module Pancakes
  class Commit
    #include Mongoid::Document

    #field :sha,     type: String
    #field :author,  type: String
    #field :message, type: String
    #field :date,    type: String
    #field :branch,  type: String
    #field :repo,    type: String
    #field :locked,  type: Boolean, default: false
    #field :at_head, type: Boolean, default: false

    #embedded_in :stack, class_name: 'Pancakes::Stack', inverse_of: :commits

    #validates :sha, presence: true
    #validates :sha, length: { minimum: 40, maximum: 40 }
    #validates :author, presence: true
    #validates :message, presence: true
    #validates :date, presence: true
    #validates :repo, presence: true
    #validates :locked, presence: true
    #validates :at_head, presence: true

    # Creating from a sha is always locked.
    def self.new_from_sha(repo:, sha:, branch: nil, locked: true)
      ci = Octokit.commit(repo, sha)
      sha = ci[:sha]
      me = new(
        sha:     sha,
        author:  ci[:commit][:author][:name],
        message: ci[:commit][:message].empty? ? nil : ci[:commit][:message].lines.first.chomp,
        date:    ci[:commit][:author][:date],
        branch:  branch,
        repo:    repo,
        locked:  locked,
      )
      me.refresh_at_head
      me
    end

    # Creating from a branch may be locked or unlocked.
    def self.new_from_branch(repo:, branch:, locked: false)
      new_from_sha(
        repo: repo,
        branch: branch,
        sha: head_sha(repo, branch),
        locked: locked,
      )
    end

    def self.new_from_git_string(repo, git_str)
      parsed = parse_git_string(git_str)
      br, sha, locked = parsed[:branch], parsed[:sha], parsed[:locked]

      if br && !sha
        Pancakes::Commit.new_from_branch(repo: repo, branch: br, locked: locked)
      elsif br && sha
        Pancakes::Commit.new_from_sha(repo: repo, branch: br, sha: sha, locked: locked)
      elsif !br && sha
        Pancakes::Commit.new_from_sha(repo: repo, sha: sha, locked: locked)
      else
        raise "new_from_git_string() requires branch and/or sha"
      end
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

    def toggle_lock
      self.locked = !self.locked
    end

    def refresh_at_head
      if branch
        self.at_head = sha == self.class.head_sha(repo, branch)
      else
        self.at_head = false
      end
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

    def date_as_date
      Time.parse(self.date)
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
    # for any branch name, includeing those with a sha before it, if it starts with a L+, it will be locked.
    # if it starts with L-, it will be unlocked, which is the default.
    # - 'L+branch/with:name'
    # - 'L-branch/with:name'
    #
    # @return [Hash] { sha: '...',  }
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

      { sha: sha, branch: branch, locked: locked }
    end

    #attr_reader :sha, :author_name, :message, :date, :branch_name, :repo

    #def initialize(sha:, author_name:, message:, date:, branch_name:, repo:, locked: false)
      #@sha, @author_name, @message, @date, @branch_name, @repo, @locked  = sha, author_name, message, date.to_s, branch_name, repo, locked
    #end

    #def locked?
      #@locked
    #end

    #def lock
      #@locked = true
    #end

    #def unlock
      #@locked = false
    #end

    #def flip_lock
      #@locked = !@locked
    #end

    #def as_json(opts={})
      #{
        #sha: @sha,
        #author_name: @author_name,
        #message: @message,
        #date: @date.to_s,
        #branch_name: @branch_name,
        #repo: @repo,
        #locked: @locked,
      #}.stringify_keys
    #end

    #def self.from_json(json)
      #new(json.symbolize_keys)
    #end

    #def self.new_from_github_api_commit(commit_hash, branch_name=nil, locked=false)
      #repo = commit_hash[:url].sub('https://api.github.com/repos/', '').sub(/\/commits.+/, '')
      #new(
        #sha: commit_hash[:sha],
        #author_name: commit_hash[:commit][:author][:name],
        #message: commit_hash[:commit][:message].empty? ? '' : commit_hash[:commit][:message].lines.first.chomp,
        #date: commit_hash[:commit][:author][:date],
        #branch_name: branch_name,
        #repo: repo,
        #locked: locked,
      #)
    #end

    #def self.new_from_integrity_commit(commit, locked=false)
      #repo = commit.branch.project.repo
      #new(
        #sha: commit.identifier,
        #author_name: commit.author.name,
        #message: commit.message,
        #date: commit.committed_at,
        #branch_name: commit.branch,
        #repo: "#{repo.owner}/#{repo.name}",
        #locked: locked,
      #)
    #end
  end
end
