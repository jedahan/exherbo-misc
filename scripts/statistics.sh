#!/bin/env bash
# Show some package statistics
# needs permissions in /etc/paludis/repositories

# make the environment clean
cd /etc/paludis/repositories/
mkdir temp
mv *conf temp/
mv temp/{accounts,arbor,installed-accounts,installed,unavailable-unofficial,unavailable,unpackaged,unwritten}.conf .

# collect package statistics
pInstalled=`paludis --list-packages --repository installed | grep -c "*"`
pOfficial=`paludis --list-packages --repository unavailable  --repository arbor | grep -c "*"`
pUnofficial=`paludis --list-packages --repository unavailable-unofficial | grep -c "*"`
pTotal=`paludis --list-packages --repository arbor --repository unavailable --repository unavailable-unofficial | grep -c "*"`

# collect repository statistics
rOfficial=`ls /var/db/paludis/repositories/unavailable/*repository | wc -l`
let "rOfficial += 1"
rUnofficial=`ls /var/db/paludis/repositories/unavailable-unofficial/*repository | wc -l`

echo "   $pInstalled packages installed out of $pTotal available"
echo "  $pOfficial available from $rOfficial official repositories"
echo "   $pUnofficial from $rUnofficial unofficial repositories"

mv temp/*conf .
rm -r temp
