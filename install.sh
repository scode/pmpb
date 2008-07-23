#!/bin/sh

set -e

if ! [ -e /usr/local/bin/zsh ]
then
    echo "META: installing zsh to get script working"
    pkg_add /usr/ports/packages/All/zsh*
else
    echo "META: zsh is installed - proceeding"
fi

./install-zsh.sh $1

