#!/bin/sh
set -e

userId="$1"
userName="$( id -nu "$userId" )"
homeDirectory="$( eval echo "~${userName}" )"

umount -R "$homeDirectory"
cryptsetup close "home_${userId}_${userName}"

