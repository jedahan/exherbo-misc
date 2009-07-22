#!/bin/env zsh
# vim: set sw=4 sts=4 et tw=80 :

# This lists all unused repositories

for r in `paludis --list-repositories | egrep -v 'unavailable|unwritten|installed|account' | cut -d' ' -f2`;  
    paludis -q "*/*::$r->installed" --compact 2>&1 1> /dev/null | egrep 'Could not find' | cut -d':' -f3 | cut -d'>' -f1 | cut -d'-' -f1
