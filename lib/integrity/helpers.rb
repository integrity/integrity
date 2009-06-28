require "integrity/helpers/authorization"
require "integrity/helpers/breadcrumbs"
require "integrity/helpers/pretty_output"
require "integrity/helpers/rendering"
require "integrity/helpers/resources"
require "integrity/helpers/urls"

module Integrity
  module Helpers
    include Authorization
    include Breadcrumbs
    include PrettyOutput
    include Rendering
    include Resources
    include Urls

    include Rack::Utils
    alias :h :escape_html
  end
end
