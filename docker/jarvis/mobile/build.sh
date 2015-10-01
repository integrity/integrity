#!/bin/bash
git clone https://${GITHUB_READ_TOKEN}@github.com/ConsultingMD/ConsultingMD jarvis
cd jarvis
git fetch origin ${MOBILE_SPEC_BRANCH}
git checkout ${MOBILE_SPEC_BRANCH}
echo "[Starting Mobile Tests]"
rspec --require ./docker/mobile-specs/spec_helper.rb --options ./docker/mobile-specs/.rspec spec/mobile/
RSPEC_EXIT_STATUS=$?
echo "[Finished Mobile Tests with exit code: ${RSPEC_EXIT_STATUS}]"
exit ${RSPEC_EXIT_STATUS}
