Integrity
=========

[Integrity][website] is your friendly automated Continuous Integration server.

* See our [website][] for documentation and a [live demo][demo]
* Report bugs and submit features request on our [Lighthouse account][lighthouse]
* Join us on [#integrity][irc-channel] for ideas, help, patches or something
* Get the code from [GitHub][repo]

Contributing
------------

The canonical repository for Integrity is `git://github.com/integrity/integrity.git`.

The development version (the `master` branch) of Integrity often requires edgy
code. To help handle this situation, a [Rip][] file is included. To start hacking:

1. [Setup Rip](http://hellorip.com/install.html) if necessary
2. `rip install deps.rip && rip install hack.rip`
3. Hack and `rake` as usual

Finally, push your changes and let us known where we can pull from.

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
