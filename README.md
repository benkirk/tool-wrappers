# Tool Wrappers
## "Faking" a native installation of containerized applications
Occasionally it can be beneficial to "hide" the fact that a particular application is containerized - or within a `conda` environment - typically to simplify the user interface and usage experience. In this section we follow a clever approach deployed by the [NIH Biowulf team](https://hpc.nih.gov/apps/singularity.html) and outlined [here](https://singularity-tutorial.github.io/07-fake-installation/) to enable users to interact transparently with containerized applications without needing to know any details of the run-time (`singularity`, `ch-run`, etc...).

The basic idea is to create a `wrapper.sh` shell script that
1. Infers the name of the containerized command to run,
2. Invokes the chosen run-time transparently to the user, and
3. Passes along any command-line arguments to the containerized application.
   
Consider the following directory tree structure, taken from a production deployment:
```pre
.
├── README.md
├── bin
│   ├── emacs -> ../libexec/wrap_singularity.sh
│   ├── eog -> ../libexec/wrap_singularity.sh
│   ├── evince -> ../libexec/wrap_singularity.sh
│   ├── gedit -> ../libexec/wrap_singularity.sh
│   ├── geeqie -> ../libexec/wrap_singularity.sh
│   ├── gimp -> ../libexec/wrap_singularity.sh
│   ├── gv -> ../libexec/wrap_singularity.sh
│   ├── meld -> ../libexec/wrap_singularity.sh
│   ├── nedit -> ../libexec/wrap_singularity.sh
│   ├── nvim -> ../libexec/wrap_singularity.sh
│   ├── ratarmount -> ../libexec/wrap_conda.sh
│   ├── smplayer -> ../libexec/wrap_singularity.sh
│   ├── vlc -> ../libexec/wrap_singularity.sh
│   ├── xemacs -> ../libexec/wrap_singularity.sh
│   └── xfig -> ../libexec/wrap_singularity.sh
└── libexec
    ├── Makefile
    ├── ratarmount.yaml
    ├── wrap_conda.sh
    └── wrap_singularity.sh
```
At the top level, we simply have two directories: `./bin/` (which likely will go into the user's `PATH`) and `./libexec/` (where we will hide implementation details).

## Constructing the `bin` directory

The `./bin/` directory contains symbolic links to the `wrap_{conda,singularity}.sh` scripts, where the name of the symbolic link is the application to run. For the example above, when a user runs `./bin/gv` for example, it will invoke the `wrap_singularity.sh` "behind the scenes." In general there can be many application symbolic links in the `./bin/` directory, so long as the desired application exists within the wrapped container image or `conda` environment.


## Wrapping Conda Environments
```bash
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
```

## Wrapping Container Images
### Singularity
```bash
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
```
Specifically:

- The command to execute is inferred from the shell argument `${0}` - the name of the script being executed. Here is where the symbolic links from `./bin` are important: If the symbolic link `./bin/gv` is invoked, for example, the script above will execute with the name `gv`. This is accessible within the script as `${0}`, and is stored in the `requested_command` variable.
- Any command-line arguments passed to the executable are captured in the `${@}` environment variable, and are passed directly through as command-line arguments to the containerized application.
- We bind-mount the usual GLADE file systems so that expected data are accessible.
- In this example we execute all commands in the same base container `ncar-casper-gui_tools.sif`. This is the simplest approach, however strictly not required. (A more complex treatment could "choose" different base containers for different commands using a bash case statement, for example, if desired.)
- The container is launched with the users' directory `topdir` as the working directory. This is required so that any relative paths specified are handled properly.
- In order to robustly access the required apptainer module, we first check to see if the module command is recognized and if not initialize the module environment, then load the apptainer module. This allows the script to function properly even when the user does not have the module system initialized in their environment - a rare but an occasional issue.

While the example above wraps the Apptainer run-time, a similar approach works for Charliecloud and Podman as well if desired.
