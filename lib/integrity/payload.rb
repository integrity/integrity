module Integrity
  class Payload

    def self.build(payload, all)
      new(payload).build(all)
    end

    def initialize(payload)
      payload  = JSON.parse(payload) if payload.is_a?(String)
      @payload = Hashie::Mash.new(payload)
    end

    def build(all)
      PayloadBuilder.build(self, all)
    end

    def repo
      Integrity::Repository.new(uri, branch)
    end

    def head
      commits.detect {|c| c.identifier == @payload.after }
    end

    def commits
      @commits ||= @payload[:commits].map do |commit|
        Hashie::Mash.new(
          identifier:   commit.id,
          author:       normalize_author(commit.author),
          message:      commit.message,
          committed_at: commit.timestamp,
          branch:       branch,

        )
      end
    end

    def deleted?
      @payload[:deleted]
    end

    def private?
      @payload[:repository][:private] rescue true
    end

    def uri
      return uri if uri = @payload[:uri]

      repository = @payload.repository

      if private?
        "git://github.com/#{repository.full_name}"
      else
        "https://github.com#{repository.full_name}.git"
      end
    end

    def branch
      @payload[:ref].split('refs/heads/').last
    end

    def normalize_author(author)
      return 'unknown' unless author
      author = Hashie::Mash.new(author) unless author.is_a?(Hashie::Mash)
      "#{author.name} <#{author.email}>"
    end
  end
end
