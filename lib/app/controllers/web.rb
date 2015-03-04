module Integrity
  module Web
    def self.included(base)
      base.class_eval do

        # Settings
        get '/settings' do
          @load_utilization = LoadUtilization.current
          loads = [Integrity::LoadUtilization.first(:created_at.lt => 10.minutes.ago)]
          (1..23).each do |n|
            loads << Integrity::LoadUtilization.first(:created_at.lt => n.hour.ago)
          end
          @usage = loads.compact.map(&:usage)
          show :settings, title: 'settings'
        end

        # Change Settings
        post '/settings' do
          redirect '/settings'
        end

        get '/jobs' do
          show :jobs, title: 'jobs'
        end

        # List Honesty Users
        get '/users' do
          @users = Integrity::User.all
          show :users, title: 'Users'
        end

      end
    end
  end
end