module Integrity
  module Helpers
    def github_enabled?
      options.respond_to?(:github_token) && options.github_token
    end

    def github_payload
      payload = JSON.parse(params[:payload])

      repository = payload.delete("repository")
      branch     = payload.delete("ref").split("/").last

      uri =
        if repository["private"]
          "git@github.com:#{URI(repository["url"]).path[1..-1]}"
        else
          URI(repository["url"]).tap { |u| u.scheme = "git" }.to_s
        end

      # TODO
      uri = repository["url"] if options.test?

      commits =
        if options.build_all?
          payload.delete("commits")
        else
          [payload["commits"].detect { |c| c["id"] == payload["after"] }]
        end

      payload.update(
        "scm"         => "git",
        "uri"         => uri,
        "branch"      => branch,
        "commits"     => commits
      )
    rescue JSON::JSONError
      false
    end
  end
end
