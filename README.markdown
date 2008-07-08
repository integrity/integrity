Integrity
=========

Integrity is your friendly automated Continuous Integration server.

It's fully usable from within its web interface (backed by [Sinatra][]), 
allowing you to add a project, set preferences for it (where's the code 
repository, is it completely private or public, etc), and run the test suite 
from there.

It has been designed with ruby projects in mind, but any project that can be
tested in an unix-y fashion (with a command line tool that returns 0 on success
and non-zero on failure) works with it.

Integrity works out of the box with [git][] projects, and support for other 
VCSs like [Subversion][svn] is planned.

Requirements
============

To be defined.

Getting Started
===============

    git clone git://github.com/foca/integrity.git
    cd integrity
    git submodule init
    git submodule update
    bin/integrity

Now you can go to http://localhost:4567, add your first project, and enjoy
safer coding, with integrity.

Future plans
============

* [GitHub][] post-receive integration
* [Twitter][]/[Campfire][]/[IRC][] bots
* Other SCMs like Subversion

[Sinatra]: http://sinatrarb.com
[git]: http://git.or.cz
[svn]: http://subversion.tigris.org
[GitHub]: http://github.com
[Twitter]: http://twitter.com
[Campfire]: http://campfirenow.com
[IRC]: http://wikipedia.org/wiki/IRC
