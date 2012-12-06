module Integrity
  class Build
    include DataMapper::Resource

    HUMAN_STATUS = {
      :success  => "Built %s successfully",
      :failed   => "Built %s and failed",
      :pending  => "%s hasn't been built yet",
      :building => "%s is building"
    }
    
    GLOB_CHARS = '*?[]'

    property :id,           Serial
    property :project_id,   Integer   # TODO :nullable => false
    property :output,       Text,     :default => "", :length => 1048576
    property :successful,   Boolean,  :default => false
    property :started_at,   DateTime
    property :completed_at, DateTime

    timestamps :at

    belongs_to :project
    has 1,     :commit

    after :create do
      project.raise_on_save_failure = true
      project.update(:last_build_id => id)
    end

    before :destroy do
      if commit
        commit.destroy!
      end
    end

    def run
      Integrity.config.builder.enqueue(self)
    end

    def run!
      Builder.build(self, Integrity.config.directory, Integrity.logger)
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

    def repo
      project.repo
    end

    def command
      project.command
    end

    def sha1
      if commit
        commit.identifier
      else
        '(commit is missing)'
      end
    end

    def sha1_short
      unless commit
        return '(commit is missing)'
      end

      unless sha1
        return "This commit"
      end

      sha1[0..6]
    end

    def message
      if commit
        commit.message || "message not loaded"
      else
        '(commit is missing)'
      end
    end

    def full_message
      if commit
        # commit.message fallback is here because we don't have migrations (yet?)
        commit.full_message || commit.message || "message not loaded"
      else
        '(commit is missing)'
      end
    end

    def author
      if commit
        (commit.author || Author.unknown).name
      else
        '(commit is missing)'
      end
    end

    def committed_at
      if commit
        commit.committed_at
      else
        # UI expects a date, give it to it
        Time.utc(1970)
      end
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
      delta = Integrity.datetime_to_time(completed_at).to_i - Integrity.datetime_to_time(started_at).to_i
      ChronicDuration.output(delta, :format => :micro)
    end
    
    def human_time_since_start
      return if pending?
      delta = Time.now.utc.to_i - Integrity.datetime_to_time(started_at).utc.to_i
      ChronicDuration.output(delta, :format => :micro)
    end

    def build_directory
      Pathname.new(Integrity.config.directory).join(self.id.to_s)
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
=begin
      # for file in build dir check below
      build_dir = File.expand_path(build_dir)
=end
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

=begin
      # check that all files are under the build dir
      all_files.map! do |file|
        File.expand_path(file)
      end
      all_files.delete_if do |file|
        file[0, build_dir_with_slash.length] != build_dir_with_slash
      end
=end

      all_files.map! do |file|
        if file[0, build_dir_with_slash.length] == build_dir_with_slash
          relative_path = file[build_dir_with_slash.length..-1]
        else
          relative_path = file
        end
        {
          :name => File.basename(file),
          :relative_path => relative_path,
        }
      end
      all_files.sort do |a, b|
        a[:name] <=> b[:name]
      end
    end
  end
end
