require "integrity/notifier/test/hpricot_matcher"
require "integrity/notifier/test/fixtures"

module Integrity
  class Notifier
    module Test
      def setup_database
        DataMapper.setup(:default, "sqlite3::memory:")
        DataMapper.auto_migrate!
      end

      def build(state=:successful)
        Integrity::Build.gen(state)
      end

      def notifier_class
        Integrity::Notifier.const_get(notifier)
      end

      def provides_option?(option, value=nil)
        selector = "input##{notifier.downcase}_notifier_#{option}"
        selector << "[@name='notifiers[#{notifier}][#{option}]']"
        selector << "[@value='#{value}']" if value

        form_have_tag?(selector, option => value)
      end

      def provides_options(*options)
        options.each { |option| assert_form_have_option(option) }
      end

      private
        def form(config={})
          Haml::Engine.new(notifier_class.to_haml).
            render(OpenStruct.new(:config => config))
        end

        def form_have_tag?(selector, options={})
          content = options.delete(:content)
          have_tag?(form(options), selector, content)
        end

        def have_tag?(html, selector, content=nil)
          matcher = HpricotMatcher.new(html)
          assert_equal content, matcher.tag(selector) if content
          matcher.tag(selector)
        end
    end
  end
end
