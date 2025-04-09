#!/bin/bash
AtlasExternals_URL="https://gitlab.cern.ch/xju/atlasexternals.git"
AtlasExternals_REF="origin/debug_mr_triton"
NWORKERS=32
CLONE_SOURCE=false

HELP_MSG="Usage: $0 [-s] [-u url] [-r ref] [-j nworkers] <output_file> <source_directory>"

while getopts ":su:r:j:" opt; do
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
    \? )
      echo $HELP_MSG
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))


if [ "$#" -ne 2 ]; then
    echo $HELP_MSG
    exit 1
fi

OUTFILE=$(realpath "$1")
SOURCEDIR=$2

## log the parameters...
echo "Running $0 on $(date) @ $(hostname)" > $OUTFILE
echo "-----------------------------------" >> $OUTFILE
echo "AtlasExternals_URL: ${AtlasExternals_URL}" >> $OUTFILE
echo "AtlasExternals_REF: ${AtlasExternals_REF}" >> $OUTFILE
echo "NWORKERS: ${NWORKERS}" >> $OUTFILE
echo "CLONE_SOURCE: ${CLONE_SOURCE}" >> $OUTFILE
echo "Output file: ${OUTFILE}" >> $OUTFILE
echo "Source directory: ${SOURCEDIR}" >> $OUTFILE


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

export PATH=/cvmfs/sft.cern.ch/lcg/contrib/ninja/1.11.1/Linux-x86_64/bin:$PATH
export ATLASAuthXML=/global/cfs/cdirs/atlas/xju/data/xml

export AtlasExternals_URL=$AtlasExternals_URL
export AtlasExternals_REF=$AtlasExternals_REF

export G4PATH=/cvmfs/atlas-nightlies.cern.ch/repo/sw/main_Athena_x86_64-el9-gcc13-opt/Geant4

rm -rf build && mkdir build
./athena/Projects/Athena/build_externals.sh -t Release -k "-j${NWORKERS}" 2>&1 | tee build/log.external.txt

echo "-----------------------------------" >> $OUTFILE
echo "DONE on $(date)" >> $OUTFILE
