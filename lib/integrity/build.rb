require 'integrity/build/status'

    # The Simple Path for a Build to Run (this is a rebuild, for a new build based on a payload, the beginning part is more complicated)
    #- From app.rb, post to /:build to rebuild. this calls project.build
    #- If the build is valid, then project.build creates a new build and calls build.run
    #- build.run is called, triggering action 'build:queue'
    #- 'build:queue' runs Integrity.builder.enqueue(build)
    #- Integrity.builder.enqueue(build) then calls Delayed::Job.enqueue(BuildJob.new(build))
    #- BuildJob.new(build) calls Build.get!(@build).run!
    #- Build.get(@build).run! calls event Integrity::Event.trigger('build:start', self.id)
    #- Event 'build:start' calls Integrity.builder.run(:start_build, build)
    #- Integrity.builder.run calls Delayed::Job.enqueue(BuildManagerJob.new(action, build))
    #- BuildManagerJob.new() calls Integrity::Builder.send(:start_build, @build)
    #- Integrity::Builder.start_build calls Integrity::Builder.launch_build if there is capacity
    #- If the build has not already finished and there is capacity, then Integrity::Builder.launch_build, will call Builder.start_build
    #- Builder.start_build will actually do the build

module Integrity
  class Build
    include DataMapper::Resource
    extend DataMapper::Resource::ClassMethods
    include Status
    include HonestyCluster::SwarmBackend::Build

    GLOB_CHARS = '*?[]' unless defined?(GLOB_CHARS)
    MERCY_KILL_TIMESPAN = 20.minutes unless defined?(MERCY_KILL_TIMESPAN)

    property :id,                    Serial
    property :project_id,            Integer, required: true
    property :branch_id,             Integer, required: true
    property :output,                Text,    default: '', length: 1048576
    property :successful,            Boolean, default: false
    property :rebuild,               Boolean, default: false
    property :started_at,            DateTime
    property :completed_at,          DateTime
    property :state,                 String
    property :fleetctl_status,       String
    property :machine_ip,            String
    property :kill_reason,           String, default: '', length:512
    property :fail_category,         String, default: '', length:512

    timestamps :at

    belongs_to :project
    belongs_to :branch
    has 1,     :commit

    delegate :name, :permalink, :repo, :command, :datastore, to: :project

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

    def branch_name
      branch.try(:name)
    end

    def repo_full_name
      repo.full_name
    end

    def run
      log 'run'
      Integrity::Event.trigger('build:queue', self.id)
    end

    def run!
      log 'run!'
      return false if invalid_sha?
      Integrity::Event.trigger('build:start', self.id)
    end

    def complete!(result)
      success = result.respond_to?(:success) ? result.success : result
      log "[complete!][fi] with success #{success} and result #{result}. Setting_as_complete and cleanup next!"
      set_as_complete(success)
      Integrity::Event.trigger('build:cleanup', self.id)
    end

    def cancel_with_reason(agent, reason, method_name)
      description = "Killed by [#{agent}] because [#{reason}] in method [#{method_name}]"
      log "[kill_with_reason][fi] #{description}"
      update(kill_reason: description)
      cancel!
    end

    def cancel_previous_builds!
      previous_in_progress_builds = branch.builds_before(self).select{|b| b.in_progress?}
      log %Q{[cancel_previous_builds!]: #{previous_in_progress_builds.map{|b| b.id}.join(",") }}
      previous_in_progress_builds.each do |b|
        b.cancel_with_reason('Honesty', 'More recent commit on branch submitted', 'cancel_previous_builds')
      end
    end

    def started!
      log 'started!'
      update(started_at: Time.now)
      StatHatWrapper.post_count("honesty started builds~#{project.name},all", 1)
    end

    def notify
      return if Integrity.config.dtest?
      project.enabled_notifiers.each { |n| n.notify(self) }
    end

    def reload
      self.class.get(id)
    end

    def invalid_sha?
      sha1.blank? || sha1 == 'HEAD'
    end

    def sha1
      commit.try(:identifier).presence
    end

    def sha1_short
      sha1.to_s[0..6]
    end
    alias_method :sha, :sha1_short

    def message
      commit.try(:message).presence || 'message not loaded' end

    def full_message
      commit.try(:full_message).presence || message
    end

    def author
      (commit.try(:author) || Author.unknown).name
    end

    def committed_at
      commit.try(:committed_at) || Time.now.utc
    end

    def human_duration
      Integrity.human_duration(duration)
    end

    def duration
      return false unless completed? && started?
      Integrity.delta(completed_at, started_at)
    end

    def human_time_since_start
      Integrity.human_duration(time_since_start)
    end
    alias_method :time_elapsed, :human_time_since_start

    def time_since_start
      return if pending?
      Integrity.delta(Time.now, started_at)
    end

    def run_time
      duration || time_since_start
    end

    def human_run_time
      Integrity.human_duration(run_time)
    end

    def build_directory
      Pathname.new(Integrity.config.directory).join(self.id.to_s)
    end

    def set_as_complete(success = false)
      log "[set_as_complete!][fi] with success #{success}."
      self.raise_on_save_failure = true
      update(completed_at: Time.now, successful: success)
      notify

      StatHatWrapper.post_value("honesty completed build duration~#{project.name},all", run_time / 60.0)
      StatHatWrapper.post_count("honesty #{success ? 'green' : 'red'} builds~#{project.name},all", 1)
      StatHatWrapper.post_count("honesty completed builds~#{project.name},all", 1)
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

    def url
      "/#{permalink}/builds/#{id}"
    end

    def service_vars
      [permalink, sha1_short, id]
    end

    def service_name
      service_vars.join('_')
    end

    def project_name
      project.permalink
    end

    def app_service_name
      "#{service_name}_app"
    end

    def enter_instructions
      [
        "ssh core@#{machine_ip || '127.0.0.1'}",
        "docker exec -it #{app_service_name} bash",
        "cd #{project.name}",
        "Load correct environment variables (from honesty/build.sh)"
      ]
    end

    def load_score
      try(:project).try(:weight)
    end

    def log(msg)
      Integrity.logger.info "[Integrity::Build]:[Build:#{id}] event:#{msg}, params:#{self.inspect}"
    end

    def consider_mercy_kill
      if mercy_kill?
        log("[consider_mercy_kill][fi] Mercy Killing Unit")
        cancel_with_reason('Coreos', 'Failed on CoreOS', 'consider_mercy_kill')
      end
    end

    private

    def cancel!
      log '[cancel!][fi] Starting'
      cancel_pending! if pending?
      cancel_building! if building?
      Integrity::Event.trigger('build:canceled', self.id)
    end

    def cancel_pending!
      log '[cancel_pending!][fi] Build pending, change_state'
      update(state: 'cancelled', completed_at: Time.now)
    end

    def cancel_building!
      log '[cancel!][cancel_building!][fi] Build pending, kill!'
      time = completed_at || Time.now
      update(state: 'killed', completed_at: time)
      Integrity::Event.trigger('build:cleanup', self.id)
    end

    def mercy_kill?
      building? && failed_on_docker? && passed_give_up_time?
    end

    def failed_on_docker?
      fleetctl_status == 'failed'
    end

    def passed_give_up_time?
      give_up_at = started_at + MERCY_KILL_TIMESPAN
      Time.now > give_up_at
    end
  end
end
