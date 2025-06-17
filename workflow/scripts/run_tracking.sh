#!/bin/bash

# Default values for arguments
INPUT_FILE=""
OUTFILE=""
NUM_WORKERS=6
MAX_EVENTS=1
CHAINNAME="CKF_LEGACY"
SETUP_FILE=""
TRITON_MODEL_NAME="metriclearning"
TRITON_URL="localhost"

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
    echo "  -u <triton_url>   : Triton URL (default: $TRITON_URL)"
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
        u) TRITON_URL="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage exit 1 ;;
    esac
done

OUTFILE=$(realpath "$OUTFILE")
RUN_DIR=$(dirname "$OUTFILE")
RUN_DIR=$(realpath "$RUN_DIR")

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
echo "Triton URL: $TRITON_URL"

# check if chain name is in
# ["CKF_LEGACY", "GNN4ITk_ML_LOCAL", "GNN4ITK_ML_TRITON"]
if [[ "$CHAINNAME" != "CKF_LEGACY" \
   && "$CHAINNAME" != "GNN4ITk_ML_LOCAL" \
   && "$CHAINNAME" != "GNN4ITk_ML_TRITON" \
   && "$CHAINNAME" != "CKF_LEGACY_LRT" \
   && "$CHAINNAME" != "GNN4ITk_ML_TRITON-DefaultCuts" \
    && "$CHAINNAME" != "GNN4Pixel_ML_TRITON" \
]]; then
    echo "Error: Invalid chain name. Must be one of [CKF_LEGACY, GNN4ITk_ML_LOCAL, GNN4ITk_ML_TRITON, GNN4ITk_ML_TRITON-DefaultCuts, GNN4Pixel_ML_TRITON]."
    exit 1
fi

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

if [ -f "PoolFileCatalog.xml" ]; then
    echo "Cleanup workarea."
    rm InDetIdDict.xml PoolFileCatalog.xml hostnamelookup.tmp eventLoopHeartBeat.txt
fi

DETECTOR_CONDITIONS="all:OFLCOND-MC15c-SDR-14-05"
GEOMETRY_VERSION="all:ATLAS-P2-RUN4-03-00-00"

if [[ "$CHAINNAME" == "CKF_LEGACY" ]]; then
    mkdir ckf_legacy
    cd ckf_legacy || { echo "Failed to create or change directory to ckf_legacy"; exit 1; }
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
    mkdir gnn4itk_ml_local
    cd gnn4itk_ml_local || { echo "Failed to create or change directory to gnn4itk_ml_local"; exit 1; }
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
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4ITk_ML_TRITON" ]]; then
    mkdir gnn4itk_ml_triton
    cd gnn4itk_ml_triton || { echo "Failed to create or change directory to gnn4itk_ml_triton"; exit 1; }
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preExec "all:flags.ITk.doEndcapEtaNeighbour=True; flags.Tracking.ITkGNNPass.minClusters = [7,7,7]; flags.Tracking.ITkGNNPass.maxHoles = [4,4,2]; " \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnTritonValidation' \
        --preExec "flags.Tracking.GNN.Triton.model = \"$TRITON_MODEL_NAME\"; flags.Tracking.GNN.Triton.url = \"$TRITON_URL\";" \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4ITk_ML_TRITON-DefaultCuts" ]]; then
    mkdir gnn4itk_ml_triton-defaultcuts
    cd gnn4itk_ml_triton-defaultcuts || { echo "Failed to create or change directory to gnn4itk_ml_triton-defaultcuts"; exit 1; }
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preExec "all:flags.ITk.doEndcapEtaNeighbour=True;" \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnTritonValidation' \
        --preExec "flags.Tracking.GNN.Triton.model = \"$TRITON_MODEL_NAME\"; flags.Tracking.GNN.Triton.url = \"$TRITON_URL\";" \
        --inputRDOFile "${RDO_FILENAME}" \
        --outputAODFile "${OUTFILE}"  \
        --jobNumber '1' \
        --athenaopts='--loglevel=INFO' \
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "CKF_LEGACY_LRT" ]]; then
    mkdir ckf_legacy_lrt
    cd ckf_legacy_lrt || { echo "Failed to create or change directory to ckf_legacy_lrt"; exit 1; }
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
        --maxEvents ${MAX_EVENTS}
elif [[ "$CHAINNAME" == "GNN4Pixel_ML_TRITON" ]]; then
    mkdir gnn4pixel_ml_triton
    cd gnn4pixel_ml_triton || { echo "Failed to create or change directory to gnn4pixel_ml_triton"; exit 1; }
    FEATURE_NAMES="r,phi,z,cluster_x_1,cluster_y_1,cluster_z_1,charge_count_1,count_1,loc_eta_1,loc_phi_1,glob_eta_1,glob_phi_1,localDir0_1,localDir1_1,localDir2_1"
    Reco_tf.py \
        --CA 'all:True' --autoConfiguration 'everything' \
        --conditionsTag ${DETECTOR_CONDITIONS} \
        --geometryVersion ${GEOMETRY_VERSION} \
        --multithreaded 'True' \
        --steering 'doRAWtoALL' \
        --digiSteeringConf 'StandardInTimeOnlyTruth' \
        --postInclude 'all:PyJobTransforms.UseFrontier' \
        --preExec "all:flags.ITk.doEndcapEtaNeighbour=True; flags.Tracking.ITkGNNPass.minClusters = [7,7,7]; flags.Tracking.ITkGNNPass.maxHoles = [4,4,2]; " \
        --preInclude 'all:Campaigns.PhaseIIPileUp200' 'InDetConfig.ConfigurationHelpers.OnlyTrackingPreInclude' 'InDetGNNTracking.InDetGNNTrackingFlags.gnnTritonValidation' \
        --preExec "flags.Tracking.GNN.usePixelHitsOnly = True; flags.Tracking.GNN.Triton.model = \"$TRITON_MODEL_NAME\"; flags.Tracking.GNN.Triton.url = \"$TRITON_URL\"; flags.Tracking.GNN.Triton.features=\"$FEATURE_NAMES\"; flags.Tracking.GNN.SeedTrackMaker.usePixelWP2=True;" \
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
