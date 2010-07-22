module Integrity
  class Payload
    def initialize(payload)
      @payload = JSON.parse(payload)
    end

    def head
      commits.detect { |c| c[:identifier] == @payload["after"] }
    end

    def commits
      @commits ||= @payload["commits"].map { |commit|
        { :identifier   => commit["id"],
          :author       => normalize_author(commit["author"]),
          :message      => commit["message"],
          :committed_at => commit["timestamp"] }
      }
    end

    def uri
      if uri = @payload["uri"]
        return uri
      end

      repository = @payload["repository"]

      if repository["private"]
        "git@github.com:#{URI(repository["url"]).path[1..-1]}"
      else
        URI(repository["url"]).tap { |u| u.scheme = "git" }.to_s
      end
    end

    def branch
      @payload["ref"].split("refs/heads/").last
    end

    def normalize_author(author)
      "#{author["name"]} <#{author["email"]}>"
    end
  end
end
