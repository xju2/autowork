#!/usr/bin/env bash
AtlasExternals_URL="https://gitlab.cern.ch/athena/atlasexternals.git"
AtlasExternals_REF="origin/debug_mr_triton"
NWORKERS=32
CLONE_SOURCE=false
SOURCEDIR=$(pwd)
OUTFILE="build.log"
DO_EXTERNAL=true
EXCMAKEARGS=""

HELP_MSG="Usage: $0 [-s] [-u url] [-r ref] [-j nworkers] [-d source_directory] [-o output_file] [-a] [-x cmakeargs]"

while getopts "asu:r:j:d:o:x:b:" opt; do
  case ${opt} in
    u )
      AtlasExternals_URL=$OPTARG
      ;;
    r )
      AtlasExternals_REF=$OPTARG
      ;;
    j )
      NWORKERS=$OPTARG
      ;;
    s )
      CLONE_SOURCE=true
      ;;
    d )
      SOURCEDIR=$OPTARG
      ;;
    o )
      OUTFILE=$OPTARG
      ;;
    a )
      DO_EXTERNAL=false
      ;;
    x )
      EXCMAKEARGS=$OPTARG
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
echo "AtlasExternals_URL: ${AtlasExternals_URL}" >> $OUTFILE
echo "AtlasExternals_REF: ${AtlasExternals_REF}" >> $OUTFILE
echo "NWORKERS: ${NWORKERS}" >> $OUTFILE
echo "CLONE_SOURCE: ${CLONE_SOURCE}" >> $OUTFILE
echo "Output file: ${OUTFILE}" >> $OUTFILE
echo "Source directory: ${SOURCEDIR}" >> $OUTFILE
echo "DO_EXTERNAL: ${DO_EXTERNAL}" >> $OUTFILE
echo "EXCMAKEARGS: ${EXCMAKEARGS}" >> $OUTFILE

source "workflow/scripts/deactivate_python_env.sh"

cd $SOURCEDIR || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

# # unset the python environment
# SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
# source "$SCRIPT_DIR/deactivate_python_env.sh"

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup none,gcc13,cmakesetup --cmakeversion=3.30.5


export AtlasExternals_URL=$AtlasExternals_URL
export AtlasExternals_REF=$AtlasExternals_REF

export G4PATH=/cvmfs/atlas-nightlies.cern.ch/repo/sw/main_Athena_x86_64-el9-gcc13-opt/Geant4

mkdir build

export PATH=/cvmfs/sft.cern.ch/lcg/contrib/ninja/1.11.1/Linux-x86_64/bin:$PATH
export ATLASAuthXML=/global/cfs/cdirs/atlas/xju/data/xml

if [ "$DO_EXTERNAL" = "true" ]; then
  echo "Building external dependencies..." >> $OUTFILE
  time ./athena/Projects/Athena/build_externals.sh -t Release \
      -x "${EXCMAKEARGS}" \
      -k "-j${NWORKERS}" 2>&1 | tee build/log.external.txt
else
  echo "Building Athena on top of the external dependencies build..." >> $OUTFILE
  time ./athena/Projects/Athena/build.sh -acmi \
    -x "-DATLAS_ENABLE_CI_TESTS=TRUE -DATLAS_EXTERNAL=${ATLASAuthXML} -DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE ${EXCMAKEARGS}" \
    -k "-j${NWORKERS}" 2>&1 | tee build/log.build.athena.txt
fi

echo "-----------------------------------" >> $OUTFILE
echo "DONE on $(date)" >> $OUTFILE
