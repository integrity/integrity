Integrity — Continuous Integration Server
=========================================

### Intro
Integrity is the custom-built, CI server for Grand Rounds. It is backed by CoreOS and Docker.

#### Installation

**Environment Vars Needed:**
```
export RACK_ENV="development"
export INTEGRITY_DATABASE_URL="mysql://root@localhost:3306/integrity"
export DATABASE_URL="mysql2://root@localhost:3306/integrity"
export QUEUE="integrity"
export GITHUB_ACCOUNT="ConsultingMD"
export GITHUB_READ_TOKEN="..."   # Get tokens from Engineering Repo
export GITHUB_WRITE_TOKEN="..."
```

**Console:**
```
$> bundle install
$> rake db:
$> rake jobs:work
```


#### Links:
Live: https://integrity.test.grandrounds.com
Code: http://github.com/ConsultingMD/honesty


