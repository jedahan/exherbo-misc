#!/usr/bin/env bash
# vim: set et sw=4 sts=4 :

# Copyright 2010 Jonathan Dahan <jedahan@gmail.com>
# Distributed under the terms of the GNU General Public License v2

# This hook removes all non-english locales
# To enable this misfunctionality, this script should be copied or
# symlinked into:
#
#     /usr/share/paludis/hooks/merger_install_pre/
#
# You should ensure that it has execute permissions.

source ${PALUDIS_ECHO_FUNCTIONS_DIR:-${PALUDIS_EBUILD_DIR}}/echo_functions.bash

hook_auto_names() {
   echo merger_install_pre
}

hook_run_merger_install_pre() {
    source "${PALUDIS_EBUILD_DIR}"/echo_functions.bash
    find usr/share/locale -type d ! -name "en*" | xargs rm -rf
}
