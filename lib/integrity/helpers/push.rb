module Integrity
  module Helpers
    def endpoint_token
      %w[push github].include?(params[:endpoint]) &&
        options.respond_to?(params[:endpoint]) &&
        options.send(params[:endpoint])
    end
    alias_method :endpoint_enabled?, :endpoint_token

    def endpoint_payload
      case params[:endpoint]
      when "push"   then push_payload
      when "github" then github_payload
      else
        nil
      end
    rescue JSON::JSONError
      nil
    end

    def push_payload
      payload = JSON.parse(request.body.read)
      payload["commits"] = [payload["commits"].last] unless options.build_all?
      payload
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
    end
  end
end
