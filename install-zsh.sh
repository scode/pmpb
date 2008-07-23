#!/usr/local/bin/zsh

set -e

source $(dirname $0)/build.env

pkgtype=$1

function instpack {
    if ! packageisinstalled $package
    then
	echo "******** Installing $package and dependencies... ********"
	ensurepackageinstalled $package
    else
	echo "******** Packag $package is already installed    ********"
    fi
}

for package in $(cat packages.${pkgtype})
do
    instpack $package
done



