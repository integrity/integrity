CREATE TABLE "integrity_builds" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "output" TEXT NOT NULL DEFAULT '', "successful" BOOLEAN NOT NULL DEFAULT 'f', "commit_identifier" VARCHAR(50) NOT NULL, "commit_metadata" TEXT NOT NULL, "created_at" DATETIME, "updated_at" DATETIME, "project_id" INTEGER);
INSERT INTO "integrity_builds" VALUES(1,'rake aborted!
Don''t know how to build task ''default''
/home/simon/.gems/gems/rake-0.8.3/lib/rake.rb:1706:in `[]''
(See full trace by running task with --trace)
(in /home/simon/bar/builds/sr-shout-bot-master)
','f','348e9e27fa72645518fc539b77f1c37fcc20ab11','---
:message: had to allow for registration time
:date: 2009-01-04 06:19:30 +0800
:author: syd <syd@teh.magicha.us>
','2009-02-17T19:48:31+01:00','2009-02-17T19:48:31+01:00',1);
INSERT INTO "integrity_builds" VALUES(2,'....*...........

Pending:
ShoutBot When using Shouter.shout passes given block to join (TODO)
  Called from shout-bot.rb:113

Finished in 10.222458 seconds

16 examples, 0 failures, 1 pending
','t','348e9e27fa72645518fc539b77f1c37fcc20ab11','---
:message: had to allow for registration time
:date: 2009-01-04 06:19:30 +0800
:author: syd <syd@teh.magicha.us>
','2009-02-17T19:49:05+01:00','2009-02-17T19:49:05+01:00',1);
INSERT INTO "integrity_builds" VALUES(3,'(in /home/simon/bar/builds/sinatra-sinatra-master)
Loaded suite /home/simon/.gems/gems/rake-0.8.3/lib/rake/rake_test_loader
Started
.......................................................................................................................................................................................................................................
Finished in 1.097704 seconds.

231 tests, 437 assertions, 0 failures, 0 errors
','t','a2f5803ec642c43ece86ad96676c45f44fe3746e','---
:message: Allow dot in named param capture [#153]
:date: 2009-02-17 09:32:58 -0800
:author: Ryan Tomayko <rtomayko@gmail.com>
','2009-02-17T19:50:11+01:00','2009-02-17T19:50:11+01:00',2);
DELETE FROM sqlite_sequence;
INSERT INTO "sqlite_sequence" VALUES('integrity_projects',2);
INSERT INTO "sqlite_sequence" VALUES('integrity_builds',3);
CREATE TABLE "integrity_notifiers" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" VARCHAR(50) NOT NULL, "config" TEXT NOT NULL, "project_id" INTEGER);
CREATE TABLE "integrity_projects" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" VARCHAR(50) NOT NULL, "permalink" VARCHAR(50), "uri" VARCHAR(255) NOT NULL, "branch" VARCHAR(50) NOT NULL DEFAULT 'master', "command" VARCHAR(255) NOT NULL DEFAULT 'rake', "public" BOOLEAN DEFAULT 't', "building" BOOLEAN DEFAULT 'f', "created_at" DATETIME, "updated_at" DATETIME);
INSERT INTO "integrity_projects" VALUES(1,'Shout Bot','shout-bot','git://github.com/sr/shout-bot.git','master','ruby shout-bot.rb','t','f','2009-02-17T19:48:23+01:00','2009-02-17T19:49:05+01:00');
INSERT INTO "integrity_projects" VALUES(2,'Sinatra','sinatra','git://github.com/sinatra/sinatra.git','master','rake compat test','t','f','2009-02-17T19:49:48+01:00','2009-02-17T19:50:22+01:00');
