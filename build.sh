#!/usr/local/bin/zsh

set -e

source $(dirname $0)/build.env

pkgtype=$1

function buildpackage {
  origin=$1

  log "BUILD: processing $origin"
  if packageisinstalled $origin
  then
    log "BUILD: $pkg already installed - skipping"
  else
    log "BUILD: building $pkg"
#    if ! (cd /usr/ports/$origin && make clean package-recursive)
    if ! (portinstall -pr $origin)
    then
	log "BUILD: package $pkg from $origin failed"
	echo "$origin" >> packages.failed
    fi
    (cd /usr/ports/$origin && make clean) || log "BUILD: (cleaning of $origin failed)"
  fi
}

for package in $(cat packages.${pkgtype})
do

  buildpackage $package

done

