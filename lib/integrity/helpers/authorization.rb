module Integrity
  module Helpers
    module Authorization
      include Sinatra::Authorization

      def authorization_realm
        "Integrity"
      end

      def authorized?
        return true unless protect?
        !!request.env["REMOTE_USER"]
      end

      def authorize(user, password)
        return true unless protect?
        options.user == user && options.pass == password
      end

      def unauthorized!(realm=authorization_realm)
        response["WWW-Authenticate"] = %(Basic realm="#{realm}")
        throw :halt, [401, show(:unauthorized, :title => "incorrect credentials")]
      end

      def protect?
        options.respond_to?(:user) && options.respond_to?(:pass)
      end
    end
  end
end
