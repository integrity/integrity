module Integrity
  class Notifier
    class Github < Notifier::Base

      VALID_STATES = %w[started pending building success failure failed error]

      attr_reader :status, :desc

      def initialize(build, config={})
        super
        update_status!(build.status)
      end

      def deliver!
        client.post github_api, payload, credentials
      rescue RestClient::Exception => e
        deliver_error e
      end

      # FIXME: Great choice for config and i18n.
      def update_status!(status)
        @status = status.presence || :pending
        return false unless status.to_s.in?(VALID_STATES)
        @status, @desc =
          case @status.to_sym
            when :started, :pending, :building
              [:pending, 'The build has is running on Integrity CI']
            when :success
              [:success, 'The build succeeded on Integrity CI']
            when :failed, :failure
              [:failure, 'The build failed on Integrity CI']
            when :error
              [:error,   'The build raised an error on Integrity CI']
          end
        true
      end

      def deliver_started_notification!
        update_status!(:started) and deliver!
      end

      private

      def payload
        {state: status, target_url: build_url, description: desc, context: :default}.to_json
      end

      def client
        RestClient
      end

      def credentials
        token = Integrity.config.github_write_token
        {content_type: :json, accept: :json, params: {access_token: token}}
      end

      # FIXME: Should be config
      # /repos/:owner/:repo/statuses/:sha
      def github_api
        "https://api.github.com/repos/#{repo.owner}/#{repo.name}/statuses/#{sha1}"
      end

      def deliver_error(e)
        msg = "Could Not send notification! - ("
        msg << "endpoint: #{github_api}"
        msg << ", payload: #{payload.inspect}"
        msg << ", credentials: #{credentials.inspect}"
        msg << ")\n#{e.inspect}\n#{e.backtrace}"
        Integrity.say msg
      end

      def self.list_commits(repo)
        github_api = "https://api.github.com/repos/#{repo.owner}/#{repo.name}/commits"
        token = Integrity.config.github_read_token
        credentials = {content_type: :json, accept: :json, params: {access_token: token}}
        RestClient.get github_api, credentials
      end

    end

    register Github
  end
end

