require "diddies"

module Integrity
  module Helpers
    module Authorization
      include Sinatra::Authorization

      def authorization_realm
        "Integrity"
      end

      def authorized?
        return true unless Integrity.config[:use_basic_auth]
        !!request.env["REMOTE_USER"]
      end

      def authorize(user, password)
        if Integrity.config[:hash_admin_password]
          password = Digest::SHA1.hexdigest(password)
        end

        !Integrity.config[:use_basic_auth] ||
        (Integrity.config[:admin_username] == user &&
          Integrity.config[:admin_password] == password)
      end

      def unauthorized!(realm=authorization_realm)
        response["WWW-Authenticate"] = %(Basic realm="#{realm}")
        throw :halt, [401, show(:unauthorized, :title => "incorrect credentials")]
      end
    end
  end
end