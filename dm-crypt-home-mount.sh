#!/bin/sh
set -e

userId="$1"
devicePath="$( realpath "$2" )"
userName="$( id -nu "$userId" )"
homeDirectory="$( eval echo "~${userName}" )"

keyctl pipe "$( keyctl request user "user:${userId}" )" | cryptsetup --type luks open "$devicePath" "home_${userId}_${userName}" -d -
mount ${mountOpts} -v "/dev/mapper/home_${userId}_${userName}" "$homeDirectory"

