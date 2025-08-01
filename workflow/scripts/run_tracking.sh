#!/bin/bash

# Default values for arguments
INPUT_FILE=""
OUTFILE=""
NUM_WORKERS=6
MAX_EVENTS=1
CHAINNAME="CKF_LEGACY"
SETUP_FILE=""
TRITON_MODEL_NAME="metriclearning"
TRITON_CONFIG=""

# Function to display usage
usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i <input_file>   : Input file (e.g., RDO file list)"
    echo "  -o <output_file>  : Output file"
    echo "  -j <num_workers>  : Number of workers (default: $NUM_WORKERS)"
    echo "  -m <max_events>  : Maximum number of events to process (default: $MAX_EVENTS)"
    echo "  -c <chainname>   : Chain name (default: $CHAINNAME)"
    echo "  -s <setup_file>   : Setup file (default: $SETUP_FILE)"
    echo "  -p <triton_model_name> : Triton model name (default: $TRITON_MODEL_NAME)"
    echo "  -u <triton_url>   : Triton Server config (default: $TRITON_CONFIG)"
    echo "  -h                : Display this help message"
    exit 1
}

# Parse arguments
while getopts "i:o:j:m:c:s:p:u:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        o) OUTFILE="$OPTARG" ;;
        j) NUM_WORKERS="$OPTARG" ;;
        m) MAX_EVENTS="$OPTARG" ;;
        c) CHAINNAME="$OPTARG" ;;
        s) SETUP_FILE="$OPTARG" ;;
        p) TRITON_MODEL_NAME="$OPTARG" ;;
        u) TRITON_CONFIG="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage exit 1 ;;
    esac
done

OUTFILE=$(realpath "$OUTFILE")
RUN_DIR=$(dirname "$OUTFILE")
RUN_DIR=$(realpath "$RUN_DIR")
TRITON_CONFIG=$(realpath "$TRITON_CONFIG")

# Main script logic
echo "Running $0 \n $(date) @ $(hostname)"
echo "-----------------------------------"
echo "Input File: $INPUT_FILE"
echo "Run Directory: $RUN_DIR"
echo "Output File: $OUTFILE"
echo "Number of Workers: $NUM_WORKERS"
echo "Max Events: $MAX_EVENTS"
echo "Chain Name: $CHAINNAME"
echo "Setup File: $SETUP_FILE"
echo "Triton Model Name: $TRITON_MODEL_NAME"
echo "Triton Server Config: $TRITON_CONFIG"

RDO_FILENAME=$(cat ${INPUT_FILE} | paste -sd ',')
echo $RDO_FILENAME

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
echo "Running ${CHAINNAME} in ${RUN_DIR} with ${NUM_WORKERS} workers"

# Extract unique identifiers for directory naming to avoid conflicts
ATH_DEV_NAME="default"
TRITON_DEV_NAME="none"

# Extract ath_dev_name from setup file path if available
if [[ -n "$SETUP_FILE" && "$SETUP_FILE" =~ athena\.([^.]+)\.([^.]+)\.built\.json$ ]]; then
    # Pattern: athena.{prefix}.{ath_dev_name}.built.json
    # If prefix is "default", use it; otherwise use the second part
    if [[ "${BASH_REMATCH[1]}" == "default" ]]; then
        ATH_DEV_NAME="${BASH_REMATCH[2]}"
    else
        # For external builds like athena.{external}.{ath_dev_name}.built.json
        ATH_DEV_NAME="${BASH_REMATCH[2]}"
    fi
fi

# Extract triton_dev_name from triton config file path if available  
if [[ -n "$TRITON_CONFIG" && "$TRITON_CONFIG" =~ triton_server\.([^.]+)\.ready\.json$ ]]; then
    TRITON_DEV_NAME="${BASH_REMATCH[1]}"
fi

echo "Athena Dev Name: $ATH_DEV_NAME"
echo "Triton Dev Name: $TRITON_DEV_NAME"

if [ -f "PoolFileCatalog.xml" ]; then
    echo "Cleanup workarea."
    rm InDetIdDict.xml PoolFileCatalog.xml hostnamelookup.tmp eventLoopHeartBeat.txt
fi

# if TRITON_CONFIG is provided, set the Triton URL and port ID
if [[ -n "$TRITON_CONFIG" ]]; then
    echo "Using Triton Server configuration from $TRITON_CONFIG"
    TRITON_URL=$(jq -r '.url' "$TRITON_CONFIG")
    if [[ -z "$TRITON_URL" ]]; then
        echo "Error: Triton URL not found in $TRITON_CONFIG"
        exit 1
    fi
    TRITON_PORT=$(jq -r '.port' "$TRITON_CONFIG")
    if [[ -z "$TRITON_PORT" ]]; then
        echo "Error: Triton port not found in $TRITON_CONFIG"
        echo "Using default port 8001"
        TRITON_PORT=8001
    fi
else
    TRITON_URL="localhost"
    TRITON_PORT=8001
fi
echo "Triton URL: $TRITON_URL"
echo "Triton Port: $TRITON_PORT"

DETECTOR_CONDITIONS="all:OFLCOND-MC15c-SDR-14-05"
GEOMETRY_VERSION="all:ATLAS-P2-RUN4-03-00-00"

if [[ "$CHAINNAME" == "CKF_LEGACY" ]]; then
    WORK_DIR="ckf_legacy_${ATH_DEV_NAME}_${TRITON_DEV_NAME}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || { echo "Failed to create or change directory to $WORK_DIR"; exit 1; }
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
        --perfmonmt 'fullmonmt' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4ITk_ML_LOCAL" ]]; then
    WORK_DIR="gnn4itk_ml_local_${ATH_DEV_NAME}_${TRITON_DEV_NAME}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || { echo "Failed to create or change directory to $WORK_DIR"; exit 1; }
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preExec "all:flags.ITk.doEndcapEtaNeighbour=True; flags.Tracking.ITkGNNPass.minClusters = [7,7,7]; flags.Tracking.ITkGNNPass.maxHoles = [4,4,2]; " \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnFinderValidation' \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --perfmonmt 'fullmonmt' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4ITk_ML_TRITON" ]]; then
    WORK_DIR="gnn4itk_ml_triton_${ATH_DEV_NAME}_${TRITON_DEV_NAME}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || { echo "Failed to create or change directory to $WORK_DIR"; exit 1; }
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preExec "all:flags.ITk.doEndcapEtaNeighbour=True; flags.Tracking.ITkGNNPass.minClusters = [7,7,7]; flags.Tracking.ITkGNNPass.maxHoles = [4,4,2]; flags.Tracking.GNN.Triton.model = \"$TRITON_MODEL_NAME\"; flags.Tracking.GNN.Triton.url = \"$TRITON_URL\"; flags.Tracking.GNN.Triton.port = ${TRITON_PORT}" \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnTritonValidation' \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --perfmonmt 'fullmonmt' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4ITk_ML_TRITON-NoEndcapOLSP" ]]; then
    # should be the same as GNN4ITk_ML_TRITON, but with no endcap overlap SPs for Strip subdetector.
    WORK_DIR="gnn4itk_ml_triton-noendcapolsp_${ATH_DEV_NAME}_${TRITON_DEV_NAME}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || { echo "Failed to create or change directory to $WORK_DIR"; exit 1; }
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preExec "all:flags.Tracking.ITkGNNPass.minClusters = [7,7,7]; flags.Tracking.ITkGNNPass.maxHoles = [4,4,2]; flags.Tracking.GNN.Triton.model = \"$TRITON_MODEL_NAME\"; flags.Tracking.GNN.Triton.url = \"$TRITON_URL\"; flags.Tracking.GNN.Triton.port = ${TRITON_PORT}" \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnTritonValidation' \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --perfmonmt 'fullmonmt' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4ITk_ML_TRITON-DefaultCuts" ]]; then
    WORK_DIR="gnn4itk_ml_triton-defaultcuts_${ATH_DEV_NAME}_${TRITON_DEV_NAME}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || { echo "Failed to create or change directory to $WORK_DIR"; exit 1; }
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preExec "all:flags.ITk.doEndcapEtaNeighbour=True; flags.Tracking.GNN.Triton.model = \"$TRITON_MODEL_NAME\"; flags.Tracking.GNN.Triton.url = \"$TRITON_URL\"; flags.Tracking.GNN.Triton.port = ${TRITON_PORT}" \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnTritonValidation' \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --perfmonmt 'fullmonmt' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "CKF_LEGACY_LRT" ]]; then
    WORK_DIR="ckf_legacy_lrt_${ATH_DEV_NAME}_${TRITON_DEV_NAME}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || { echo "Failed to create or change directory to $WORK_DIR"; exit 1; }
    Reco_tf.py --CA 'all:True' \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering doRAWtoALL \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' \
        --preExec "flags.Tracking.doLargeD0=True;" \
        --perfmonmt 'fullmonmt' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4Pixel_ML_TRITON" ]]; then
    WORK_DIR="gnn4pixel_ml_triton_${ATH_DEV_NAME}_${TRITON_DEV_NAME}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || { echo "Failed to create or change directory to $WORK_DIR"; exit 1; }
    FEATURE_NAMES="r,phi,z,cluster_x_1,cluster_y_1,cluster_z_1,charge_count_1,count_1,loc_eta_1,loc_phi_1,glob_eta_1,glob_phi_1,localDir0_1,localDir1_1,localDir2_1"
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preExec "all:flags.ITk.doEndcapEtaNeighbour=True; flags.Tracking.ITkGNNPass.minClusters = [7,7,7]; flags.Tracking.ITkGNNPass.maxHoles = [4,4,2]; flags.Tracking.GNN.usePixelHitsOnly = True; flags.Tracking.GNN.SeedTrackMaker.usePixelWP2=True; flags.Tracking.GNN.Triton.model = \"$TRITON_MODEL_NAME\"; flags.Tracking.GNN.Triton.url = \"$TRITON_URL\"; flags.Tracking.GNN.Triton.port = ${TRITON_PORT}" \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnTritonValidation' \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --perfmonmt 'fullmonmt' \
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
