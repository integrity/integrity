Integrity
=========

Integrity is your friendly automated Continuous Integration server. As soon as
you push your commits, it builds your code, run your tests and makes sure
everything works fine. It then reports the build status using various notifiers
back to you and your team so everyone is on the same page and any problem can
be fixed right away.

Read more about about Continuous Integration on [Martin Fowler's website][mfci]
and [Wikipedia][wpci].

[mfci]: http://martinfowler.com/articles/continuousIntegration.html
[wpci]: http://en.wikipedia.org/wiki/Continuous_Integration

Live demo
=========

See how integrity works for yourself on [our own install][demo], watching
Integrity itself and the various notifiers.

[demo]: http://ci.atonie.org

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

**NOTE:** Currently, only SQLite3 is supported. See [this ticket][t92] for
more details.

[t92]: http://integrity.lighthouseapp.com/projects/14308/tickets/92

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

3. Tweak `thin.yml` to your needs

4. Finally start the Thin server:

        $ thin -C thin.yml -R config.ru start

[Thin]: http://code.macournoyer.com/thin
[Passenger]: http://www.modrails.com/

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

**NOTE:** If you run Integrity with another deployment strategy please drop us
us a line at <info@integrityapp.com> and let us know what config worked
for you so we can include it here.

Configuration
=============

This step should be pretty pretty stepforward. You only need to touch one file,
`config.yml` where all options are explained.

Notifiers
=========

After a build is finished, you want to know the status **immediately.**
Integrity gives you a modular notification's system for this.

With Integrity, you can receive your notifications in a few different ways.
Currently, we maintain three notifiers:

- [Email](http://github.com/integrity/integrity-email)
  by [Nicolás Sanguinetti](http://nicolassanguinetti.info)
- [Campfire](http://github.com/integrity/integrity-campfire)
  by [Chris Wanstrath](http://ozmm.org)
- [IRC](http://github.com/integrity/integrity-irc)
  by [Simon Rozet](http://atonie.org)

There are other available notifiers as well, but we do not maintain them,
which mean they might not work.

- [Tumblr](http://github.com/matflores/integrity-tumblr)
  by [Matías A. Flores](http://matflores.com)
- [Jabber](http://github.com/hukl/integrity-jabber)
  by [Pier-Hugues Pellerin](http://heykimo.com)
- [Twitter](http://github.com/cwsaylor/integrity-twitter)
  by [Chris Saylor](http://justhack.com)
- [Basecamp](http://github.com/pyrat/integrity-basecamp)
  by [Alastair Brunton](http://www.simplyexcited.co.uk)
- [Yammer](http://github.com/jstewart/integrity-yammer/tree)
  by [Jason Stewart](http://github.com/jstewart)

## Writing a notifier

Checkout [this guide][howto] by [Matías A. Flores][maf] which explains it all.
Once you're done, be sure to add it to the README and [let us know][mail] where
we can pull from.

[howto]: http://matflores.com/2009/09/21/continuous-notification-with-integrity.html
[maf]: http://matflores.com
[mail]: mailto:info@integrityapp.com

Setting up your notifier
------------------------

Also a piece of cake. For example, for email notifications:

    $ gem install integrity-email

And then edit the `config.ru` file in your Integrity install directory:

    require "integrity"
    # You need to add the following line:
    require "integrity/notifier/email"

Finally, restart Integrity. That's it. Now you can browse to
<http://ci.example.org/my-project/edit> and configure your notifier.

**NOTE:** Due to recent changes in Integrity's internals, notifiers now needs
to be registered. However, all notifiers haven't been updated yet,
so you might have to do it yourself into the `config.ru` file:

    require "integrity"
    require "integrity/notifier/foo"

    Integrity::Notifier.register(Integrity::Notifier::Foo)

FAQ
===

But does it work with *&lt;insert tech here&gt;*?
-------------------------------------------------

**Absolutely!** As long as your build process can be run from an UNIX-y
environment and that it returns a *zero* status code for success and
*non-zero* for failure, then integrity works for you.

Read more about [exit status](http://en.wikipedia.org/wiki/Exit_status#Unix)
on Wikipedia.


How to handle database.yml and similar unversioned files?
---------------------------------------------------------

Integrity is dumb. it takes a repository URL and a command to run in a
working copy of the former. It then reports success or failure depending on
the exit status of the command.

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

How do I use git submodules with Integrity?
-------------------------------------------

Use this as your build command: `git submodule update --init && rake test`
It'll fetch and update the submodules everytime the project is build.

How to use Integrity with a local repository?
---------------------------------------------

Set the project URI's to point to the `.git` directory of the repository.
Example: `/home/sr/src/integrity/.git`

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

How do I use metric\_fu with Integrity?
---------------------------------------

Use [Nick Quaranto][qrush]'s [report_card][] which provide automatic
building and reporting to Campfire of metrics with metric\_fu through
Integrity. Checkout the [demo](http://metrics.thoughtbot.com/).

[qrush]: http://litanyagainstfear.com
[report_card]: http://github.com/thoughtbot/report_card

See also
========

* [Integrity Menu](http://integrity-menu.com) — a dashboard widget for Mac OS X
  that shows the current status of projects being managed by Integrity.
* [Integritray](http://github.com/jfrench/integritray) — Adds a
  CruiseControl.rb-style XML feed to Integrity use with CCMenu and other tray
  items.
* [report_card][report_card] — metrics for Integrity.
* [Continuous Integration Testing for Ruby on Rails with Integrity](http://elabs.se/blog/7-continuous-integration-testing-for-ruby-on-rails-with-integrity)
* [Local Continuous Integration with Integrity](http://morethanseven.net/2008/12/28/local-continuous-integration-integrity/)
* [Integrity CI on Passenger 2.2.2 with Ruby Enterprise Edition on Ubuntu 8.04](http://blog.smartlogicsolutions.com/2009/04/26/integrity-ci-on-passenger-222-with-ruby-enterprise-edition-on-ubuntu-804/)
* [deploy Integrity CI with deprec](http://deprec.failmode.com/2009/03/17/deploy-integrity-ci-with-deprec/)

Please feel free to add your project, article, etc to this list.

Support / Contributing
======================

You can get in touch via IRC at [#integrity on freenode][irc]. If no one
happens to be around, you can ask in our [mailing list][ml].

If you find a bug, or want to give us a feature request, log it into our
[bug tracker][bts].

To start hacking, grab the code from our git repository at
`git://github.com/integrity/integrity.git` and [setup Rip][rip] which we
use to manage development dependencies. Then:

* Create a new rip env: `rip env create integrity`
* Install the dependencies: `for f in $(ls *.rip); do rip install $f; done`
* Finally, hack and `rake` as usual ;-)

Once you're done, make sure to rebase your changes on top of the `master`
branch if necessary and let us know where we can pull from by opening a new
ticket on our [bug tracker][bts].

**NOTE:** You might be tempted to stick in `require "rubygems"` in case you get
`LoadError` exceptions. Please don't. See
[Why "require 'rubygems'" In Your Library/App/Tests Is Wrong][gem] by
[Ryan Tomayko](http://tomayko.com/about).

[irc]: irc://irc.freenode.net:6667/integrity
[ml]: http://groups.google.com/group/integrityapp
[bts]: http://integrity.lighthouseapp.com
[rip]: http://hellorip.com
[gem]: http://gist.github.com/54177
