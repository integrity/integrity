module Tracker
  class Helper

    STOP_WORDS = %w/due so as grnds a i am the and to from my for/

    class BranchName
      attr_accessor :story_name, :good_words

      def initialize name
        @story_name = name
        @good_words = process_story_name @story_name
      end

      def process_story_name name
        words = name.downcase.gsub(/[^a-z0-9\s]/i, '')
        words.reject{|w| STOP_WORDS.include? w}
      end

      def first_two_words
        good_words[0..1]
      end

      def last_two_words
        good_words[-2..-1]
      end

      def middle_word
        [good_words[good_words.length/2]]
      end

      def words_to_use
        if good_words.length > 5
          (first_two_words + middle_word + last_two_words)
        else
          good_words
        end
      end

      def name
        words_to_use.join('-').downcase
      end
    end

    def self.generate_branch_name_from_story(story)
      branch = BranchName.new story.name
      epic_path = story.epics.first ? '' : "#{story.epics.first.id}/"
      "#{story.type}/#{epic_path}#{story.id}/#{branch.name}"
    end
  end
end
