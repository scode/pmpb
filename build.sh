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

function build {
  origin=$1

  log2 "building $origin"

  logfile="$logdir/$(echo $origin | sed -e s,/,_,g).log"

  log3 "building $origin"
  if ! (cd $portsroot/$origin && make build 2>&1) >> $logfile
  then
      log3 "package $origin failed build step - see $logfile"
      return
  else
      rm $logfile
  fi

  log3 "installing $origin"
  if ! (cd $portsroot/$origin && make install 2>&1) >> $logfile
  then
      log3 "package $origin failed install step - see $logfile"
      return
  else
      rm $logfile
  fi

  log3 "packaging $origin"
  if ! (cd $portsroot/$origin && make package 2>&1) >> $logfile
  then
      log3 "package $origin failed package step - see $logfile"
      return
  else
      rm $logfile
  fi

  log3 "cleaning $origin"
  # this seems to return non-successfully often for some reason; without
  # any actual error
  (cd $portsroot/$origin && make clean) >> /dev/null

  #if (cd $portsroot/$origin && make clean 2>&1) >> $logfile
  #then
  #    log3 "package $origin failed clean step - see $logfile"
  #    return
  #else
  #    rm $logfile
  #fi
}

function originfailed {
    origin=$1

    [ -e "$logdir/$(echo $origin | sed -e s,/,_,g).log" ]
}

function buildrecursively {
  origin=$1
  level=$2

  log "processing $origin"

  if [ "$level" -gt "20" ]
  then
      log "ERROR: recursion level exceeds 20 (cyclic dependencies?) - bailing; let's not fork bomb the machine"
      exit 1
  fi

  for dep in $(cd $portsroot/$origin && make all-depends-list | sed -e "s,$portsroot/,,g")
  do
    failed="false"
    if ! (packageisinstalled $dep)
    then
      log3 "$origin depends on $dep which is not installed"

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
    else
      log3 "$origin depends on $dep which is already installed"
    fi
  done

  if (packageisinstalled $origin)
  then
    log3 "$origin is already installed"
  else
    if [ "$failed" = "false" ]
    then
      if (originfailed $origin)
      then
        log3 "not building $origin because it has already been attempted and failed"
      else
        (build $origin)
      fi
    else
      log3 "not building $origin due to failed dependencies"
    fi
  fi
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

