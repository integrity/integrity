module Integrity
  class Commit
    include DataMapper::Resource

    property :id,           Serial
    property :build_id,     Integer
    property :identifier,   String
    property :message,      String,   :length => 255
    property :author,       Author,   :length => 255
    property :committed_at, DateTime

    timestamps :at

    belongs_to :build
  end
end
