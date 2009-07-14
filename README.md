Integrity
=========

[Integrity][website] is your friendly automated Continuous Integration server.

* See our [website][] for documentation and a [live demo][demo]
* Report bugs and submit features request on our [Lighthouse account][lighthouse]
* Join us on [#integrity][irc-channel] for ideas, help, patches or something
* Get the code from [GitHub][repo]

Try it
------

    $ gem install integrity
    $ integrity launch
    $ open http://0.0.0.0:4567/

__NOTE:__ This is nothing but a quick and easy way to try out Integrity or
run it locally. For deployement, see our [website][].

Hack
----

1. Ensure you have `gems.github.com` in your gem sources:
   `gem sources -a http://gems.github.com`
2. Install [mg](http://github.com/sr/mg): `gem install sr-mg`
3. Install the edge gem with development dependencies:
   `rake install:edge HACK=1`
4. Fetch submodules: `git submodule update --init`
5. Run the test suite: `rake`

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
