module Integrity
  class Commit
    include DataMapper::Resource

    property :id,           Serial
    property :build_id,     Integer
    property :identifier,   String,   :nullable => false
    property :message,      String,   :length => 255
    property :author,       Author,   :length => 255
    property :committed_at, DateTime

    timestamps :at

    belongs_to :build

    def message
      attribute_get(:message) || "<Commit message not loaded>"
    end

    def author
      attribute_get(:author) ||
        Author.load('<Commit author not loaded> <<Commit author not loaded>>', :author)
    end

    def committed_at
      attribute_get(:committed_at) || DateTime.new
    end

    def short_identifier
      identifier.to_s[0..6]
    end

    def status
      build.nil? ? :pending : build.status
    end

    def successful?
      status == :success
    end

    def failed?
      status == :failed
    end

    def pending?
      status == :pending
    end

    def building?
      status == :building
    end


    def output
      build && build.output
    end
  end
end
