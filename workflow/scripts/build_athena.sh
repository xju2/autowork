#!/usr/bin/env bash
AtlasExternals_URL="https://gitlab.cern.ch/athena/atlasexternals.git"
AtlasExternals_REF="origin/debug_mr_triton"
NWORKERS=32
CLONE_SOURCE=false
SOURCEDIR=$(pwd)
OUTFILE="build.log"
DO_EXTERNAL=true

HELP_MSG="Usage: $0 [-s] [-u url] [-r ref] [-j nworkers] [-d source_directory] [-o output_file] [-a]"

while getopts ":su:r:j:d:o:" opt; do
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


# if [ "$CLONE_SOURCE" = true ]; then
#     echo "Cloning source code from $AtlasExternals_URL" >> $OUTFILE
#     git clone $AtlasExternals_URL $SOURCEDIR || { echo "Failed to clone repository"; exit 1; }
# else
#     echo "Using existing source code in $SOURCEDIR" >> $OUTFILE
# fi

cd $SOURCEDIR || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh 
setupATLAS
asetup none,gcc13,cmakesetup --cmakeversion=3.30.5


export AtlasExternals_URL=$AtlasExternals_URL
export AtlasExternals_REF=$AtlasExternals_REF

export G4PATH=/cvmfs/atlas-nightlies.cern.ch/repo/sw/main_Athena_x86_64-el9-gcc13-opt/Geant4

if [ "$DO_EXTERNAL" = true ]; then
  echo "Building external dependencies..." >> $OUTFILE
  time ./athena/Projects/Athena/build_externals.sh -t Release \
      -k "-j${NWORKERS}" 2>&1 | tee build/log.external.txt
else
  echo "Building Athena on top of the external dependencies build..." >> $OUTFILE
  time ./athena/Projects/Athena/build.sh -acmi \
    -x "-DATLAS_ENABLE_CI_TESTS=TRUE -DATLAS_EXTERNAL=${ATLASAuthXML} -DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE " \
    -k "-j${NWORKERS}" 2>&1 | tee build/log.build.athena.txt
fi

echo "-----------------------------------" >> $OUTFILE
echo "DONE on $(date)" >> $OUTFILE
