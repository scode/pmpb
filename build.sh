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
  local origin=$1

  log2 "preparing $origin"

  local logfile="$(originlog $origin)"

  log3 "pre-cleaning $origin"
  (cd $portsroot/$origin && make clean) >> /dev/null || log3 'pre-cleaning failed - ignoring that'

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
  (cd $portsroot/$origin && make clean) >> /dev/null || log3 "cleaning failed - ignoring that"

  #if (cd $portsroot/$origin && make clean 2>&1) >> $logfile
  #then
  #    log3 "package $origin failed clean step - see $logfile"
  #    return
  #else
  #    rm $logfile
  #fi
}

function originlog {
    echo "$logdir/$(echo $origin | sed -e s,/,_,g).log"
}

function originfailed {
    local origin=$1
    
    [ -e "$(originlog $origin)" ]
}

function buildrecursively {
  local origin=$1
  local level=$2

  log "processing $origin (pkgname: $(packagename $origin))"

  if packageisinstalled $origin
  then
    log3 "$origin is already installed"
    return
  fi

  if [ "$level" -gt "20" ]
  then
      log "ERROR: recursion level exceeds 20 (cyclic dependencies?) - bailing; let's not fork bomb the machine"
      exit 1
  fi

  local failed="false"
  local dep
  for dep in $(cd $portsroot/$origin && make all-depends-list | sed -e "s,$portsroot/,,g")
  do
    if ! packageisinstalled $dep
    then
      log3 "$origin depends on $dep which is not installed"
      
      if originfailed $dep
      then
	log3 "dependency $dep seems to have failed a previous build attempt - skipping"
	failed="true"
      else
	buildrecursively $dep $(($level + 1))
	if originfailed $dep
	then
	  log3 "dependency $dep failed to build - skipping"
	  failed="true"
	fi
      fi
    else
      log3 "$origin depends on $dep which is already installed"
    fi
  done

  if packageisinstalled $origin
  then
    log3 "$origin is already installed"
  else
    if [ "$failed" = "false" ]
    then
      if originfailed $origin
      then
        log3 "not building $origin because it has already been attempted and failed"
      else
        build $origin
      fi
    else
      log3 "not building $origin due to failed dependencies"
      echo "building of this origin was not attempted due to failed dependencies" >> $(originlog $origin)
    fi
  fi
}

function buildpackage {
  local origin=$1

  log "processing $origin"
  if packageisinstalled $origin
  then
    log2 "$origin already installed - skipping"
  else
    builddeps $origin

#    if ! (cd /usr/ports/$origin && make clean package-recursive)
    local logfile="$(originlog $origin)"
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

local origin
for origin in $(cat packages.${pkgtype})
do

  #buildpackage $origin
  buildrecursively $origin 0 || log "$origin failed - continuing with next item"

done

