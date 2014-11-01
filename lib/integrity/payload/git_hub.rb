module Integrity
  module Payload
    class GitHub < Base
      def deleted?
        @payload["deleted"]
      end

      def uri
        if uri = @payload["uri"]
          return uri
        end

        repository = @payload["repository"]

        if repository["private"]
          "git@github.com:#{URI(repository["url"]).path[1..-1]}"
        else
          uri = URI(repository["url"])
          uri.scheme = "git"
          uri.to_s
        end
      end
    end
  end
end
