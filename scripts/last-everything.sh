#!/bin/env sh

cd /tmp
splits=`csplit -k /var/log/paludis.log  /starting\ install\ of\ targets\ everything/ /finished\ install\ of\ targets\ everything/+1 | wc -l`

let "splits -= 2"

cat "xx0$splits"
rm xx*
