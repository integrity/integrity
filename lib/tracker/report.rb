require 'erb'
require 'i18n'

module Tracker
  class Report

    def test
      epics = Hash.new {|h,k| h[k] = Hash.new {|p,q| p[q]=[]}}
      epics[:off_da_ranch] = []

      Tracker::User.all.each do |user|
        on_ranch = false
        user.stories.each do |story|
          if ['started', 'finished', 'delivered'].include?(story.current_state)
            on_ranch = true
            if story.epics.present?
              story.epics.each do |epic|
                epics[epic.name.to_sym][user.name.to_sym] << story
              end
            else
              epics[:non_epic][user.name.to_sym] << story
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
