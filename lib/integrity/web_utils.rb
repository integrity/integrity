module Integrity
  module WebUtils

    private

    def set_permalink
      attribute_set(:permalink,
      (name || '').downcase.
        gsub(/'s/, 's').
        gsub(/&/, 'and').
        gsub(/[^a-z0-9]+/, '-').
        gsub(/-*$/, '')
      )
    end


  end
end