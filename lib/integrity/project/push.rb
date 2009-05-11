module Integrity
  class Project
    module Push
      def push(payload)
        payload = parse_payload(payload)
        raise ArgumentError unless valid_payload?(payload)

        commits =
          if Integrity.config[:build_all_commits]
            payload["commits"]
          else
            [ payload["commits"].first ]
          end

        commits.each { |commit_data|
          commit_from(commit_data).create
          build(commit_data["id"])
        }
      end

      private
        def commit_from(data)
          commits.new(:identifier => data["id"],
            :author  => "#{data["author"]["name"]} <#{data["author"]["email"]}>",
            :message => data["message"],
            :committed_at => data["timestamp"])
        end

        def valid_payload?(payload)
          payload && payload["ref"].to_s.include?(branch) &&
                               !payload["commits"].nil? &&
                               !payload["commits"].to_a.empty?
        end

        def parse_payload(payload)
          JSON.parse(payload.to_s)
        rescue JSON::ParserError
          false
        end
    end
  end
end
