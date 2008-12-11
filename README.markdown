Integrity
=========

Integrity is your friendly automated Continuous Integration server.

It's fully usable from within its web interface (backed by [Sinatra][]),
allowing you to add a project, set preferences for it (where's the code
repository, is it completely private or public, etc), and run the build command
from there.

It has been designed with ruby projects in mind, but any project that can be
tested in an unix-y fashion (with a command line tool that returns 0 on success
and non-zero on failure) works with it.

Getting Started
===============

Install the `integrity` gem from GitHub:

    gem sources --add http://gems.github.com
    sudo gem install foca-integrity

In order to setup Integrity, run the following command:

    integrity install /path/to/my/app

Then browse to /path/to/my/app and edit the config files at your convenience.
The default configuration should be "good enough" in most cases, so you should
be pretty much ready to rock.

For deployment, we recommend [Thin][]. Provided with Integrity comes a thin.yml
file, so all you need to do after running `integrity install` should be

    thin -C /path/to/my/app/thin.yml -R /path/to/my/app/config.ru start

And you should be up and running.

If you want automatic commit processing, you currently need to be using
[GitHub][]. Click the edit link on your GitHub project, and add an integrity
link that looks like the following to the `Post-Receive URL` field:

    http://integrity.domain.tld/projectname/push

Receiving Notifications
=======================

If you want to be notified after each build, you need to install our notifiers.
For example, in order to receive an email after each build, install:

    sudo gem install foca-integrity-email

And then edit `/path/to/my/app/config.ru` and add:

    require "notifier/email"

After all the `require` lines.

Available notifiers
-------------------

* [Mail](http://github.com/foca/integrity-email)
* [Jabber](http://github.com/ph/integrity-jabber)
* [Campfire](http://github.com/defunkt/integrity-campfire)

Resources
========

We have a [Lighthouse account][lighthouse] where you can submit patches or
feature requests. Also, someone is usually around [#integrity][irc-channel] on
Freenode, so don't hesitate to stop by for ideas, help, patches or something.

Future plans
============

* [Twitter][]/[IRC][]/etc bots
* A sample generic post-receive-hook so you can run this from any git repo
* Better integration with GitHub

Development
===========

The code is stored in [GitHub][repo]. Feel free to fork, play with it, and send
a pull request afterwards. 

In order to run the test suite you'll need a few more gems: [rspec][], [rcov][]
and [hpricot][]. With that installed running `rake` will run the specs and
ensure the code coverage stays high.

Thanks
======

Thanks to the fellowing people for their feedbacks, ideas and patches :

* [James Adam][james]
* [Elliott Cable][ec]
* [Corey Donohoe][atmos]
* [Kyle Hargraves][kyle]
* [Pier-Hugues Pellerin][ph]
* [Simon Rozet][sr]
* [Scott Taylor][scott]

[james]: http://github.com/lazyatom
[ec]: http://github.com/elliotcabble
[atmos]: http://github.com/atmos
[kyle]: http://github.com/pd
[ph]: http://github.com/ph
[sr]: http://purl.org/net/sr/
[scott]: http://github.com/smtlaissezfaire

License
=======

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

[Sinatra]: http://sinatrarb.com
[git]: http://git.or.cz
[svn]: http://subversion.tigris.org
[Twitter]: http://twitter.com
[IRC]: http://wikipedia.org/wiki/IRC
[entp]: http://entp.com
[GitHub]: http://github.com
[Thin]: http://code.macournoyer.com/thin/

[rspec]: http://rspec.info
[rcov]: http://eigenclass.org/hiki.rb?rcov
[hpricot]: http://code.whytheluckystiff.net/hpricot

[repo]: http://github.com/foca/integrity
[lighthouse]: http://integrity.lighthouseapp.com/projects/14308-integrity
[irc-channel]: irc://irc.freenode.net/integrity

[foca]: http://nicolassanguinetti.info/
