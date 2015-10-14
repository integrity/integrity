module Tracker
  class User
    include DataMapper::Resource

    property :id,        Serial
    property :name,      String
    property :email,     String
    property :initials,  String
    property :developer, Boolean
    property :product,   Boolean

    property :sheriff,   Boolean
    property :ranger,    Boolean
    property :deputy,    Boolean
    property :santa,     Boolean

    has n, :story_owners
    has n, :owned_stories, 'Tracker::Story', :through => :story_owners, :via => :story
    has n, :requested_stories, :model => 'Tracker::Story', :child_key => [ :requestor_id ]

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
