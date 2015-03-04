module Integrity
  module Authentication
    def self.included(base)
      base.class_eval do

        get '/login' do
          redirect to root_path unless oauth?
          notify error: 'You must login to continue' if auth_redirect?
          show :login, title: 'login', layout: false
        end

        get '/logout' do
          session.delete(:user)
          notify alert: 'Logged out'
          redirect to unauthorized_path
          show :login, title: 'login', layout: false
        end

        get '/auth/github/callback' do
          auth_profile
          redirect to where_user_came_from
        end

      end
    end
  end
end



