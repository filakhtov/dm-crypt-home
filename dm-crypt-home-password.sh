#!/bin/sh
set -e

exec keyctl padd user "user:$( id -u "$PAM_USER" )" @u

