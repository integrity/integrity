Dir["#{File.dirname(__FILE__)}/helpers/*.rb"].each &method(:require)

module Integrity
  module Helpers
    include Authorization
    include Breadcrumbs
    include Forms
    include PrettyOutput
    include Rendering
    include Resources
    include Urls

    include Rack::Utils
    alias :h :escape_html
  end
end
