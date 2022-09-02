#!/usr/bin/env bash
#exit on error
set -e

readonly USERBASE="run"

# make sure USERID makes sense as UID:GID
# it looks like the alpine distro limits UID and GID to 256000, but
# could be more, so we accept any valid integers
USERID=${USERID:-"0:0"}
if [[ ! $USERID =~ ^[0-9]+:[0-9]+$ ]]; then
  echo "USERID environment variable invalid, format is userid:groupid.  Received: \"${USERID}\""
  exit 1
fi

# separate uid and gid
uid=${USERID%%:*}
gid=${USERID##*:}

# if requested UID:GID is root, go ahead and run without other processing
if [[ ${uid} == 0 && ${gid} == 0 ]]; then
  exec su-exec 0:0 pre-commit "$@"
fi

# make sure workdir and some files are readable/writable by the provided UID/GID
# combo, otherwise will have errors when processing hooks
wdir="$(pwd)"
if ! su-exec "${uid}:${gid}" "/bin/bash" -c "test -w ${wdir} && test -r ${wdir}"; then
  echo "user:gid ${uid}:${gid} lacks permissions to ${wdir}/"
  exit 1
fi
if ! su-exec "${uid}:${gid}" "/bin/bash" -c "test -w ${wdir}/.git/index && test -r ${wdir}/.git/index"; then
  echo "user:gid ${uid}:${gid} cannot write to ${wdir}/.git/index2"
  exit 1
fi

# check if group by this GID already exists, if so get the name since adduser
# only accepts names
if groupinfo="$(getent group "${gid}")"; then
  groupname="${groupinfo%%:*}"
else
  # create group in advance in case GID is different than UID
  groupname="${USERBASE}${gid}"
  if ! err="$(addgroup -g "${gid}" "${groupname}" 2>&1)"; then
    echo "failed to create gid \"${gid}\" with name \"${groupname}\""
    echo "command output: ${err}"
    exit 1
  fi
fi

# check if user by this UID already exists, if so get the name since id
# only accepts names
if userinfo="$(getent passwd "${uid}")"; then
  username="${userinfo%%:*}"
else
  username="${USERBASE}${uid}"
  if ! err="$(adduser -h "/home/${username}" -s "/bin/bash" -G "${groupname}" -D -u "${uid}" -k "/etc/skel" "${username}")"; then
    echo "failed to create uid \"${uid}\" with name \"${username}\" and group \"${groupname}\""
    echo "command output: ${err}"
    exit 1
  fi
fi

# it's possible it was not in the group specified, add it
if ! idgroupinfo="$(id -G "${username}" 2>&1)"; then
  echo "failed to get group list for username \"${username}\""
  echo "command output: ${idgroupinfo}"
  exit 1
fi
if [[ ! " ${idgroupinfo} " =~ [:blank:]${gid}[:blank:] ]]; then
  if ! err="$(addgroup "${username}" "${groupname}")"; then
    echo "failed to add user \"${username}\" to group \"${groupname}\""
    echo "command output: ${err}"
    exit 1
  fi
fi

# user and group of specified UID/GID should exist now, and user should be
# a member of group, so execute pre-commit
exec su-exec "${uid}:${gid}" pre-commit "$@"
