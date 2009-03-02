#!/bin/env bash
# 
# Show installed and available packages, repositories. Symlink to:
#
#  /usr/share/paludis/hooks/sync_all_post 
#  /usr/share/paludis/hooks/sync_post
#
# BUGS:
#   does not count duplicates...

pInstalled=`paludis --list-packages --repository installed | grep -c "*"`
rInstalled=`paludis --list-repositories | grep -v account | grep -v installed | grep -v unwritten | awk -F " " '{print $2}'`
pTotal=0
rICount=-2 # unavailable{-unofficial} don't count
rOfficial=1 # arbor!

for r in ${rInstalled} ; do
    pCount=`paludis --list-packages --repository ${r} | grep -c "*"`
    let "pTotal += ${pCount}"
    let "rICount += 1"
done

# collect repository statistics
let "rOfficial += `ls /var/db/paludis/repositories/unavailable/*repository | wc -l`"
rUnofficial=`ls /var/db/paludis/repositories/unavailable-unofficial/*repository | wc -l`

echo "   $pInstalled packages installed out of $pTotal available"
echo "  $rICount repositories installed, $rOfficial official and $rUnofficial unofficial are available"
