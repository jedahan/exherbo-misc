#!/bin/env bash
# vim: set et sw=4 sts=4 :
# 
# Show installed and available packages, repositories. Symlink to:
#
#  /usr/share/paludis/hooks/sync_all_post 
#  /usr/share/paludis/hooks/sync_post
#

pInstalled=`paludis --list-packages --repository installed | grep -c "*"`
pAvailable=`cave print-packages | grep -v user/ | grep -v group/ | grep -v virtual/ | wc -l`

rInstalled=`cave print-repositories | grep -v account | grep -v installed | grep -v unwritten | grep -v unavailable | wc -l`

rLocation=`paludis --configuration-variable unavailable location`
ruLocation=`paludis --configuration-variable unavailable-unofficial location`

rOfficial=`ls $rLocation/*repository | wc -l`
let "rOfficial += 1" # arbor
rUnofficial=`ls $ruLocation/*repository | wc -l`
let "rAvailable = $rOfficial + $rUnofficial"

echo "    packages: $pInstalled installed    $pAvailable available"
echo "repositories:  $rInstalled installed      $rAvailable available"
