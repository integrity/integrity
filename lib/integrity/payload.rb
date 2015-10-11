module Integrity
  class Payload
    include ClassLogger

    attr_reader :payload

    def initialize(payload)
      payload  = JSON.parse(payload) if payload.is_a?(String)
      @payload = Hashie::Mash.new(payload)
      dump_payload
    end

    def finish_story
      pull_request = payload.pull_request
      logger.info "finishing story_id=#{pull_request.story_id}"
      if story = Tracker::Story.first(id: pull_request.story_id)
        story.finish(pull_request.pr_url)
      end
    end

    def deliver_story
      logger.info "delivering story_id=#{payload.merged_story_id}"
      if story = Tracker::Story.first(id: payload.merged_story_id)
        story.deliver
      end
    end

    def destroy_branch
      if branch = payload.branch
        logger.info "destroying branch id=#{branch.id} name=#{branch.name}"
        branch.destroy
      end
    end

    def dump_payload
      Dir.mkdir('/tmp/payloads') unless File.directory?('/tmp/payloads')
      File.open("/tmp/payloads/payload_#{Time.now.strftime('%Y%m%dT%H:%M:%S')}.json", 'w') do |f|
        f.write(JSON.dump(@payload))
      end
    end

    # Each line of the ignore file should contain a substring to match against a branch.
    # If the line starts with a bang, it means 'dont ignore', otherwise if the branch
    # contains the line, it will be ignored. A blank line ignores everything.
    def ignore_branch?
      fname = '/tmp/honesty-ignore.txt'
      return false unless File.exists?(fname)
      return !!File.readlines(fname).map{|l| [!l['!'], l.sub('!', '').chomp] } # [negated, line]
        .select{ |line| branch_name.include?(line[1]) }                        # ignore non-matching lines
        .map(&:first)                                                          # only care about whether the match is positive or negative
        .last                                                                  # only the last positive/negative matters
    end

    def run_build
      @build ||= project.build(commit)
    end

    def project
      @project ||= ProjectFinder.find(repo)
    end

    def branch
      project.branches.first(name: branch_name)
    end

    def branch_name
      ref.split('refs/heads/').last
    end

    def ref
      @payload.ref || ''
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

    def merged_story_id
      return unless merge_to_master?
      story_id_from_message head_commit[:message]
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
        "https://github.com/#{repository.full_name}.git"
      end
    end

    def is_new_pull_request?
      @payload[:pull_request].present? && @payload[:action].eql?('opened')
    end

    def pull_request
      if is_new_pull_request?
        pull_request = @payload[:pull_request]
        story_id = story_id_from_message pull_request[:head][:label]

        Hashie::Mash.new(
          pr_url: pull_request[:html_url],
          story_id: story_id,
        )
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
