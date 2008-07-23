#!/usr/local/bin/zsh

set -e

source $(dirname $0)/build.env

pkgtype=$1

for package in $(cat packages.${pkgtype})
do
  if ! packageisinstalled $package
  then
      log "NOT INSATLLED: $package"
  fi
done

