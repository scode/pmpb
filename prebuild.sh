#!/bin/sh

set -e

cd /usr/ports/ports-mgmt/portconf && make BATCH=1 clean package-recursive
cd /usr/ports/ports-mgmt/portconf && make clean
cd /usr/ports/shells/zsh && make BATCH=1 clean package-recursive
cd /usr/ports/shells/zsh && make clean
cd /usr/ports/ports-mgmt/portupgrade && make BATCH=1 clean package-recursive
cd /usr/ports/ports-mgmt/portupgrade && make clean

# not needed by the scripts, however it is useful to kick off the full build
# in a screen and thus anoying when screen is missing
cd /usr/ports/sysutils/screen && make BATCH=1 clean package-recursive
cd /usr/ports/sysutils/screen && make clean


