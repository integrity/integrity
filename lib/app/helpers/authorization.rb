module Integrity
  module Helpers
    module Authorization
      include Sinatra::Authorization

      def authorization_realm
        "Integrity"
      end

      def authorized?
        !!request.env["REMOTE_USER"] ||
          authorize(*auth.credentials) if auth.provided?
      end

      def authorize(user, password)
        unless Integrity.config.protected?
          return true
        end

        Integrity.config.username == user &&
          Integrity.config.password == password
      end

      def unauthorized!(realm=authorization_realm)
        response["WWW-Authenticate"] = %(Basic realm="#{realm}")
        throw :halt, [401, show(:unauthorized, :title => "incorrect credentials")]
      end
    end
  end
end
