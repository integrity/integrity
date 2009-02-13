require 'webrat/rack'
require 'sinatra'
require 'sinatra/test'

set :environment, :test
disable :run
disable :reload

Webrat.configuration.instance_variable_set("@mode", :sinatra)

module Webrat
  class SinatraSession < Session
    DEFAULT_DOMAIN = "integrity.example.org"

    def initialize(context = nil)
      super(context)
      @sinatra_test = Sinatra::TestHarness.new
    end

    %w(get head post put delete).each do |verb|
      class_eval <<-METHOD
        def #{verb}(path, data, headers = {})
          params = data.inject({}) do |data, (key,value)|
            data[key] = Rack::Utils.unescape(value)
            data
          end
          headers['HTTP_HOST'] = DEFAULT_DOMAIN
          @sinatra_test.#{verb}(path, params, headers)
        end
      METHOD
    end

    def response_body
      @sinatra_test.body
    end

    def response_code
      @sinatra_test.status
    end

    private

    def response
      @sinatra_test.response
    end

    def current_host
      URI.parse(current_url).host || DEFAULT_DOMAIN
    end

    def response_location_host
      URI.parse(response_location).host || DEFAULT_DOMAIN
    end
  end
end

require Integrity.root / "app"
require File.dirname(__FILE__) / "acceptance/git_helper"

module AcceptanceHelper
  include FileUtils

  def export_directory
    Integrity.root / "exports"
  end

  def enable_auth!
    Integrity.config[:use_basic_auth]      = true
    Integrity.config[:admin_username]      = "admin"
    Integrity.config[:admin_password]      = "test"
    Integrity.config[:hash_admin_password] = false
  end

  def login_as(user, password)
    def AcceptanceHelper.logged_in; true; end
    basic_auth user, password
    visit "/login"
    Sinatra::Application.before { login_required if AcceptanceHelper.logged_in }
  end

  def log_out
    def AcceptanceHelper.logged_in; false; end
    @_webrat_session = Webrat::SinatraSession.new(self)
  end

  def disable_auth!
    Integrity.config[:use_basic_auth] = false
  end

  def set_and_create_export_directory!
    FileUtils.rm_r(export_directory) if File.directory?(export_directory)
    FileUtils.mkdir(export_directory)
    Integrity.config[:export_directory] = export_directory
  end

  def setup_log!
    pathname = Integrity.root / "integrity.log"
    FileUtils.rm pathname if File.exists?(pathname)
    Integrity.config[:log] = pathname
  end
end

class Test::Unit::AcceptanceTestCase < Test::Unit::TestCase
  include AcceptanceHelper
  include Test::Storyteller
  include GitHelper
  include Webrat::Methods
  Webrat::Methods.delegate_to_session :response_code

  before(:all) do
    Integrity.config[:base_uri] = "http://#{Webrat::SinatraSession::DEFAULT_DOMAIN}"
  end

  before(:each) do
    # ensure each scenario is run in a clean sandbox
    setup_and_reset_database!
    enable_auth!
    setup_log!
    set_and_create_export_directory!
    log_out
  end

  after(:each) do
    destroy_all_git_repos
    rm_r export_directory if File.directory?(export_directory)
  end
end
