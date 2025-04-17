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

source "workflow/scripts/deactivate_python_env.sh"

cd $SOURCEDIR || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

# deactivate the inherited python environment.
# SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
# source "$SCRIPT_DIR/deactivate_python_env.sh"

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
