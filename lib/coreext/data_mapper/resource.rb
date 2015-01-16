module DataMapper
  module Resource

    def self.scope(query = :all, *conditions)
      send(query, *conditions)
    end

  end
end