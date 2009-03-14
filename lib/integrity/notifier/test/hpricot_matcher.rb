require "hpricot"

module Integrity
  class Notifier
    module Test
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
    end
  end
end
