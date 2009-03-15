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
let "rAvailable = $rOfficial + $rUnofficial"


# calculate the number of packages / day
pOld=`date -d "Wed Feb 11 11:22:48 CET 2009" +%s`
pNew=`date +%s`
let "pDays = ($pNew - $pOld) / 86400"
let "pDelta = $pAvailable-1379"
let "pPerDay = $pDelta/$pDays"

echo "    packages: $pInstalled installed    $pAvailable available    $pPerDay new daily"
echo "repositories:  $rInstalled installed      $rAvailable available"

#echo "  $rInstalled repositories installed /   $rOfficial official & $rUnofficial unofficial"
#echo " $pDelta packages added in the last $pDays days, at least $pPerDay/day!"
