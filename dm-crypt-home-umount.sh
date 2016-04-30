#!/bin/sh
set -e

userId="$1"
userName="$( id -nu "$userId" )"
homeDirectory="$( eval echo "~${userName}" )"

while fuser -k -m "$homeDirectory" > /dev/null ; do
    sleep 1
done

umount -R "$homeDirectory"
cryptsetup close "home_${userId}"

