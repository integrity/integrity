require "app/helpers/authorization"
require "app/helpers/breadcrumbs"
require "app/helpers/pretty_output"
require "app/helpers/rendering"
require "app/helpers/resources"
require "app/helpers/urls"

module Integrity
  module Helpers
    include Authorization, Breadcrumbs, PrettyOutput,
      Rendering, Resources, Urls

    include Rack::Utils
    alias :h :escape_html

    def show_login?
      Integrity.config.protected? && !authorized?
    end
  end
end
