#!/usr/bin/env zsh

setopt ERR_EXIT
setopt NO_UNSET

root=$0:A:h:h

cd $root/picknmix
exec meteor $@

