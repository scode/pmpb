#!/bin/sh

set -e

# We nuke the pkgdb.db because portupgrade almost always gets in a
# twist over *something* in between upgrades. Totally nuking the
# database tends to translate into successful operation.

BATCH=1 pkg_delete -a -a
rm -rf /usr/ports/packages/All
rm /var/db/pkg/pkgdb.db

