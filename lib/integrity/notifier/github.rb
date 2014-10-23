module Integrity
  class Notifier
    class Github < Notifier::Base

      VALID_STATES = %w[started pending success failure error]

      attr_reader :status, :desc

      def initialize(build, config={})
        super
        status = config[:status].presence || :pending
        update_status!(status)
      end

      def deliver!
        client.post github_api, payload, credentials
      end

      # FIXME: Great choice for config and i18n.
      def update_status!(status)
        return false unless status.to_s.in?(VALID_STATES)
        @status = status
        @desc   = case @status.to_sym
                    when :started then 'The build has started on Integrity CI'
                    when :pending then 'The build has started on Integrity CI'
                    when :success then 'The build succeeded on Integrity CI'
                    when :failure then 'The build failure on Integrity CI'
                    when :error   then 'The build raised an error on Integrity CI'
                  end
        true
      end

      def deliver_started_notification!
        update_status!(:pending) and deliver!
      end

      private

      def payload
        {state: status, target_url: url, description: desc, context: :default}.to_json
      end

      def client
        RestClient
      end

      def credentials
        token = Integrity.config.github_token
        {content_type: :json, accept: :json, params: {access_token: token}}
      end

      # FIXME: Should be config
      # /repos/:owner/:repo/statuses/:sha
      def github_api
        "https://api.github.com/repos/#{owner}/#{repo_name}/statuses/#{sha1}"
      end

    end

    register Github
  end
end

