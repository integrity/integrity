module Sinatra
  # HTTP Authorization helpers for Sinatra.
  #
  # In your helpers module, include Sinatra::Authorization and then define
  # a +authorize(user, password)+ method to handle user provided
  # credentials.
  # 
  # Inside your events, call +login_required+ to trigger the HTTP 
  # Authorization window to pop up in the browser.
  #
  # Code adapted from Ryan Tomayko <http://tomayko.com> and Christopher 
  # Schneid <http://gittr.com>, shared under an MIT License  
  module Authorization
    # Redefine this method on your helpers block to actually contain
    # your authorization logic.
    def authorize(username, password)
      false
    end

    # Override in your application to return the name of your app
    def authorization_realm
      "[Remember to Override Me]"
    end

    # Call in any event that requires authentication
    def login_required
      return if authorized?
      unauthorized! unless auth.provided?
      bad_request! unless auth.basic?
      unauthorized! unless authorize(*auth.credentials)
      request.env['REMOTE_USER'] = auth.username
    end

    # Convenience method to determine if a user is logged in
    def authorized?
      request.env['REMOTE_USER']
    end
    alias :logged_in? :authorized?

    # Name provided by the current user to log in
    def current_user
      request.env['REMOTE_USER']
    end

    private

      def auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
      end

      def unauthorized!(realm=authorization_realm)
        header 'WWW-Authenticate' => %(Basic realm="#{realm}")
        throw :halt, [ 401, 'Authorization Required' ]
      end

      def bad_request!
        throw :halt, [ 400, 'Bad Request' ]
      end
  end
end
