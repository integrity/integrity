require 'app/models'
require 'app/helpers'
require 'app/controllers'

module Integrity
  class App < Sinatra::Base
    register Sinatra::StaticAssets

    configure do
      enable  :sessions, :reload_templates, :partial_underscores, :logging, :methodoverride, :static
      disable :build_all

      set :partial_template_engine, :erb
      set :environment, ENV['RACK_ENV'] || :production
    end

    not_found do
      status 404
      show :not_found, title: 'lost, are we?'
    end

    error do
      @error = request.env['sinatra.error']
      log "error: #{@error.inspect}"
      status 500
      show :error, title: 'something has gone terribly wrong'
    end

    before do
      login_required
      setup_env
    end

    # Helpers
    helpers Integrity::Helpers

    # Controllers
    include Integrity::Api
    include Integrity::Authentication
    include Integrity::Web

    include Integrity::Diligence
    include Integrity::Projects
    include Integrity::Branches
    include Integrity::Builds

    # i18n translations
    load_translations
  end
end
