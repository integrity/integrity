module Integrity
  class Commit
    include DataMapper::Resource

    property :id,           Serial
    property :project_id,   Integer
    property :build_id,     Integer
    property :identifier,   String
    property :branch,       String,   length: 255
    property :message,      String,   length: 255
    property :full_message, Text
    property :author,       Author,   length: 255
    property :committed_at, DateTime

    timestamps :at

    belongs_to :project
    belongs_to :build

    def finishes?
      ['finish'].any? { |w| self.message.downcase =~ /#{w}/}
    end
  end
end
