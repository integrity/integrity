module Integrity
  class Commit
    include DataMapper::Resource

    property :id,           Integer,  :serial => true
    property :identifier,   String,   :nullable => false
    property :message,      String,   :length => 255
    property :author,       Author,   :length => 255
    property :committed_at, DateTime
    property :created_at,   DateTime
    property :updated_at,   DateTime

    has 1,     :build,   :class_name => "Integrity::Build", :order => [:created_at.desc]
    belongs_to :project, :class_name => "Integrity::Project"

    def message
      attribute_get(:message) || "<Commit message not loaded>"
    end
    
    def author
      attribute_get(:author) || Author.load('<Commit author not loaded> <<Commit author not loaded>>', :author)
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

    def human_readable_status
      case status
      when :success; "Built #{short_identifier} successfully"
      when :failed;  "Built #{short_identifier} and failed"
      when :pending; "#{short_identifier} hasn't been built yet"
      end
    end

    def output
      build && build.output
    end

    def queue_build
      self.build = Build.create(:commit_id => id)
      self.save

      # Build on foreground (this will move away, I promise)
      ProjectBuilder.new(project).build(self)
    end

    # Deprecation layer
    alias :short_commit_identifier :short_identifier
    alias :commit_identifier       :identifier
    alias :commit_author           :author
    alias :commit_message          :message
    alias :commited_at             :committed_at
  end
end