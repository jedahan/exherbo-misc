#!/usr/bin/env bash
# vim: set et sw=4 sts=4 :

# This hook reports the number of installed and available packages. Copy or symlink to:
#
#   /usr/share/paludis/hooks/sync_all_post
#   /usr/share/paludis/hooks/sync_post
#

installed=`paludis --list-packages --repository installed | grep -c "*"`
available=`cave print-packages | grep -v user/ | grep -v group/ | grep -v virtual/ | wc -l`
echo "  Installed:  $installed"
echo "  Available: $available"
