Integrity — Continuous Integration Server
=========================================

### Intro
Integrity is the custom-built, CI server for Grand Rounds. It is backed by CoreOS and Docker.

#### Installation

**Environment Vars Needed:**
```Bash
export RACK_ENV="development"
export INTEGRITY_DATABASE_URL="mysql://root@localhost:3306/integrity"
export QUEUE="integrity"
export GITHUB_ACCOUNT="ConsultingMD"
export GITHUB_READ_TOKEN="..."   # Get tokens from Engineering Repo
export GITHUB_WRITE_TOKEN="..."
```

**Console:**
```Bash
$> bundle install
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

Given your project, you may need more files, if your build process requires it.

#### Links:
Live: https://integrity.test.grandrounds.com
Code: http://github.com/ConsultingMD/honesty


