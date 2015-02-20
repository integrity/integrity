module Integrity
  module DataUtils

    def blank?
      builds.count.zero?
    end

    def sorted_builds
      builds(order: [:created_at.desc, :id.desc])
    end

    def builds_before(build)
      sorted_builds.all(:created_at.lt => build.created_at)
    end

    def attributes_for_json
      {name: name, status: status}
    end

    def to_json
      {self.class.name.underscore => attributes_for_json}.to_json
    end

    def github?
      uri.to_s.include?('github.com')
    end

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