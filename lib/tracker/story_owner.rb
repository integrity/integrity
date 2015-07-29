module Tracker
  class StoryOwner
    include DataMapper::Resource
    belongs_to :user, :key => true
    belongs_to :story, :key => true
  end
end
