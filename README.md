Integrity
=========

Integrity is the angel watching over your shoulder while you code. As soon
as you push your commits, it builds, runs your tests, and makes sure
everything works fine.

It then reports the build status using [various notifiers][notifiers]
back to your team so everyone's on the same page, and if there's a problem,
you can get it fixed right away.

Read more about [Continuous Integration][ci] on Wikipedia.

Live demo
=========

See how integrity works for yourself on [our own install][demo], watching
Integrity itself and the [various notifiers][notifiers].

Installation and deployment
===========================

__It's ridiculously easy.__ All you need is to have `ruby` and `rubygems`
installed on your server, and then run the built-in installer and follow the
instructions.

    $ gem install integrity
    $ integrity install /home/www-data/integrity

This will create a couple files on your server, mainly `config.yml`
and `config.ru`. Then, edit `config.yml` to your liking and run
`integrity migrate_db config.yml` to create the database.

**NOTE:** Currently, only SQLite3 is supported. Please see ticket
[#92](http://integrity.lighthouseapp.com/projects/14308/tickets/92) for
details.

The installer provides special configuration files for [Thin][]
and [Passenger][].

Passenger
---------

    $ integrity install ~www-data/integrity --passenger
    $ cd ~www-data/integrity

Then, tell Passenger to start your app: `$ touch tmp/restart.txt`

Thin
----

1. Install [Thin][] if necessary:

        $ gem install thin

2. Run the installer:

        $ integrity install --thin ~www-data/integrity
        $ cd ~www-data/integrity`

3. Tweak `thin.yml` to your need if necessary.

4. Then, to start the Thin server, just do this:

        $ thin -C thin.yml -R config.ru start

Configure a web proxy
---------------------

### nginx

    http {
      upstream builder-integrityapp-com {
        server 127.0.0.1:8910;
        server 127.0.0.1:8911;
      }

      server {
        server_name builder.integrityapp.com;
        location / {
          proxy_pass http://builder-integrityapp-com;
        }
      }
    }

### Apache acting as reverse proxy to a cluster of thin instances

    <VirtualHost *>
      <Proxy>
        Order deny,allow
        Allow from all
      </Proxy>

      RedirectMatch ^/integrity$ /integrity/
      ProxyRequests Off
      ProxyPass /integrity/ http://localhost:8910/
      ProxyHTMLURLMap http://localhost:8910 /integrity

      <Location /integrity>
        ProxyPassReverse /
        SetOutputFilter proxy-html
        ProxyHTMLURLMap / /integrity/
        ProxyHTMLURLMap /integrity/ /integrity
      </Location>
    </VirtualHost>

If you run Integrity behind Passenger, or other deployment strategy, drop
us a line at <info@integrityapp.com> and let us know what config worked
for you so we can include it here :-)

Configuration
=============

This step should be pretty pretty stepforward. You only need to touch one file:

    /path/to/integrity/config.yml

All options are explained in the file. In case you want to see them anyway,
you can see the [source file on GitHub][configsrc].

Notifiers
=========

After a build is finished, you want to know the status __immediately.__
Integrity gives you a modular notification's system for this.

With Integrity, you can receive your notifications in a few different ways.
Currently, we maintain three notifiers:

- [Email](http://github.com/integrity/integrity-email),
  by [Nicolás Sanguinetti][foca]
- [Campfire](http://github.com/integrity/integrity-campfire),
  by [Chris Wanstrath](http://ozmm.org)
- [IRC](http://github.com/integrity/integrity-irc), by [Simon Rozet][sr]

There are other available notifiers as well, but we do not maintain them,
which mean they might not work.

- [Tumblr](http://github.com/matflores/integrity-tumblr),
  by [Matías A. Flores](http://matflores.com)
- [Jabber](http://github.com/hukl/integrity-jabber),
  by [Pier-Hugues Pellerin](http://heykimo.com)
- [Twitter](http://github.com/cwsaylor/integrity-twitter),
  by [Chris Saylor](http://justhack.com)
- [Basecamp](http://github.com/pyrat/integrity-basecamp), by
  [Alastair Brunton](http://www.simplyexcited.co.uk)
- [Yammer](http://github.com/jstewart/integrity-yammer/tree), by
  [Jason Stewart](http://github.com/jstewart)

If you'd like to write a notifier, checkout [this guide][howto] by
[Matías A. Flores](http://matflores.com) which explains it all. Be sure to
[let us know](mailto:info@integrityapp.com) when you're done and we'll add you
here :)

[howto]: http://matflores.com/2009/09/21/continuous-notification-with-integrity.html

Setting up your notifier
------------------------

Also a piece of cake. For example, for email notifications:

    $ gem install integrity-email

And then edit the `config.ru` file in your Integrity install directory:

    require "rubygems"
    require "integrity"

    # You need to add the following line:
    require "integrity/notifier/email"

Finally, restart Integrity. That's it. Now you can browse to
<http://ci.example.org/my-project/edit> and configure your notifier.

**NOTE:** Due to recent changes in Integrity's internals, notifiers now needs
to be registered. However, all notifiers haven't been updated yet,
so you might have to do it yourself into the `config.ru` file:

    require "rubygems"
    require "integrity"
    require "integrity/notifier/email"

    Integrity::Notifier.register(Integrity::Notifier::Email)

FAQ
===

But does it work with *&lt;insert tech here&gt;*?
-------------------------------------------------

Short answer: __Yeah!__

Slightly longer answer: as long as your build process can be run from an unix-y
environment __and__ it returns a *zero* status code for
success and _non-zero_ for failure, then integrity works for you.

How do I use metric\_fu with Integrity?
---------------------------------------

Use [Nick Quaranto][qrush]'s [report\_card][] which provide automatic
building and reporting to Campfire of metrics with metric\_fu through
Integrity.

Checkout the [demo](http://metrics.thoughtbot.com/) if you're not convinced.

[qrush]: http://litanyagainstfear.com
[report_card]: http://github.com/thoughtbot/report_card

How to handle database.yml and similar unversioned files?
---------------------------------------------------------

Integrity is dumb. it takes a repository URL and a command to run in a
working copy of the former. It then reports success or failure depending on
the [exit status][exit] of the command.

While this is very simplistic, it allows for great flexibility: you can use
whatever you want as the build command.

So, to handle `database.yml`, you can either use a build command like this:

    cp config/database.sample.yml config/database.yml && rake test

Or use a Rake task. Example:

    namespace :test do
      task :write_test_db_config do
        file = File.join(Rails.root, "config", "database.yml")
        File.open(file), "w") { |config|
          config << "...."
        }
      end
    end

My project won't build!
-----------------------

The most common causes are:

* You've installed `foca-integrity` (directly or via an outdated notifier). If
  so, uninstall it or make sure the `integrity` gem is loaded.

* The build directory isn't writeable by the user that runs Integrity.

* `git` isn't in said user's `PATH`.

* If you're trying to build a private repository (`git@example.org:repo.git`
  for example), be sure to setup [ssh-agent] or [keychain][].

[keychain]: http://www.gentoo.org/proj/en/keychain/
[ssh-agent]: http://en.wikipedia.org/wiki/Ssh-agent

How do I use git submodules with Integrity?
-------------------------------------------

Use this as your build command: `git submodule update --init && rake test`
It'll fetch and update the submodules everytime the project is build.

How to use Integrity with a local repository?
---------------------------------------------

Set the project URI's to point to the `.git` directory of the
repository: `/home/sr/code/integrity/.git`

[git-sub]: http://www.kernel.org/pub/software/scm/git/docs/git-submodule.html

Related projects and external resources
=======================================

* [Integrity Menu](http://integrity-menu.com) -- a dashboard widget for Mac OS X
  that shows the current status of projects being managed by Integrity.
* [Integritray](http://github.com/jfrench/integritray) -- Adds a
  CruiseControl.rb-style XML feed to Integrity (integrityapp.com) for use with
  CCMenu and other tray items.
* [report\_card](http://giantrobots.thoughtbot.com/2009/7/24/enforcer-and-report_card) --
  metrics for Integrity.

* [Continuous Integration Testing for Ruby on Rails with Integrity](http://elabs.se/blog/7-continuous-integration-testing-for-ruby-on-rails-with-integrity)
* [Local Continuous Integration with Integrity](http://morethanseven.net/2008/12/28/local-continuous-integration-integrity/)
* [Integrity CI on Passenger 2.2.2 with Ruby Enterprise Edition on Ubuntu 8.04](http://blog.smartlogicsolutions.com/2009/04/26/integrity-ci-on-passenger-222-with-ruby-enterprise-edition-on-ubuntu-804/)
* [deploy Integrity CI with deprec](http://deprec.failmode.com/2009/03/17/deploy-integrity-ci-with-deprec/)

Please feel free to [fork](http://github.com/integrity/integrity-website) this
website and add your project, article, etc to this list.

Support / Development
=====================

[#integrity]: irc://irc.freenode.net:6667/integrity
You can get in touch via IRC at [#integrity][] on freenode. If no one happens
to be around the IRC channel, you can ask in our [Google Group][ml].

If you find a bug, or want to give us a feature request, drop by our
[Lighthouse][] tracker.

If you want to check out the code, you can do so at our [GitHub project][src]

[configure]: /#configure
[notifiers]: /#notifiers
[demo]: http://builder.integrityapp.com
[src]: http://github.com/integrity/integrity
[lighthouse]: http://integrity.lighthouseapp.com
[ml]: http://groups.google.com/group/integrityapp
[configsrc]: http://github.com/integrity/integrity/blob/3d1ba4b8cde7241dacd641eb40e9f26c49fbea35/config/config.sample.yml
[Thin]: http://code.macournoyer.com/thin
[Passenger]: http://www.modrails.com/
[nginx]: http://nginx.net
[ci]: http://en.wikipedia.org/wiki/Continuous_Integration
[exit]: http://en.wikipedia.org/wiki/Exit_status#Unix
[foca]: http://nicolassanguinetti.info
[sr]: http://atonie.org

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
