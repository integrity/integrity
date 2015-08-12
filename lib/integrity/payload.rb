module Integrity
  class Payload

    attr_reader :builder, :payload

    def self.build(payload)
      new(payload).build
    end

    def initialize(payload)
      payload  = JSON.parse(payload) if payload.is_a?(String)
      @payload = Hashie::Mash.new(payload)
      Dir.mkdir('/tmp/payloads') unless File.directory?('/tmp/payloads')
      File.open("/tmp/payloads/#{Time.now.strftime('%Y%m%dT%H:%M:%S')}.json", 'w') {|f| f.write(JSON.dump(@payload)) }
      @builder = PayloadBuilder.new(self)
    end

    def build!
      builder.build
    end

    def project
      builder.project
    end

    def branch
      project.branches.first(name: branch_name)
    end

    def branch_name
      @payload[:ref].split('refs/heads/').last
    end

    def repo
      Integrity::Repository.new(uri, branch_name)
    end

    def commit
      commits.detect {|c| c.identifier == @payload.after }
    end
    alias_method :head, :commit

    def commits
      @commits ||= @payload[:commits].map do |commit|
        Hashie::Mash.new(
          identifier:   commit.id,
          author:       normalize_author(commit.author),
          message:      commit.message,
          committed_at: commit.timestamp,
          branch:       branch_name
        )
      end
    end

    def deleted?
      @payload[:deleted]
    end

    def merge_to_master?
      branch_name.eql? 'master'
    end

    def head_commit
      @payload[:head_commit]
    end

    def merged_story
      return unless merge_to_master?
      story_id_from_message head_commit[:message]
    end

    def private?
      @payload[:repository][:private] rescue true
    end

    def is_branch_master?
      branch_name.eql? 'master'
    end

    def uri
      return uri if uri = @payload[:uri]

      repository = @payload.repository

      if private?
        "git://github.com/#{repository.full_name}"
      else
        "https://github.com#{repository.full_name}.git"
      end
    end

    def is_new_pull_request?
      @payload[:pull_request].present? && @payload[:action].eql?('opened')
    end

    def pull_request
      if is_new_pull_request?
        pull_request = @payload[:pull_request]
        story_id = story_id_from_message pull_request[:head][:label]

        {
          pr_url: pull_request[:url],
          story_id: story_id,
        }
      end
    end

    private

    def normalize_author(author)
      return 'unknown' unless author
      author = Hashie::Mash.new(author) unless author.is_a?(Hashie::Mash)
      "#{author.name} <#{author.email}>"
    end

    def story_id_from_message(message)
      message.scan(/(?=\/(\d{6,})\/)/).flatten.last
    end
  end
end
