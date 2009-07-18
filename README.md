Integrity
=========

[Integrity][website] is your friendly automated Continuous Integration server.

* See our [website][] for documentation and a [live demo][demo]
* Report bugs and submit features request on our [Lighthouse account][lighthouse]
* Join us on [#integrity][irc-channel] for ideas, help, patches or something
* Get the code from [GitHub][repo]

Try it
------

Integrity provides a quick and easy way to try it out locally. The database is
saved into `$HOME/.integrity.db`.

    $ gem install integrity thin do_sqlite3
    $ integrity launch
    $ open http://0.0.0.0:4567/

Please see our [website][] for deployement instructions.

Contributing
------------

The canonical repository for Integrity is <git://github.com/integrity/integrity.git>.

The development version (the `master` branch) of Integrity often requires edgy
code. To help handle this situation, a [Rip][] file is included. To start hacking:

1. [Setup Rip](http://hellorip.com/install.html) if necessary
2. Install the runtimes dependencies via RubyGems:
   `rake install && gem install do_sqlite3 randexp`
3. Create a new Rip environement: `rip env create integrity-hacking`
4. Install the development and edgy runtime dependencies: `rip install hack.rip`
5. Run the test suite: `RUBYOPT=rubygems rake`

In case following these steps doesn't work, please [let us known][lighthouse];
that's a bug.

__NOTE:__ Ideally, RubyGems wouldn't be necessary and `rip install hack.rip`
would just work. Unfortunately, that is not currently possible due to some
limitations of Rip.

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
[Rip]: http://hellorip.com
