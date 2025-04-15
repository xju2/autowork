#!/usr/bin/env bash

SOURCEDIR=$(pwd)
OUTFILE="build.log"
NWORKERS=32
DOG300=false

HELP_MSG="Usage: $0 [-d source_directory] [-o output_file] [-j nworkers] [-g]"

while getopts ":d:o:j:g:" opt; do
  case ${opt} in
    d )
      SOURCEDIR=$OPTARG
      ;;
    o )
      OUTFILE=$OPTARG
      ;;
    j )
        NWORKERS=$OPTARG
        ;;
    g )
        if [[ $OPTARG == "true" ]]; then
            DOG300=true
        fi
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
echo "NWORKERS: ${NWORKERS}" >> $OUTFILE
echo "DOG300: ${DOG300}" >> $OUTFILE


cd $SOURCEDIR || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

# deactivate the herited python environment.
SCRIPT_DIR=$(realpath "${BASH_SOURCE[0]}")
source "$SCRIPT_DIR/deactivate_python_env.sh"

# load the ATLAS environment
source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,main,here,latest

cd build || { echo "Failed to change directory to `build`"; exit 1; }
env > envlog.log
source */setup.sh
export `grep CMAKE_PREFIX_PATH envlog.log`

cd ../run

POST_INCLUDE="EFTracking.TrackingAlgConfig.TrackingAlgCfg"
if [ "$DOG300" = true ]; then
    POST_INCLUDE="EFTracking.TrackingAlgConfig.TrackingAlgG300Cfg"
fi
# run the G300 chain:
Reco_tf.py --CA \
    --preInclude "InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude" \
    --inputRDOFile '/cvmfs/atlas-nightlies.cern.ch/repo/data/data-art/PhaseIIUpgrade/RDO/ATLAS-P2-RUN4-03-00-00/mc21_14TeV.601229.PhPy8EG_A14_ttbar_hdamp258p75_SingleLep.recon.RDO.e8481_s4149_r14700/RDO.33629020._000047.pool.root.1' \
    --outputAODFile AOD.test.root \
    --steering doRAWtoALL  \
    --postInclude "EFTracking.TrackingAlgConfig.TrackingAlgCfg" \
    --maxEvents 1

echo "DONE on $(date +%Y-%m-%dT%H:%M:%S)" >> "$OUTFILE"
