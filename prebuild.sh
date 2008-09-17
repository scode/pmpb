#!/bin/sh

set -e

cd /usr/ports/ports-mgmt/portconf && make BATCH=1 clean package-recursive
cd /usr/ports/ports-mgmt/portconf && make clean
cd /usr/ports/shells/zsh && make BATCH=1 clean package-recursive
cd /usr/ports/shells/zsh && make clean
cd /usr/ports/ports-mgmt/portupgrade && make BATCH=1 clean package-recursive
cd /usr/ports/ports-mgmg/portupgrade && make clean



