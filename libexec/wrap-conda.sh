#!/usr/bin/env bash

# following https://hpc.nih.gov/apps/singularity.html
SCRIPTDIR="$( cd "$( dirname "$(readlink -f ${BASH_SOURCE[0]})" )" >/dev/null 2>&1 && pwd )"

#echo "pwd=$(pwd)"
#echo "SCRIPTDIR=${SCRIPTDIR}"

cmd="$(basename $0)"

module purge >/dev/null 2>&1 || exit 1
module load conda >/dev/null 2>&1

# create the conda environment, if necessary.
make -C ${SCRIPTDIR} --silent ${cmd}-env

conda activate ${SCRIPTDIR}/${cmd}-env/ >/dev/null 2>&1 \
    || { echo "Cannot 'conda activate ${SCRIPTDIR}/${cmd}-env'"; exit 1; }

# run the wrapped command with any arguments
${cmd} "$@"
