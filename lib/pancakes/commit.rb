module Pancakes
  class Commit
    attr_reader :sha, :author_name, :message, :date, :branch_name, :repo

    def initialize(sha:, author_name:, message:, date:, branch_name:, repo:, locked: false)
      @sha, @author_name, @message, @date, @branch_name, @repo, @locked  = sha, author_name, message, date.to_s, branch_name, repo, locked
    end

    def locked?
      @locked
    end

    def lock
      @locked = true
    end

    def unlock
      @locked = false
    end

    def flip_lock
      @locked = !@locked
    end

    def date_as_date
      Time.parse(@date)
    end

    def as_json(opts={})
      {
        sha: @sha,
        author_name: @author_name,
        message: @message,
        date: @date.to_s,
        branch_name: @branch_name,
        repo: @repo,
        locked: @locked,
      }.stringify_keys
    end

    def self.from_json(json)
      new(json.symbolize_keys)
    end

    def self.new_from_github_api_commit(commit_hash, branch_name=nil, locked=false)
      repo = commit_hash[:url].sub('https://api.github.com/repos/', '').sub(/\/commits.+/, '')
      new(
        sha: commit_hash[:sha],
        author_name: commit_hash[:commit][:author][:name],
        message: commit_hash[:commit][:message].empty? ? '' : commit_hash[:commit][:message].lines.first.chomp,
        date: commit_hash[:commit][:author][:date],
        branch_name: branch_name,
        repo: repo,
        locked: locked,
      )
    end

    def self.new_from_integrity_commit(commit, locked=false)
      repo = commit.branch.project.repo
      new(
        sha: commit.identifier,
        author_name: commit.author.name,
        message: commit.message,
        date: commit.committed_at,
        branch_name: commit.branch,
        repo: "#{repo.owner}/#{repo.name}",
        locked: locked,
      )
    end
  end
end
