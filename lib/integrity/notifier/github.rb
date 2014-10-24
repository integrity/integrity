module Integrity
  class Notifier
    class Github < Notifier::Base

      VALID_STATES = %w[started pending success failure failed error]

      attr_reader :status, :desc

      def initialize(build, config={})
        super
        update_status!(build.status)
      end

      def deliver!
        Integrity.logger.info 'Posting Github Status'
        Integrity.logger.info '====================='
        Integrity.logger.info "API:     #{github_api}"
        Integrity.logger.info "PAYLOAD: #{payload}"
        Integrity.logger.info "CREDS:   #{credentials.inspect}"
        Integrity.logger.info '====================='
        client.post github_api, payload, credentials
      end

      # FIXME: Great choice for config and i18n.
      def update_status!(status)
        @status = status.presence || :pending
        return false unless status.to_s.in?(VALID_STATES)
        @status = (@status == :failed) ? :failure : status
        @desc   = case @status.to_sym
                    when :started then 'The build has started on Integrity CI'
                    when :pending then 'The build is running on Integrity CI'
                    when :success then 'The build succeeded on Integrity CI'
                    when :failure then 'The build failed on Integrity CI'
                    when :error   then 'The build raised an error on Integrity CI'
                  end
        @status = :pending if @status == :started  # If starting, send github pending status and started message
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

    end

    register Github
  end
end

