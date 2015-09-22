#!/bin/bash
set -vex

echo "This is a stubbed build. I always pass Honesty."
EXIT_STATUS='0'
curl -v -X POST -H "Content-Type: application/json" -d "{\"project\":\"$PROJECT\", \"build_id\":\"$BUILD_ID\", \"success\":${EXIT_STATUS}}" $CALLBACK_URL
