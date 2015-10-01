Integrity — Continuous Integration Server
=========================================

### Intro
Integrity is the custom-built, CI server for Grand Rounds. It is backed by CoreOS and Docker.

#### Installation

**Environment Vars Needed:**
```Bash
export RACK_ENV="development"
export DATABASE_URL="mysql://localhost/integrity"
export QUEUE="integrity"
export GITHUB_ACCOUNT="ConsultingMD"
export GITHUB_READ_TOKEN="..."   # Get tokens from Engineering Repo
export GITHUB_WRITE_TOKEN="..."
export PIVOTAL_TRACKER_TOKEN="..."   # Get tokens from Engineering Repo
export PIVOTAL_TRACKER_PROJECT_ID="..."
export SENDGRID_USERNAME="..."   # Get tokens from Engineering Repo
export SENDGRID_PASSWORD="..."
```

**Console:**
```Bash
$> bundle install
mysql> CREATE DATABASE integrity;
$> rake db
$> rake jobs:work
```

#### Building Projects

In order to have a project build on Integrity you need two things. Register the project, then add the build files to the projects repo.

**Register your project on integrity:**

1. Click *Nav > Add Project*
2. Add a name for your project.
3. Add your projects git repo uri. (i.e. git://github.com/ConsultingMD/...)
4. Click *Create Project*

**Add these files to target Repo:**

Add an *honesty* directory along with the following files to the top-level of your project.

```Bash
- honesty
  - base
    - Dockerfile
    - upstart-envs
    - chris-lea-node_js-trusty.list
  - Dockerfile
  - build.sh
  - git-checkout.sh

```

Given your project, you may need more files, if your build process requires it. See other projects (i.e. jarvis or frick) to see examples of the build files.


#### Troubleshooting Builds

**Checking CoreOS:**
SSH into coreos server
```Bash
 $> ssh -A core@coreos.test.grandrounds.com
```

**Check build containers *(units)*:**
```Bash
   $> fleetctl list-units
```

**Check Worker Machines:**
```Bash
   $> fleetctl list-machines
```

**Destroy a Build Unit:**
- Make sure to kill app and mysql containers
```Bash
   $> fleetctl destroy jarvis_8cefa79_1945_app.service
   $> fleetctl destroy jarvis_8cefa79_1945_mysql.service
```

**Checking Integrity Web:**
SSH into integrity server
```Bash
 $> ssh ubuntu@integrity-2014-12-02-1b.test.grandrounds.com
```

**Checking Status:**

- Check Web Service
```Bash
 $> sudo status integrity
 $> sts
```
- Check Jobs
```Bash
 $> ps -ef | grep jobs
 $> running jobs
 $> stsj
```
- Restarting Web Service
```Bash
 $> sudo restart integrity
 $> rst
```

- Restarting Jobs
```Bash
 $> bundle exec rake jobs:daemons:restart
 $> rstj
```

- Start Pending Builds
NOTE: Irb will load integrity application automatically
```Bash
 $> irb
 irb> Integrity::Builder.queue_builds!
```

- Start a build syncronously
```Bash
 irb> build = Integrity::Build.get(123)
 irb> build.run!
```


#### Links:
- Live: https://integrity.test.grandrounds.com
- Code: http://github.com/ConsultingMD/honesty
