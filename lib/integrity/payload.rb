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
      cc = commits.detect {|c| c.identifier == @payload.after }
      if !cc
        Integrity.logger.debug "[fml] commits.detect is nil c.identifiers=#{commits.map(&:identifier).join(',')} @payload.after=#{@payload.after}"
      end
      cc
    end
    alias_method :head, :commit

    def commits
      Integrity.logger.debug "[fml] @payload[:commits] is nil" if @payload[:commits].nil?
      Integrity.logger.debug "[fml] @payload[:commits] is empty" if @payload[:commits].empty?

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

    def private?
      @payload[:repository][:private] rescue true
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

    private

    def normalize_author(author)
      return 'unknown' unless author
      author = Hashie::Mash.new(author) unless author.is_a?(Hashie::Mash)
      "#{author.name} <#{author.email}>"
    end
  end
end
