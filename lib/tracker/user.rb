module Tracker
  class User
    include DataMapper::Resource

    property :id,       Serial
    property :name,     String
    property :email,    String
    property :initials, String
    property :developer, Boolean

    has n, :stories, :through => Resource

    def self.create(membership)
      user = User.new
      user.id       = membership.id
      user.name     = membership.name
      user.email    = membership.email
      user.initials = membership.initials
      user.save
    end
  end
end
