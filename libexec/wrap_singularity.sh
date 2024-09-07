#!/bin/bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
selfdir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
#----------------------------------------------------------------------------

topdir="$(pwd)"

requested_command="$(basename ${0})"

case "${requested_command}" in
    # https://bbs.archlinux.org/viewtopic.php?id=157830
    "meld"|"gimp"|"vlc")
        requested_command="dbus-launch ${requested_command}"
        ;;
    *)
        ;;
esac

cd ${selfdir} || exit 1

XDG_RUNTIME_DIR=${TMPDIR}/xdg-runtime-${USER} && mkdir -p ${XDG_RUNTIME_DIR} && chmod 700 ${XDG_RUNTIME_DIR}

type module >/dev/null 2>&1 || . /etc/profile.d/z00_modules.sh
module load apptainer || exit 1

container_img="ncar-casper-gui_tools"
make ${container_img}.sif >/dev/null || exit 1

cd ${topdir} || exit 1

unset extra_binds

[ -d /local_scratch ] && extra_binds="-B /local_scratch ${extra_binds}"

singularity \
    --quiet \
    exec \
    --cleanenv \
    -B /glade ${extra_binds} \
    --env DISPLAY=${DISPLAY} \
    --env XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR} \
    --env NO_AT_BRIDGE=1 \
    ${selfdir}/${container_img}.sif \
    ${requested_command} ${@}
