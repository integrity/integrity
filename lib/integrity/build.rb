require 'integrity/build/status'

module Integrity
  class Build
    include DataMapper::Resource
    extend DataMapper::Resource::ClassMethods
    include Status

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
    property :service_template,      String, default: 'spec'
    property :public_port,           String

    timestamps :at

    belongs_to :project
    belongs_to :branch
    has 1,     :commit
    has 1,     :diligence_branch

    delegate :name, :permalink, :repo, :command, to: :project

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

    def run
      log 'run'
      Integrity::Event.trigger('build:queue', self.id)
    end

    def run!
      log 'run!'
      return false if invalid_sha?
      Integrity::Event.trigger('build:start', self.id)
    end

    def cleanup!
      log '[cleanup!][fi]'
      Integrity::Event.trigger('build:cleanup', self.id)
    end

    def complete!(result)
      success = result.respond_to?(:success) ? result.success : result
      log "[complete!][fi] with success #{success} and result #{result}. Setting_as_complete and cleanup next!"
      set_as_complete(success) and cleanup!
    end

    def kill!(params = {})
      log "[kill!][fi] #{params}"
      params = {cleanup: true}.merge(params)
      cleanup! if params[:cleanup]
      time = completed_at || Time.now
      update(state: 'killed', completed_at: time)
    end

    def cancel_previous_builds!
      log '[cancel_previous_builds!]'
      previous_builds.map(&:cancel!)
    end

    def previous_builds(on = :branch)
      parent = self.send(on)
      (parent.builds & (self.class.running | self.class.pending)) & self.class.all(:id.not => id, order: :created_at.desc)
    end

    def cancel!
      log '[cancel!][fi]'
      if pending?
        log '[cancel!][fi] Build pending, change_state'
        update(state: 'cancelled', completed_at: Time.now)
      elsif building?
        log '[cancel!][fi] Build pending, kill!'
        kill!
      end
      log '[cancel!][fi] Triggering diligence_branch:deactivate and build:canceled'
      Integrity::Event.trigger('diligence_branch:deactivate', self.id)
      Integrity::Event.trigger('build:canceled')
    end

    def spec?
      service_template == 'spec'
    end

    def server?
      service_template == 'server'
    end

    def started!
      log 'started!'
      update(started_at: Time.now)
      update_ports if server?
    end

    def fail!(message=nil)
      log "[fail!][fi] with message #{message}. Setting as complete."
      set_as_complete(false)
    end

    def notify
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

    #'jarvis', '98j98j89j', 389, 'spec'
    def service_vars
      [permalink, sha1_short, id]
    end

    def service_name
      service_vars.join('_')
    end

    def service_options
      {
        id: id,
        project: permalink,
        branch: branch_name,
        sha: sha,
        template_name: service_template
      }
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

    def update_ports
      update(public_port: get_public_port)
    end

    def public_link
      @machine_ip && public_port ? "http://#{machine_ip}:#{public_port}" : false
    end

    def log(msg)
      puts msg
      Integrity.logger.info "[Integrity::Build]:[Build:#{id}] event:#{msg}, params:#{self.inspect}"
    end

    def consider_mercy_kill
      if mercy_kill?
        log("[consider_mercy_kill][fi] Mercy Killing Unit")
        kill
      end
    end

    private

    def get_public_port
      ports = get_ports(app_service_name)
      port = ports.select{|p| p[:internal_port] == '3000'}.first
      log "Setting ports as #{port}"
      port[:external_port] if port
    end

    def get_ports(service)
      docker_info = `ssh core@#{machine_ip} 'docker ps | grep #{service}'`
      ports = docker_info.split(" ").select{|e| e.include?("->")}
      ports.map!{|e| e.split("->")}.map!{|n, m| {external_port:n, internal_port:m}}
      ports.each{|p| p[:external_port] = /0.0.0.0:(\d*)/.match(p[:external_port])[1]}
      ports.each{|p| p[:internal_port] = /(\d*)\//.match(p[:internal_port])[1]}
      log "get_ports #{ports}"
      ports
    end

    def mercy_kill?
      building? && failed_on_docker? && passed_give_up_time?
    end

    def failed_on_docker?
      fleetctl_status == 'failed'
    end

    def passed_give_up_time?
      give_up_at = started_at + MERCY_KILL_TIMESPAN
      time.now > give_up_at
    end
  end
end
