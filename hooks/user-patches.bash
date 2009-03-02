#!/usr/bin/env bash
# vim: set et sw=4 sts=4 :

# This hook autopatches sources. Copy or symlink this script into:
#
#   /usr/share/paludis/hooks/ebuild_src_prepare_pre
#
# You may also want to set $PATCHDIR in /etc/paludis/bashrc

if [[ -d "${PATCHDIR}/${CATEGORY}/${PN}" ]]
then
    echo "Adding user-patches from ${PATCHDIR}/${CATEGORY}/${PN}"
    for uPatch in `ls ${PATCHDIR}/${CATEGORY}/${PN}`
    do
        patch -p1 ${PATCHDIR}${CATEGORY}/${PN}/${uPatch} -d ${WORK}
    done
fi
