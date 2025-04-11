#!/usr/bin/env bash

SOURCEDIR=$(pwd)
OUTFILE="build.log"
NWORKERS=32

HELP_MSG="Usage: $0 [-d source_directory] [-o output_file] [-j nworkers]"

while getopts ":d:o:j:" opt; do
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


cd $SOURCEDIR || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

# deactivate the herited python environment.
deactivate

# load the ATLAS environment
source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,main,here,latest

cd build || { echo "Failed to change directory to `build`"; exit 1; }
env > envlog.log
source */setup.sh
export `grep CMAKE_PREFIX_PATH envlog.log`

cd ../run

# run the G300 chain:
Reco_tf.py --CA \
    --preInclude "InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude" \
    --inputRDOFile '/cvmfs/atlas-nightlies.cern.ch/repo/data/data-art/PhaseIIUpgrade/RDO/ATLAS-P2-RUN4-03-00-00/mc21_14TeV.601229.PhPy8EG_A14_ttbar_hdamp258p75_SingleLep.recon.RDO.e8481_s4149_r14700/RDO.33629020._000047.pool.root.1' \
    --outputAODFile AOD.test.root \
    --steering doRAWtoALL  \
    --postInclude "EFTracking.TrackingAlgG300Config.TrackingAlgG300Cfg" \
    --maxEvents 1
