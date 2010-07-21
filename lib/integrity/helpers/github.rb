module Integrity
  module Helpers
    def github_payload
      payload = JSON.parse(params[:payload])

      repository = payload.delete("repository")
      branch     = payload.delete("ref").split("refs/heads/").last

      unless uri = payload.delete("uri")
        uri =
          if repository["private"]
            "git@github.com:#{URI(repository["url"]).path[1..-1]}"
          else
            URI(repository["url"]).tap { |u| u.scheme = "git" }.to_s
          end
      end

      commits =
        if Integrity.config.build_all?
          payload.delete("commits")
        else
          [payload["commits"].detect { |c| c["id"] == payload["after"] }]
        end

      payload.update(
        "uri"     => uri,
        "branch"  => branch,
        "commits" => commits
      )
    rescue JSON::JSONError
      nil
    end
  end
end
