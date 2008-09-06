#!/usr/local/bin/zsh

set -e

source $(dirname $0)/build.env

logdir="buildlog"

mkdir -p $logdir
for f in $(ls $logdir)
do
    rm $logdir/$f
done


pkgtype=$1

function buildpackage {
  origin=$1

  log "processing $origin"
  if packageisinstalled $origin
  then
    log2 "$origin already installed - skipping"
  else
#    if ! (cd /usr/ports/$origin && make clean package-recursive)
    logfile="$logdir/$(echo $origin | sed -e s,/,_,g).log"
    log2 "building $origin and dependencies"

    if script -t 0 $logfile portinstall -pr $origin 1>/dev/null 2>/dev/null
    then
	rm $logfile
    else
	log2 "BUILD:  package $origin failed to build - see $logfile"
	(cd /usr/ports/$origin && make clean) || log2 "BUILD:  (cleaning of $origin failed)"
    fi
  fi
}

for package in $(cat packages.${pkgtype})
do

  buildpackage $package

done

