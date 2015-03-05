begin
  require '.bundle/environment'
rescue LoadError
  require 'bundler/setup'
end

# Ruby Core
require 'yaml'
require 'logger'
require 'digest/sha1'
require 'timeout'
require 'ostruct'
require 'pathname'
require 'json'
require 'haml'
require 'sass'
require 'cgi'
require 'rubygems'

# Omniauth/Authentication
require 'omniauth'
require 'omniauth-github'

# Rack
require 'rack'
require 'rack/flash'

# Sinatra
require 'sinatra'
require 'sinatra/base'
require 'sinatra/authorization'
require 'sinatra/static_assets'

# ActiveSupport
require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/string/inflections'
require 'active_support/hash_with_indifferent_access'

# DataMapper
require 'data_mapper'
require 'dm-core'
require 'dm-validations'
require 'dm-types'
require 'dm-timestamps'
require 'dm-aggregates'
require 'dm-migrations'
require 'coreext/data_mapper/resource'

# Gems/Utils
require 'addressable/uri'
require 'chronic_duration'
require 'bcat/ansi'
require 'rconfig'
require 'i18n'
require 'rest_client'
require 'hashie'
require 'crust'

require 'opts/rconfig'

require 'commands'
require 'runnable'
require 'docker'

# I18n Translations
translations = YAML.load_file(File.join(ROOT_DIR, 'config', 'locale', 'en.yml'))
I18n.load_path << "#{ROOT_DIR}/config/locale/dates.en.yml"
I18n.backend.store_translations(:en, translations)

# DataMapper
DataMapper.finalize

# Addressable/URI
Addressable::URI.class_eval do
  def gsub(*args)
    to_s.gsub(*args)
  end
end

# Encoding
if Object.const_defined?(:Encoding) && Encoding.respond_to?(:default_internal=)
  # ruby 1.9
  # Internal encoding is what is used on ruby strings.
  Encoding.default_internal = Encoding::UTF_8
  # External encoding is what is used on pipes used to communicate with
  # launched command runners and is the default encoding used when opening
  # e.g. the log file.
  Encoding.default_external = Encoding::UTF_8
end