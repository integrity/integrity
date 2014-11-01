module Integrity
  module Helpers
    module Authentication

      def current_user
        Hashie::Mash.new(session[:user])
      end

      def current_user=(profile)
        user_session = build_user_session(profile)
        session[:user] = user_session.to_hash
      end

      def logged_in?
        !!session[:user]
      end

      def auth_profile
        profile = Hashie::Mash.new(request.env['omniauth.auth'])
        # STDERR.puts profile.to_yaml
        self.current_user = profile.info
        profile
      end

      def where_user_came_from
        session[:previous_url] || '/'
      end

      def build_user_session(profile)
        profile.delete(:urls)
        image = profile.delete(:image)
        username = profile.delete(:nickname)
        profile.merge(avatar: image, username: username)
      end
    end
  end
end
