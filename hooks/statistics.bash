#!/bin/env bash
# vim: set et sw=4 sts=4 :
# 
# Show installed and available packages, repositories. Symlink to:
#
#  /usr/share/paludis/hooks/sync_all_post 
#

pInstalled=`paludis --list-packages --repository installed | grep -c "*"`
pAvailable=`cave print-packages | egrep -vc 'user/|group/|virtual/'`

rInstalled=`cave print-repositories | egrep -vc 'account|installed|un'`

    rLoc=`paludis --configuration-variable unavailable location`
    ruLoc=`paludis --configuration-variable unavailable-unofficial location`

rAvailable=`ls {$rLoc,$ruLoc}/* | wc -l`
let "rAvailable += 1" # arbor


echo "    packages: $pInstalled installed    $pAvailable available"
echo "repositories:  $rInstalled installed      $rAvailable available"
