#!/usr/local/bin/zsh

set -e

source $(dirname $0)/build.env

logdir="buildlog"
portsroot=/usr/ports

mkdir -p $logdir
for f in $(ls $logdir)
do
    rm $logdir/$f
done


pkgtype=$1

function buildorigin {
  origin=$1

  logfile="$logdir/$(echo $origin | sed -e s,/,_,g).log"

  log3 " building $origin"
  if (cd $portsroot/$origin && make package clean 2>&1) >> $logfile
  then
      log3 "package $origin failed - see $logfile"
  else
      rm $logfile
  fi
}

function originfailed {
    origin=$1

    [ -e "$logdir/$(echo $origin | sed -e s,/,_,g).log" ]
}

function buildrecursively {
  origin=$1
  level=$2

  if [ "$level" -gt "20" ]
  then
      log "ERROR: recursion level exceeds 20 (cyclic dependencies?) - bailing; let's not fork bomb the machine"
      exit 1
  fi

  for dep in $(cd $portsroot/$origin && make all-depends-list | sed -e "s,$portsroot/,,g")
  do
    log3 "$origin depends on $dep"
    failed="false"
    if ! (packageisinstalled $dep)
    then
      if (originfailed $dep)
      then
	log3 "dependency $origin seems to have failed a previous build attempt - skipping"
	failed="true"
      else
	(buildrecursively $dep $(($level + 1)))
	if (originfailed $dep)
	then
	  log3 "dependency $origin failed to build - skipping"
	  failed="true"
	fi
      fi
    fi
    
    if [ "$failed" = "false" ]
    then
      if (originfailed $origin)
      then
	log3 "not building $origin because it has already been attempted and failed"
      else
	(buildorigin $origin)
      fi
    else
      log3 "not building $origin due to failed dependencies"
    fi
  done
}

function buildpackage {
  origin=$1

  log "processing $origin"
  if packageisinstalled $origin
  then
    log2 "$origin already installed - skipping"
  else
    builddeps $origin

#    if ! (cd /usr/ports/$origin && make clean package-recursive)
    logfile="$logdir/$(echo $origin | sed -e s,/,_,g).log"
    log2 "building $origin and dependencies"

    if script -t 0 $logfile portinstall -pr $origin 1>/dev/null 2>/dev/null
    then
	rm $logfile
    else
	log2 "package $origin failed to build - see $logfile"
	(cd /usr/ports/$origin && make clean) || log2 "(cleaning of $origin failed)"
    fi
  fi
}

for origin in $(cat packages.${pkgtype})
do

  #buildpackage $origin
  buildrecursively $origin 0

done

