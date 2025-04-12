#!/usr/bin/env bash
SOURCEDIR=$(pwd)
OUTFILE="build.log"
RELEASE="25.0.30"

HELP_MSG="Usage: $0 [-d source_directory] [-o output_file] [-r release]"

while getopts ":d:o:r:" opt; do
  case ${opt} in
    d )
      SOURCEDIR=$OPTARG
      ;;
    o )
      OUTFILE=$OPTARG
      ;;
    r )
      RELEASE=$OPTARG
      ;;
    \? )
      echo $HELP_MSG
      exit 1
      ;;
  esac
done

OUTFILE=$(realpath "$OUTFILE")

## log the parameters...
echo "Running $0 on $(date) @ $(hostname)" > $OUTFILE
echo "-----------------------------------" >> $OUTFILE
echo "Output file: ${OUTFILE}" >> $OUTFILE
echo "Source directory: ${SOURCEDIR}" >> $OUTFILE
echo "Release: ${RELEASE}" >> $OUTFILE

cd $SOURCEDIR || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

# deactivate the inherited python environment.
function deactivate () {
    # reset old environment variables
    if [ -n "${_OLD_VIRTUAL_PATH:-}" ] ; then
        PATH="${_OLD_VIRTUAL_PATH:-}"
        export PATH
        unset _OLD_VIRTUAL_PATH
    fi
    if [ -n "${_OLD_VIRTUAL_PYTHONHOME:-}" ] ; then
        PYTHONHOME="${_OLD_VIRTUAL_PYTHONHOME:-}"
        export PYTHONHOME
        unset _OLD_VIRTUAL_PYTHONHOME
    fi

    # Call hash to forget past commands. Without forgetting
    # past commands the $PATH changes we made may not be respected
    hash -r 2> /dev/null

    if [ -n "${_OLD_VIRTUAL_PS1:-}" ] ; then
        PS1="${_OLD_VIRTUAL_PS1:-}"
        export PS1
        unset _OLD_VIRTUAL_PS1
    fi

    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
    if [ ! "${1:-}" = "nondestructive" ] ; then
    # Self destruct!
        unset -f deactivate
    fi
}

# unset irrelevant variables
deactivate nondestructive

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh 
setupATLAS

asetup Athena,$RELEASE,here --releasepath=$SOURCEDIR/build/install

## run some test.

cd $SOURCEDIR/build/build/Athena
ctest -R CITest_DerivationRun2Data_PHYS_ctest --output-on-failure >> $OUTFILE
if [ $? -ne 0 ]; then
    echo "Test failed" >> $OUTFILE
    exit 1
fi

echo "-----------------------------------" >> $OUTFILE
echo "DONE on $(date)" >> $OUTFILE
