module Integrity
  class Build
    include DataMapper::Resource

    HUMAN_STATUS = {
      success:  "Built %s successfully",
      failed:   "Built %s and failed",
      pending:  "%s hasn't been built yet",
      building: "%s is building"
    }
    
    GLOB_CHARS = '*?[]'

    property :id,           Serial
    property :project_id,   Integer   # TODO :nullable => false
    property :branch_id,    Integer,  required: true
    property :output,       Text,     default: '', length: 1048576
    property :successful,   Boolean,  default: false
    property :started_at,   DateTime
    property :completed_at, DateTime

    timestamps :at

    belongs_to :project
    belongs_to :branch
    has 1,     :commit

    after :create do
      project.raise_on_save_failure = true
      project.update(last_build_id: id)
    end

    before :destroy do
      commit.destroy! if commit
    end

    delegate :repo, :command, to: :project

    def run
      # Integrity.config.builder.enqueue(self)
      Integrity.start_service(project.permalink, sha1_short)
    end

    def run!
      # Builder.build(self, Integrity.config.directory, Integrity.logger)
      # Builder.docker(self, Integrity.config.directory, Integrity.logger)
      Integrity.start_service(project.permalink, sha1_short)
    end

    def complete!(result)
      set_as_complete(result.output, result.success)
    end

    def fail!(message)
      set_as_complete(message)
    end

    def notify
      project.enabled_notifiers.each { |n| n.notify(self) }
    end

    def successful?
      successful == true
    end

    def failed?
      ! successful?
    end

    def building?
      ! started_at.nil? && completed_at.nil?
    end

    def pending?
      started_at.nil?
    end

    def completed?
      ! pending? && ! building?
    end

    def sha1
      commit.try(:identifier).presence || '(commit is missing)'
    end

    def sha1_short
      return '(commit is missing)' unless commit
      return 'This commit' unless sha1
      sha1[0..6]
    end

    def message
      commit.try(:message).presence || 'message not loaded'
    end

    def full_message
      commit.try(:full_message).presence || commit.try(:message).presence || 'message not loaded'
    end

    def author
      (commit.try(:author) || Author.unknown).name
    end

    def committed_at
      commit.try(:committed_at) || Time.now.utc
    end

    def status
      case
      when building?   then :building
      when pending?    then :pending
      when successful? then :success
      when failed?     then :failed
      end
    end

    def human_status
      HUMAN_STATUS[status] % sha1_short
    end
    
    def human_duration
      return if pending? || building?
      delta = Integrity.delta(completed_at, started_at)
      Integrity.human_duration(delta)
    end
    
    def human_time_since_start
      return if pending?
      # to_i returns utc timestamp
      delta = Integrity.delta(Time.now, started_at)
      Integrity.human_duration(delta)
    end
    alias_method :time_elapsed, :human_time_since_start

    def build_directory
      Pathname.new(Integrity.config.directory).join(self.id.to_s)
    end

    def set_as_complete(message, success = false)
      self.raise_on_save_failure = true
      update(completed_at: Time.now, successful: success, output: message)
    end

    def escape_glob(path)
      escaped = path
      each_char(GLOB_CHARS) do |char|
        escaped = escaped.sub(char, "\\" + char)
      end
      escaped
    end
    private :escape_glob
    
    def each_char(str)
      if str.respond_to?(:each_char)
        # ruby 1.9
        str.each_char do |char|
          yield char
        end
      else
        # ruby 1.8
        str.each do |char|
          yield char
        end
      end
    end
    private :each_char
    
    def artifact_files
      build_dir = build_directory
      escaped_build_dir = nil
      all_files = []
      project.get_artifacts.each do |artifact|
        if GLOB_CHARS.split('').any? { |char| artifact.include?(char) }
          if escaped_build_dir.nil?
            escaped_build_dir = escape_glob(build_dir.to_s)
          end

          pattern = File.join(escaped_build_dir, artifact)
          all_files += Dir[pattern]
        else
          file = build_dir.join(artifact).to_s
          if File.exist?(file)
            all_files << file
          end
        end
      end

      build_dir_with_slash = build_dir.to_s + '/'

      all_files.map! do |file|
        if file[0, build_dir_with_slash.length] == build_dir_with_slash
          relative_path = file[build_dir_with_slash.length..-1]
        else
          relative_path = file
        end
        {name: File.basename(file), relative_path: relative_path}
      end
      all_files.sort do |a, b|
        a[:name] <=> b[:name]
      end
    end
    
    def to_json
      {build: {id: id, project: {name: project.name}, status: status}}.to_json
    end
  end
end
