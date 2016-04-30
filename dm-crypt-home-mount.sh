#!/bin/sh
set -e

userId="$1"
devicePath="$( realpath "$2" )"
userName="$( id -nu "$userId" )"
homeDirectory="$( eval echo "~${userName}" )"

keyId="$( keyctl request user "user:${userId}" )"

keyctl pipe "$keyId" | cryptsetup --type luks open "$devicePath" "home_${userId}" -d -
mount ${mountOpts} -v "/dev/mapper/home_${userId}" "$homeDirectory"
keyctl revoke "$keyId"

