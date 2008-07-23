#!/bin/sh

set -e

# We nuke the pkgdb.db because portupgrade almost always gets in a
# twist over *something* in between upgrades. Totally nuking the
# database tends to translate into successful operation.

pkg_info | awk '{print $1}' | xargs pkg_delete
rm -rf /usr/ports/packages/All
rm /var/db/pkg/pkgdb.db

