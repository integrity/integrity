module Integrity
  class Build
    include DataMapper::Resource

    HUMAN_STATUS = {
      success:  "Built %s successfully",
      failed:   "Built %s and failed",
      pending:  "%s hasn't been built yet",
      building: "%s is building",
      killed: "%s was killed",
      cancelled: "%s was cancelled"
    }
    
    GLOB_CHARS = '*?[]'

    property :id,           Serial
    property :project_id,   Integer   # TODO :nullable => false
    property :branch_id,    Integer,  required: true
    property :output,       Text,     default: '', length: 1048576
    property :successful,   Boolean,  default: false
    property :started_at,   DateTime
    property :completed_at, DateTime
    property :state, String
    property :fleetctl_status, String
    property :machine_ip, String

    timestamps :at

    belongs_to :project
    belongs_to :branch
    has 1,     :commit

    delegate :name, :permalink, to: :project

    after :create do
      project.update(last_build_id: id)
      branch.update(last_build_id: id)
    end

    before :destroy do
      commit.destroy! if commit
      if project.last_build_id == id
        last_id = project.builds(:id.not => id).last.try(:id)
        project.update(last_build_id: last_id)
      end
    end

    delegate :repo, :command, to: :project

    def self.scope(query = :all, *conditions)
      send(query, *conditions)
    end

    def self.pending(query = :all)
      scope(query, started_at: nil, completed_at: nil, state: nil, order: :created_at.asc)
    end

    def self.running(query = :all)
      scope(query, :started_at.not => nil, completed_at: nil, state: nil, order: :started_at.asc)
    end

    def self.orphaned(query = :all)
      scope(query, :started_at.lt => 1.hour.ago, completed_at: nil, order: :started_at.asc)
    end

    def self.update_fleetctl_status
      status = Crust.get_service_status
      status.each do |id, service_status|
        build = Build.first(id: id.to_i)
        build.update_fleetctl_status(service_status) if build
      end
    end

    def run
      Integrity.config.builder.enqueue(self)
    end

    def run!
      return false if invalid_sha?
      Builder.start_build(self)
    end

    def cleanup!
      Builder.destroy_build(self)
    end

    def update_fleetctl_status(status)
      app_status = status.select{|s| s[:type] == "app"}.first
      update(fleetctl_status: app_status[:active], machine_ip: app_status[:ip])
      if (fleetctl_status == 'failed') and building?
        kill!({ cleanup: false })
      end
    end

    def complete!(result)
      success = result.respond_to?(:success) ? result.success : result
      set_as_complete(success) and cleanup!
    end

    def kill!(params = {})
      cleanup = params[:cleanup] || true
      cleanup! if cleanup
      update(state: 'killed', completed_at: Time.now)
    end

    def cancel!
      update(state: 'cancelled', completed_at: Time.now)
    end

    def interrupted?
      status == :killed || status == :cancelled
    end

    def completed?
      !completed_at.nil?
    end

    def finished?
      completed? && !interrupted?
    end

    def started?
      !started_at.nil?
    end

    def fail!(message=nil)
      set_as_complete(false)
    end

    def notify
      project.enabled_notifiers.each { |n| n.notify(self) }
    end

    def successful?
      successful == true
    end

    def failed?
      !successful?
    end

    def building?
      started?  && !completed? && !killed?
    end

    def pending?
      started_at.nil? && completed_at.nil?
    end

    def invalid_sha?
      sha1.blank? || sha1 == 'HEAD'
    end

    def sha1
      commit.try(:identifier).presence || "build_#{id}"
    end

    def sha1_short
      return id.to_s unless commit.try(:identifier)
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
      return state.to_sym if state
      case
      when building?   then :building
      when pending?    then :pending
      when successful? then :success
      when failed?     then :failed
      else :unknown
      end
    end

    def in_progress?
      pending? || building?
    end

    def human_status
      HUMAN_STATUS[status].try(:%, sha1_short)
    end

    def killed?
      state == 'killed'
    end
    
    def human_duration
      Integrity.human_duration(duration)
    end

    def bootstrap_class
      case status
      when :building then 'info'
      when :success then 'success'
      when :failed then 'danger'
      when :pending then 'warning'
      when :killed then 'killed'
      end
    end

    def duration
      return false if !completed? or !started_at
      Integrity.delta(completed_at, started_at)
    end

    def human_time_since_start
      Integrity.human_duration(time_since_start)
    end

    def time_since_start
      return if pending?
      # to_i returns utc timestamp
      Integrity.delta(Time.now, started_at)
    end

    alias_method :time_elapsed, :human_time_since_start

    def build_directory
      Pathname.new(Integrity.config.directory).join(self.id.to_s)
    end

    def set_as_complete(success = false)
      self.raise_on_save_failure = true
      update(completed_at: Time.now, successful: success)
      notify
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

    def service_name
      "#{name}_#{sha1_short}_#{id}"
    end
  end
end
