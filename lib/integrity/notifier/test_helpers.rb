require "hpricot"
require "haml"
require File.dirname(__FILE__) + "/../../integrity"

module Integrity
  class Notifier
    module TestHelpers
      module HpricotAssertions
        # Thanks Harry! http://gist.github.com/39960

        class HpricotMatcher
          def initialize(html)
            @doc = Hpricot(html)
          end

          # elements('h1') returns a Hpricot::Elements object with all h1-tags.
          def elements(selector)
            @doc.search(selector)
          end

          # element('h1') returns Hpricot::Elem with first h1-tag, or nil if
          # none exist.
          def element(selector)
            @doc.at(selector)
          end

          # tags('h1') returns the inner HTML of all matched elements mathed.
          def tags(selector)
            e = elements(selector)
            e.map {|x| x.inner_html}
          end

          # tag('h1') returns the inner HTML of the first mached element, or
          # nil if none matched.
          def tag(selector)
            e = element(selector)
            e && e.inner_html
          end
        end

        def assert_have_tag(html, selector, content=nil)
          matcher = HpricotMatcher.new(html)
          assert_equal content, matcher.tag(selector) if content
          assert matcher.tag(selector)
        end
      end

      module NotifierFormHelpers
        include HpricotAssertions

        def form(config={})
          Haml::Engine.new(notifier_class.to_haml).
            render(OpenStruct.new(:config => config))
        end

        def assert_form_have_tag(selector, options={})
          content = options.delete(:content)
          assert_have_tag(form(options), selector, content)
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
      end

      include NotifierFormHelpers

      def build
        @build ||= Integrity::Build.gen(:successful)
      end

      def commit
        @commit ||= build.commit
      end

      def notifier_class
        Integrity::Notifier.const_get(notifier)
      end

      def notification
        notifier_class.new(commit).body
      end

      def setup_database
        DataMapper.setup(:default, "sqlite3::memory:")
        DataMapper.auto_migrate!

        require File.dirname(__FILE__) + "/../../../test/helpers/fixtures"
      end
    end
  end
end
