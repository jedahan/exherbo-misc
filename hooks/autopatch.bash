#!/usr/bin/env bash
# vim: set et sw=4 sts=4 :

# This hook autopatches sources. Copy or symlink this script into:
#
#    /usr/share/paludis/hooks/ebuild_prepare_pre
#    /usr/share/paludis/hooks/install_all_post
#
# You may also want to set $PALUDIS_HOOKS_AUTO_PATCH_DIR in /etc/paludis/bashrc

case "${EBUILD_PHASE}" in
    compile|config|configure|fetch|init|metadata|nofetch|postinst|postrm|preinst|prerm|setup|strip|test|tidyup|unpack) return
esac

source ${PALUDIS_ECHO_FUNCTIONS_DIR:-${PALUDIS_EBUILD_DIR}}/echo_functions.bash

AUTOPATCH_DIR="${PALUDIS_HOOKS_AUTO_PATCH_DIR}/${CATEGORY}/${PN}"
AUTOPATCHED_FILE="${PALUDIS_HOOKS_TMPDIR:-${ROOT}/var/tmp/paludis}/._autopatched_${PALUDIS_PID}"

case "${HOOK}" in
    ebuild_prepare_pre)
        if [ -d "${AUTOPATCH_DIR}" ] ; then
            echo "Patching with user patches from: ${AUTOPATCH_DIR}"
            for p in `ls ${AUTOPATCH_DIR}/*.patch` ; do
                epatch ${p}
                touch ${AUTOPATCHED_FILE}
            done
            if [ -e "${AUTOPATCHED_FILE}" ] ; then
                ewarn "WARNING: This package will be installed with extra patches applied by the user-patch hook."
                ewarn "WARNING: Before filing bugs, remove all the patches and reinstall."
            else
                einfo "No patches found for ${PN}"
            fi
        fi
        ;;
    install_all_post)
        if [ -e "${AUTOPATCHED_FILE}" ] ; then
            ewarn "WARNING: This package will be installed with extra patches applied by the user-patch hook."
            ewarn "WARNING: Before filing bugs, remove all the patches and reinstall."
            rm ${AUTOPATCHED_FILE}
        fi
        ;;
esac

