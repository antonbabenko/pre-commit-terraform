#!/usr/bin/env bash
#exit on error
set -e

readonly USERBASE="run"
readonly BASHPATH="/bin/bash"

function echo_error_and_exit {
  echo -e "ERROR: $@" >&2
  exit 1
}

# make sure USERID makes sense as UID:GID
# it looks like the alpine distro limits UID and GID to 256000, but
# could be more, so we accept any valid integers
USERID=${USERID:-"0:0"}
if [[ ! $USERID =~ ^[0-9]+:[0-9]+$ ]]; then
  echo_error_and_exit "USERID environment variable invalid, format is userid:groupid.  Received: \"${USERID}\""
fi

# separate uid and gid
uid=${USERID%%:*}
gid=${USERID##*:}

# if requested UID:GID is root, go ahead and run without other processing
[[ $USERID == "0:0" ]] && exec su-exec "$USERID" pre-commit "$@"

# make sure workdir and some files are readable/writable by the provided UID/GID
# combo, otherwise will have errors when processing hooks
wdir="$(pwd)"
if ! su-exec "$USERID" "$BASHPATH" -c "test -w ${wdir} && test -r ${wdir}"; then
  echo_error_and_exit "uid:gid $USERID lacks permissions to ${wdir}/"
fi
wdirgitindex="$wdir/.git/index"
if ! su-exec "$USERID" "$BASHPATH" -c "test -w $wdirgitindex && test -r $wdirgitindex"; then
  echo_error_and_exit "uid:gid $USERID cannot write to ${wdir}/.git/index"
fi

# check if group by this GID already exists, if so get the name since adduser
# only accepts names
if groupinfo="$(getent group "${gid}")"; then
  groupname="${groupinfo%%:*}"
else
  # create group in advance in case GID is different than UID
  groupname="${USERBASE}${gid}"
  if ! err="$(addgroup -g "${gid}" "${groupname}" 2>&1)"; then
    echo_error_and_exit "failed to create gid \"${gid}\" with name \"${groupname}\" command output: \"$err\""
  fi
fi

# check if user by this UID already exists, if so get the name since id
# only accepts names
if userinfo="$(getent passwd "${uid}")"; then
  username="${userinfo%%:*}"
else
  username="${USERBASE}${uid}"
  if ! err="$(adduser -h "/home/${username}" -s "$BASHPATH" -G "${groupname}" -D -u "${uid}" -k "${HOME}" "${username}" 2>&1)"; then
    echo_error_and_exit "failed to create uid \"${uid}\" with name \"${username}\" and group \"${groupname}\" command output: \"$err\""
  fi
fi

# it's possible it was not in the group specified, add it
if ! idgroupinfo="$(id -G "${username}" 2>&1)"; then
  echo_error_and_exit "failed to get group list for username \"${username}\" command output: \"$idgroupinfo\""
fi
if [[ ! " ${idgroupinfo} " =~ [:blank:]${gid}[:blank:] ]]; then
  if ! err="$(addgroup "${username}" "${groupname}" 2>&1)"; then
    echo_error_and_exit "failed to add user \"${username}\" to group \"${groupname}\" command output: \"${err}\""
  fi
fi

# user and group of specified UID/GID should exist now, and user should be
# a member of group, so execute pre-commit
exec su-exec "$USERID" pre-commit "$@"
