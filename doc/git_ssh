#!/bin/sh

IDENTITY_FILE="`mktemp /tmp/integrity.$USER.XXXXXXXX`"
echo "$GIT_PRIVATE_KEY" > "$IDENTITY_FILE"

ssh -i "$IDENTITY_FILE" -o "StrictHostKeyChecking no" "$@"
rv=$?

rm -f "$IDENTITY_FILE"

exit $rv
