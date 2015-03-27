module Pancakes
  class Commit
    attr_reader :sha, :author_name, :message, :date, :branch_name

    def initialize(sha:, author_name:, message:, date:, branch_name:)
      @sha, @author_name, @message, @date, @branch_name = sha, author_name, message, date.to_s, branch_name
    end

    def as_json(opts={})
      {
        sha: @sha,
        author_name: @author_name,
        message: @message,
        date: @date.to_s,
        branch_name: @branch_name,
      }.stringify_keys
    end

    def self.from_json(json)
      new(json.symbolize_keys)
    end

    def self.new_from_github_api_commit(commit_hash, branch_name=nil)
      new(
        sha: commit_hash[:sha],
        author_name: commit_hash[:commit][:author][:name],
        message: commit_hash[:commit][:message].empty? ? '' : commit_hash[:commit][:message].lines.first.chomp,
        date: commit_hash[:commit][:author][:date],
        branch_name: branch_name,
      )
    end

    def self.new_from_integrity_commit(commit)
      new(
        sha: commit.identifier,
        author_name: commit.author.name,
        message: commit.message,
        date: commit.committed_at,
        branch_name: commit.branch,
      )
    end
  end
end
