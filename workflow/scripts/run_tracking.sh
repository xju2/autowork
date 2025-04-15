#!/bin/bash

# Default values for arguments
INPUT_FILE=""
WORK_DIR=""
OUTPUT_FILE=""
NUM_WORKERS=6

# Function to display usage
usage() {
    echo "Usage: $0 -i <input_file> -d <work_dir> -o <output_file>"
    echo "  -i <input_file>   : Input file (e.g., RDO file list)"
    echo "  -d <work_dir>     : Working directory"
    echo "  -o <output_file>  : Output file"
    echo "  -j <num_workers>  : Number of workers (default: $NUM_WORKERS)"
    exit 1
}

# Parse arguments
while getopts "i:d:o:j:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        d) WORK_DIR="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        j) NUM_WORKERS="$OPTARG" ;;
        \?) usage exit 1 ;;
    esac
done

# Check for mandatory arguments
if [[ -z "$INPUT_FILE" || -z "$WORK_DIR" || -z "$OUTPUT_FILE" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

OUTFILE=$(realpath "$OUTPUT_FILE")

# Main script logic
echo "Running $0 on $(date) @ $(hostname)" > "$OUTFILE"
echo "-----------------------------------" >> "$OUTFILE"
echo "Input File: $INPUT_FILE" >> "$OUTFILE"
echo "Working Directory: $WORK_DIR" >> "$OUTFILE"
echo "Output File: $OUTPUT_FILE" >> "$OUTFILE"
echo "Number of Workers: $NUM_WORKERS" >> "$OUTFILE"


cd $WORK_DIR || { echo "Failed to change directory to $WORK_DIR"; exit 1; }

RDO_FILENAME=$(cat ${INPUT_FILE} | paste -sd ',')

echo $RDO_FILENAME

if [ -f "PoolFileCatalog.xml" ]; then
    echo "Cleanup workarea."
    rm InDetIdDict.xml PoolFileCatalog.xml hostnamelookup.tmp eventLoopHeartBeat.txt
fi

export ATHENA_CORE_NUMBER=$NUM_WORKERS

# Reco_tf.py \
#     --CA 'all:True' --autoConfiguration 'everything' \
#     --conditionsTag 'all:OFLCOND-MC15c-SDR-14-05' \
#     --geometryVersion 'all:ATLAS-P2-RUN4-03-00-00' \
#     --multithreaded 'True' \
#     --steering 'doRAWtoALL' \
#     --digiSteeringConf 'StandardInTimeOnlyTruth' \
#     --postInclude 'all:PyJobTransforms.UseFrontier' \
#     --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' \
#     --inputRDOFile "${RDO_FILENAME}" \
#     --outputAODFile 'test.aod.ckf.debug.root'  \
#     --jobNumber '1' \
#     --athenaopts='--loglevel=INFO' \
#     --maxEvents -1 2>&1 | tee log.ckf.txt


# Write output
echo "-----------------------------------" >> "$OUTFILE"
echo "DONE $(date +%Y-%m-%dT%H:%M:%S)" >> "$OUTFILE"
