module Integrity
  class Payload
    def self.build(payload, all)
      new(payload).build(all)
    end

    def initialize(payload)
      payload = JSON.parse(payload) if payload.is_a?(String)
      @payload = payload.symbolize_keys
      Integrity.logger.info "payload:\n#{@payload.inspect}"
    end

    def build(all)
      PayloadBuilder.build(self, all)
    end

    def repo
      Integrity::Repository.new(uri, branch)
    end

    def head
      commits.detect {|c| c[:identifier] == @payload[:after] }
    end

    def commits
      @commits ||= @payload[:commits].map do |commit|
        {
          identifier:   commit[:id],
          author:       normalize_author(commit[:author]),
          message:      commit[:message],
          committed_at: commit[:timestamp]
        }
      end
    end

    def deleted?
      @payload[:deleted]
    end

    def private?
      @payload[:private]
    end

    def uri
      return uri if uri = @payload[:uri]

      repository = @payload[:repository].symbolize_keys
      url = repository[:url]
      uri = URI(url)

      if private?
        "git@github.com:#{uri.path[1..-1]}"
      else
        uri.scheme = 'git'
        uri.to_s
      end
    end

    def branch
      @payload[:ref].split('refs/heads/').last
    end

    def normalize_author(author)
      author = author.symbolize_keys
      "#{author[:name]} <#{author[:email]}>"
    end
  end
end
