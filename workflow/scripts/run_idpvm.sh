#!/bin/bash
# set -eo pipefail  # -e to exit on error, -u to treat unset variables as errors, -o pipefail to catch errors in pipelines
# IFS=$'\n\t'

# Default values for arguments
INPUT_FILE=""
SETUP_FILE=""
NUM_WORKERS=6
MAX_EVENTS=1
OUTFILE=""
CHAIN_NAME="PRIMARY"


# Function to display usage
usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i <input_file>   : Input file (e.g., RDO file list)"
    echo "  -s <setup_file>   : Setup file (default: $SETUP_FILE)"
    echo "  -j <num_workers>  : Number of workers (default: $NUM_WORKERS)"
    echo "  -m <max_events>  : Maximum number of events to process (default: $MAX_EVENTS)"
    echo "  -o <output_file>  : Output file"
    echo "  -c <chain_name>   : Chain name (default: $CHAIN_NAME)"
    echo "  -h                : Display this help message"
    exit 1
}

# Parse arguments
while getopts "i:s:j:m:o:c:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        s) SETUP_FILE="$OPTARG" ;;
        j) NUM_WORKERS="$OPTARG" ;;
        m) MAX_EVENTS="$OPTARG" ;;
        o) OUTFILE="$OPTARG" ;;
        c) CHAIN_NAME="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage exit 1 ;;
    esac
done

INFILE=$(realpath "$INPUT_FILE")
OUTFILE=$(realpath "$OUTFILE")
RUN_DIR=$(dirname "$OUTFILE")
RUN_DIR=$(realpath "$RUN_DIR")

# Main script logic
echo "Running $0 \n $(date) @ $(hostname)"
echo "-----------------------------------"
echo "Input File: $INPUT_FILE"
echo "Setup File: $SETUP_FILE"
echo "Run Directory: $RUN_DIR"
echo "Output File: $OUTFILE"
echo "Number of Workers: $NUM_WORKERS"
echo "Max Events: $MAX_EVENTS"
echo "Chain Name: $CHAIN_NAME"


source "workflow/scripts/deactivate_python_env.sh"

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS

if [[ -f "$SETUP_FILE" ]]; then
    SETUP_FILE=$(realpath "$SETUP_FILE")
    echo "Set up environment from $SETUP_FILE"
    source workflow/scripts/setup_athena_from_json.sh
    setup_athena_from_json "$SETUP_FILE"
else
    echo "Warning: Setup file $SETUP_FILE not found"
    echo "Using the default setup: \"Athena,main,latest,here\""
    asetup Athena,main,latest,here
fi

export ATHENA_CORE_NUMBER=$NUM_WORKERS

cd ${RUN_DIR} || { echo "Failed to change directory to ${RUN_DIR}"; exit 1; }
echo "Running with ${NUM_WORKERS} workers"

if [ -f "PoolFileCatalog.xml" ]; then
    echo "Cleanup workarea."
    rm InDetIdDict.xml PoolFileCatalog.xml hostnamelookup.tmp eventLoopHeartBeat.txt
fi

LRT_OPTIONS=()
if [[ "${CHAIN_NAME}" == "LRT" ]]; then
    echo "Running LRT workflow"
    LRT_OPTIONS+=(--doLargeD0Tracks --ancestorIDList 36)
else
    echo "Running standard workflow"
fi

# Build IDPVM options safely
FULL_IDPVM_OPTIONS=(
    --maxEvents "${MAX_EVENTS}"
    --filesInput "${INFILE}"
    --outputFile "${OUTFILE}"
    --truthMinPt 1000
    --HSFlag HardScatter
    --doTruthToRecoNtuple
    --doLoose
    --doTightPrimary
    --doHitLevelPlots
    --OnlyTrackingPreInclude
    "${LRT_OPTIONS[@]}"
)

echo -e "Full IDPVM Options:\n    runIDPVM.py ${FULL_IDPVM_OPTIONS[*]}"
runIDPVM.py "${FULL_IDPVM_OPTIONS[@]}"


echo "DONE $(date +%Y-%m-%dT%H:%M:%S)"
