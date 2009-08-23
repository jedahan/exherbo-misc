#!/usr/bin/env bash
# vim: set et sw=4 sts=4 :

# Copyright 2009 Jonathan Dahan <jedahan@gmail.com>
# Distributed under the terms of the GNU General Public License v2

# This hook makes Paludis display a summary of leftover files after an
# uninstall. To enable this functionality, this script should be copied or
# symlinked into:
#
#     /usr/share/paludis/hooks/uninstall_all_pre/
#     /usr/share/paludis/hooks/uninstall_all_post/
#
# You should ensure that it has execute permissions.

source ${PALUDIS_ECHO_FUNCTIONS_DIR:-${PALUDIS_EBUILD_DIR}}/echo_functions.bash

fileprefix="${PALUDIS_HOOKS_TMPDIR:-${ROOT}/var/tmp/paludis}/${PALUDIS_PID}"
contentsfile="${fileprefix}.contents"
rmfile="${fileprefix}.remove"

case "${HOOK}" in
    uninstall_all_pre)
    for i in `${PALUDIS_COMMAND} -k ${TARGETS} | grep '^\    /' | cut -d' ' -f5`; do 
        ls -dF "$i" | sed -e '/\/$/ d' -e 's/\*//g'; 
    done > ${contentsfile}

    ;;

    uninstall_all_post)
    for i in `cat ${contentsfile}`; do 
        if [ -e $i ]; then 
            echo $i >> ${rmfile}
        fi
    done
    if [ -e ${rmfile} ]; then
        einfo "cat ${rmfile} | xargs sudo rm -rf"
    fi
    ;;

    *)
    ewarn "leftovers.bash doesn't know what to do for HOOK=\"${HOOK}\""

    ;;
esac
