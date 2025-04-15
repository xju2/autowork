#!/bin/bash

# Default values for arguments
INPUT_FILE=""
OUTFILE=""
NUM_WORKERS=6
MAX_EVENTS=1

# Function to display usage
usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i <input_file>   : Input file (e.g., RDO file list)"
    echo "  -o <output_file>  : Output file"
    echo "  -j <num_workers>  : Number of workers (default: $NUM_WORKERS)"
    echo "  -m <max_events>  : Maximum number of events to process (default: $MAX_EVENTS)"
    exit 1
}

# Parse arguments
while getopts "i:o:j:m:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        o) OUTFILE="$OPTARG" ;;
        j) NUM_WORKERS="$OPTARG" ;;
        m) MAX_EVENTS="$OPTARG" ;;
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

RDO_FILENAME=$(cat ${INPUT_FILE} | paste -sd ',')
echo $RDO_FILENAME


cd $WORK_DIR || { echo "Failed to change directory to $WORK_DIR"; exit 1; }


if [ -f "PoolFileCatalog.xml" ]; then
    echo "Cleanup workarea."
    rm InDetIdDict.xml PoolFileCatalog.xml hostnamelookup.tmp eventLoopHeartBeat.txt
fi

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,main,here,latest

export ATHENA_CORE_NUMBER=$NUM_WORKERS

Reco_tf.py \
    --CA 'all:True' --autoConfiguration 'everything' \
    --conditionsTag 'all:OFLCOND-MC15c-SDR-14-05' \
    --geometryVersion 'all:ATLAS-P2-RUN4-03-00-00' \
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

# Check for errors
if [ $? -ne 0 ]; then
    echo "Error: Reco_tf.py failed."
    exit 1
fi

# Write output
echo "-----------------------------------"
echo "DONE $(date +%Y-%m-%dT%H:%M:%S)"
