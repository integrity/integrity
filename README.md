Integrity
=========

[Integrity][website] is your friendly automated Continuous Integration server.

* See our [website][] for documentation and a [live demo][demo]
* Report bugs and submit features request on our [Lighthouse account][lighthouse]
* Join us on [#integrity][irc-channel] for ideas, help, patches or something
* Get the code on [GitHub][repo]

Try it!
-------

    $ gem install integrity
    $ integrity launch
    $ open http://0.0.0.0:4567/

Run the test suite
------------------

1. Ensure you have `gems.github.com` in your gem sources:
   `gem sources -a http://gems.github.com`
2. Install the runtime and development dependencies:
   `gem build integrity.gemspec && gem install *.gem --development`.
3. Run the test suite: `rake test`

Why we don't `require "rubygems"`
---------------------------------

We decided to leave that choice up to the user. For more information, please
see [Why "require 'rubygems'" In Your Library/App/Tests Is Wrong][rubygems]
by [Ryan Tomayko][rtomayko].

[website]: http://integrityapp.com
[demo]: http://builder.integrityapp.com
[repo]: http://github.com/integrity/integrity
[lighthouse]: http://integrity.lighthouseapp.com/projects/14308-integrity
[irc-channel]: irc://irc.freenode.net/integrity
[rubygems]: http://gist.github.com/54177
[rtomayko]: http://tomayko.com/about
