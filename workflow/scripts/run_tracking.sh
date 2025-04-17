#!/bin/bash

# Default values for arguments
INPUT_FILE=""
OUTFILE=""
NUM_WORKERS=6
MAX_EVENTS=1
CHAINNAME="CKF_LEGACY"

# Function to display usage
usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i <input_file>   : Input file (e.g., RDO file list)"
    echo "  -o <output_file>  : Output file"
    echo "  -j <num_workers>  : Number of workers (default: $NUM_WORKERS)"
    echo "  -m <max_events>  : Maximum number of events to process (default: $MAX_EVENTS)"
    echo "  -c <chainname>   : Chain name (default: $CHAINNAME)"
    exit 1
}

# Parse arguments
while getopts "i:o:j:m:c:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        o) OUTFILE="$OPTARG" ;;
        j) NUM_WORKERS="$OPTARG" ;;
        m) MAX_EVENTS="$OPTARG" ;;
        c) CHAINNAME="$OPTARG" ;;
        \?) usage exit 1 ;;
    esac
done

# Check for mandatory arguments
if [[ -z "$INPUT_FILE" || -z "$OUTFILE" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

OUTFILE=$(realpath "$OUTFILE")
WORK_DIR=$(dirname "$OUTFILE")
WORK_DIR=$(realpath "$WORK_DIR")

# Main script logic
echo "Running $0 \n $(date) @ $(hostname)"
echo "-----------------------------------"
echo "Input File: $INPUT_FILE"
echo "Working Directory: $WORK_DIR"
echo "Output File: $OUTFILE"
echo "Number of Workers: $NUM_WORKERS"
echo "Max Events: $MAX_EVENTS"
echo "Chain Name: $CHAINNAME"

# check if chain name is in
# ["CKF_LEGACY", "GNN4ITk_ML_LOCAL", "GNN4ITK_ML_TRITON"]
if [[ "$CHAINNAME" != "CKF_LEGACY" && "$CHAINNAME" != "GNN4ITk_ML_LOCAL" && "$CHAINNAME" != "GNN4ITk_ML_TRITON" ]]; then
    echo "Error: Invalid chain name. Must be one of [CKF_LEGACY, GNN4ITk_ML_LOCAL, GNN4ITk_ML_TRITON]."
    exit 1
fi

RDO_FILENAME=$(cat ${INPUT_FILE} | paste -sd ',')
echo $RDO_FILENAME

source "workflow/scripts/deactivate_python_env.sh"


cd $WORK_DIR || { echo "Failed to change directory to $WORK_DIR"; exit 1; }


if [ -f "PoolFileCatalog.xml" ]; then
    echo "Cleanup workarea."
    rm InDetIdDict.xml PoolFileCatalog.xml hostnamelookup.tmp eventLoopHeartBeat.txt
fi

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,main,here,latest

export ATHENA_CORE_NUMBER=$NUM_WORKERS

DETECTOR_CONDITIONS="all:OFLCOND-MC15c-SDR-14-05"
GEOMETRY_VERSION="all:ATLAS-P2-RUN4-03-00-00"

echo "Running ${CHAINNAME} with ${NUM_WORKERS} workers"
if [[ "$CHAINNAME" == "CKF_LEGACY" ]]; then
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4ITk_ML_LOCAL" ]]; then
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnFinderValidation' \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --maxEvents ${MAX_EVENTS}
else
    echo "not implemented yet."
    exit 1
fi

# Check for errors
if [ $? -ne 0 ]; then
    echo "Error: Reco_tf.py failed."
    exit 1
fi

# Write output
echo "-----------------------------------"
echo "DONE $(date +%Y-%m-%dT%H:%M:%S)"
