require 'webrat/rack'
require 'sinatra'
require 'sinatra/test/methods'

require 'sinatra/test/unit'
require 'sinatra/test/rspec' if Object.const_defined?(:Spec)

module Webrat
  class SinatraSession < RackSession #:nodoc:
    include Sinatra::Test::Methods

    attr_reader :response

    def get(path, data, h = {})
      do_request(:get, path, data, h.merge(headers))
    end

    def post(path, data, h = {})
      do_request(:post, path, data, h.merge(headers))
    end

    def put(path, data, h = {})
      do_request(:put, path, data, h.merge(headers))
    end

    def delete(path, data, h = {})
      do_request(:delete, path, data, h.merge(headers))
    end

    private
      def do_request(verb, path, data, headers)
        params = data.merge(:env => headers)
        self.__send__("#{verb}_it", path, params)
        follow! while response.redirect?
      end
  end

  module SinatraTestCase
    include Webrat::Methods

    %w(get head post put delete).each do |meth|
      define_method(meth) do |*args|
        args << {} if args.size == 1
        webrat_session.send(meth, *args)
      end
    end

    def body
      webrat_session.response_body
    end

    def status
      webrat_session.response_code
    end
  end
end

Test::Unit::TestCase.send(:include, Webrat::SinatraTestCase)
Webrat.configuration.mode = :sinatra
