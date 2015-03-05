module Integrity
  module Helpers
    module Authentication

      def login_required
        unauthorized! unless (authorized_ip? || web_hook? || status_update?) # Ok to talk?
        return true if authorized? || web_hook? || status_update? # Already authenticated
        return unless protected?  # Auth not enabled
        return true if login_page? || logging_out? # Logging in or out

        # Authenticate with basic auth
        if auth_basic?
          unauthorized! unless auth.provided?
          bad_request!  unless auth.basic?
          unauthorized! unless authorize(*auth.credentials)
          request.env['REMOTE_USER'] = auth.username
          return true # Authenticated successfully
        end

        set_requested_path # Remember where they are going

        return auth_profile if development? # Don't use oauth in development

        # Send to authenticate with provider (i.e. github)
        redirect to oauth_provider if oauth?

        # Auth enabled but no basic or oauth??
        # Go to root path with no access
        session[:need_login] = true
        redirect to unauthorized_path
      end
      alias :authenticate_and_authorize :login_required

      def current_user
        Hashie::Mash.new(session[:user])
      end

      def current_user=(profile)
        session[:user] = build_user_session(profile)
      end

      def authorized?
        !!session[:user]
      end
      alias :logged_in? :authorized?

      def auth_profile
        auth = development? ? dev_user : request.env['omniauth.auth']
        #auth = request.env['omniauth.auth']
        profile = Hashie::Mash.new(auth)
        STDERR.puts "USER PROFILE:\n#{profile.to_yaml}"
        self.current_user = profile.info
        request.env['REMOTE_USER'] = current_user.username
        profile
      end

      def authorized_ip?
        remote_ip.index('10.') == 0 || development?
      end

      def show_login?
        protected? && !authorized?
      end

      def auth_basic?
        protected? && config.basic?
      end

      def oauth?
        config.oauth?
      end

      def protected?
        config.protected?
      end

      def oauth_provider
        "/auth/#{config.oauth_provider}"
      end

      def set_requested_path
        session[:requested_path] = request.path_info
      end

      def where_user_came_from
        session[:requested_path] || '/'
      end

      def login_page?
        request.path_info == '/login'
      end

      def logging_out?
        request.path_info == '/logout'
      end

      def auth_redirect?
        flag = !!session[:need_login]
        session[:need_login] = false
        flag
      end

      def dev_user
        {info: {name: 'Dev User', nickname: 'development', image: '/images/github-user.png'}}
      end

      private

      def unauthorized!(realm=authorization_realm)
        throw :halt, [403, 'Authorization Required']
      end

      def build_user_session(profile)
        profile.delete(:urls)
        image = profile.delete(:image)
        username = profile.delete(:nickname)
        profile.merge(avatar: image, username: username).to_hash
      end
    end
  end
end
