#!/bin/bash

set -e

STUBBED_PROJECTS=( "$@" )
STUB_IMAGE='grnds/stubbed-green:latest'

for prj in "${STUBBED_PROJECTS[@]}" ; do
  tag="grnds/${prj}_ci:latest"
  echo "tagging $STUB_IMAGE with $tag"
  docker tag -f $STUB_IMAGE $tag
  docker push $tag
done
