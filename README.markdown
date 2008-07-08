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

There's no gem yet, so for now you have to clone the source:

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

License
=======

(The MIT License)

Copyright (c) 2008 Nicolás Sanguinetti, [CitrusByte][]

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
[GitHub]: http://github.com
[Twitter]: http://twitter.com
[Campfire]: http://campfirenow.com
[IRC]: http://wikipedia.org/wiki/IRC
[CitrusByte]: http://citrusbyte.com