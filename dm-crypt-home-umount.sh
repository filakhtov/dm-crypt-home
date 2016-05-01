#!/bin/sh
set -e

userId="$1"
userName="$( id -nu "$userId" )"
homeDirectory="$( eval echo "~${userName}" )"

if mount | grep -q "on ${homeDirectory} type" ; then
    while ! umount -R "$homeDirectory" ; do
        fuser -k -m -s "$homeDirectory"
        sleep 1
    done
fi

cryptsetup close "home_${userId}"
