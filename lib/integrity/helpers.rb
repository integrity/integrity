require "integrity/helpers/authorization"
require "integrity/helpers/breadcrumbs"
require "integrity/helpers/pretty_output"
require "integrity/helpers/rendering"
require "integrity/helpers/resources"
require "integrity/helpers/urls"
require "integrity/helpers/push"

module Integrity
  module Helpers
    include Authorization, Breadcrumbs, PrettyOutput,
      Rendering, Resources, Urls

    include Rack::Utils
    alias :h :escape_html
  end
end
