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
rOfficial=`ls /var/db/paludis/repositories/unavailable/*repository | wc -l`
let "rOfficial += 1" # arbor
rUnofficial=`ls /var/db/paludis/repositories/unavailable-unofficial/*repository | wc -l`

pOld=`date -d "Wed Feb 11 11:22:48 CET 2009" +%s`
pNew=`date +%s`
let "pDays = ($pNew - $pOld) / 86400"

let "pDelta = $pAvailable-1379"
let "pPerDay = $pDelta/$pDays"

echo "   $pInstalled packages installed out of $pAvailable available"
echo "  $rInstalled package repositories installed, $rOfficial official and $rUnofficial unofficial are available"
echo " $pDelta new packages have been added in the past $pDays days, thats at least $pPerDay per day!"
