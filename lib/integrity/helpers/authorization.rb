module Integrity
  module Helpers
    module Authorization
      include Sinatra::Authorization

      def authorization_realm
        "Integrity"
      end

      def authorized?
        return true unless Integrity.config.protect?
        !!request.env["REMOTE_USER"]
      end

      def authorize(user, password)
        return true unless Integrity.config.protect?
        Integrity.config.user == user && Integrity.config.pass == password
      end

      def unauthorized!(realm=authorization_realm)
        response["WWW-Authenticate"] = %(Basic realm="#{realm}")
        throw :halt, [401, show(:unauthorized, :title => "incorrect credentials")]
      end
    end
  end
end
