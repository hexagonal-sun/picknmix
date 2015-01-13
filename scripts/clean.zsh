#!/usr/bin/env zsh

setopt ERR_EXIT
setopt NO_UNSET

root=$0:A:h:h
rm --force --recursive --verbose $root/picknmix/.meteor/local

