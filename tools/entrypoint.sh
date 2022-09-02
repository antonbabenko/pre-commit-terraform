#!/usr/bin/env bash
#exit on error
set -e

USERID=${USERID:-"0:0"}
if [[ ! $USERID =~ ^[0-9]+:[0-9]+$ ]]; then
    echo "USERID environment variable invalid, format is userid:groupid.  Received: \"${USERID}\""
    exit 1
fi

uid=${USERID%%:*}
gid=${USERID##*:}

if [[ ${uid} == 0 && ${gid} == 0 ]]; then
    su-exec 0:0 pre-commit "$@"
fi

