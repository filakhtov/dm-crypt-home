#!/bin/sh
set -e

userId="$1"
userName="$( id -nu "$userId" )"
homeDirectory="$( eval echo "~${userName}" )"

while ! umount -R "$homeDirectory" ; do
    fuser -k -m -s "$homeDirectory"
    sleep 1
done

cryptsetup close "home_${userId}"
