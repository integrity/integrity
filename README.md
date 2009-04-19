Integrity
=========

[Integrity][website] is your friendly automated Continuous Integration server.

* See our [website][] for documentation and a [live demo][demo]
* Report bugs and submit features request on our [Lighthouse account][lighthouse]
* Join us on [#integrity][irc-channel] for ideas, help, patches or something
* Get the code on [GitHub][repo]

Try it!
-------

    $ git clone git://github.com/integrity/integrity.git
    $ rake launch
    $ open http://0.0.0.0:4567/

Run the test suite
------------------

1. Ensure you have `gems.github.com` in your gem sources:
   `gem sources -a http://gems.github.com`
2. Install the runtime and development dependencies:
   `gem build integrity.gemspec && gem install *.gem --development`.
3. Run the test suite: `rake test`

Why We Do Not Require 'rubygems'
-------------------------------

We do not require 'rubygems' directly in Integrity, instead leaving that choice up to the user.  For more information on this line of thinking, please see the article [Why "require 'rubygems'" In Your Library/App/Tests Is Wrong][rtomayko-rubygems] by Ryan Tomayko.

Thanks
------

Thanks to the following people for their feedbacks, ideas and patches :

* [James Adam][james]
* [Elliott Cable][ec]
* [Corey Donohoe][atmos]
* [Kyle Hargraves][kyle]
* [Pier-Hugues Pellerin][ph]
* [Simon Rozet][sr]
* [Scott Taylor][scott]

License
-------

(The MIT License)

Copyright (c) 2008 [Nicolás Sanguinetti][foca], [entp][]

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[website]: http://integrityapp.com
[demo]: http://builder.integrityapp.com
[repo]: http://github.com/integrity/integrity
[lighthouse]: http://integrity.lighthouseapp.com/projects/14308-integrity
[irc-channel]: irc://irc.freenode.net/integrity
[rtomayko-rubygems]: http://gist.github.com/54177


[foca]: http://nicolassanguinetti.info/
[entp]: http://entp.com

[james]: http://github.com/lazyatom
[ec]: http://github.com/elliotcabble
[atmos]: http://github.com/atmos
[kyle]: http://github.com/pd
[ph]: http://github.com/ph
[sr]: http://purl.org/net/sr/
[scott]: http://github.com/smtlaissezfaire

