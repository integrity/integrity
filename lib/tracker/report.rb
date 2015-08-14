require 'erb'
require 'i18n'

module Tracker
  class Report

    def self.nes_report
      stories_in_time_frame = Tracker::StoryMerge.all(:created_at => (2.days.ago..Time.now))

      stories_count = stories_in_time_frame.count
      nes_count = stories_in_time_frame.count(nes: true)
      es_count = stories_in_time_frame.count(nes: false)
      nes_percent = ((nes_count.to_f / stories_count) * 100).to_i
      es_percent = 100 - nes_percent

      {
        stories_count: stories_count,
        nes_count: nes_count,
        es_count: es_count,
        nes_percent: nes_percent,
        es_percent: es_percent,
      }
    end

    def self.developer_report
      epics = Hash.new {|h,k| h[k] = Hash.new {|p,q| p[q]= Hash.new {|m,n| m[n]=[]}}}
      epics[:off_da_ranch] = []

      stories_in_flight = Tracker::Story.all(:current_state => ['started', 'finished', 'delivered'])

      epics[:story_counts] = {
        started: stories_in_flight.all(:current_state => 'started').count,
        finished: stories_in_flight.all(:current_state => 'finished').count,
        delivered: stories_in_flight.all(:current_state => 'delivered').count,
      }

      Tracker::User.all(developer: true).each do |user|
        on_ranch = false
        user.owned_stories.each do |story|
          if ['started', 'finished', 'delivered'].include?(story.current_state)
            on_ranch = true
            if story.epics.present?
              story.epics.each do |epic|
                epics[epic.name.to_sym][:requestors] = [] if epics[epic.name.to_sym][:requestors].blank?
                epics[epic.name.to_sym][:requestors] << story.requestor.name unless story.requestor.developer
                epics[epic.name.to_sym][:requestors].uniq!
                epics[epic.name.to_sym][:developers][user.name.to_sym] << story
              end
            else
              epics[:'Non Epic'][:developers][user.name.to_sym] << story
            end
          else

          end
        end

        epics[:off_da_ranch] << user.name unless on_ranch
      end

      epics
    end
  end
end
