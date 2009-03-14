require "haml"

require File.dirname(__FILE__) + "/test/hpricot_matcher"

module Integrity
  class Notifier
    module Test
      def setup_database
        DataMapper.setup(:default, "sqlite3::memory:")
        DataMapper.auto_migrate!

        require File.dirname(__FILE__) + "/../../../test/helpers/fixtures"
      end

      def build
        @build = Integrity::Build.gen(:successful)
      end

      def commit
        @commit = build.commit
      end

      def notifier_class
        Integrity::Notifier.const_get(notifier)
      end

      def notification
        notifier_class.new(commit).body
      end

      def assert_form_have_option(option, value=nil)
        selector = "input##{notifier.downcase}_notifier_#{option}"
        selector << "[@name='notifiers[#{notifier}][#{option}]']"
        selector << "[@value='#{value}']" if value

        assert_form_have_tag(selector, option => value)
      end

      def assert_form_have_options(*options)
        options.each { |option| assert_form_have_option(option) }
      end

      def assert_form_have_tag(selector, options={})
        content = options.delete(:content)
        assert_have_tag(form(options), selector, content)
      end

      def assert_have_tag(html, selector, content=nil)
        matcher = HpricotMatcher.new(html)
        assert_equal content, matcher.tag(selector) if content
        assert matcher.tag(selector)
      end

      def form(config={})
        Haml::Engine.new(notifier_class.to_haml).
          render(OpenStruct.new(:config => config))
      end
    end
  end
end
