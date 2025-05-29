#!/bin/bash
set -eo pipefail  # -e to exit on error, -o pipefail to catch errors in pipelines

# Default values for arguments
INPUT_FILES=()
OUTFILE=""

usage() {
    echo "Usage: $0 -i <input_files>"
    echo "  -i <input_files> : Comma-separated list of input files (e.g., RDO file list)"
    echo "  -o <output_file> : Output file (optional)"
    echo "  -h               : Display this help message"
    exit 1
}

# Parse arguments
while getopts "i:o:h" opt; do
    case $opt in
        i) INPUT_FILES=(${OPTARG//,/ }) ;;
        o) OUTFILE="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage exit 1 ;;
    esac
done

OUTFILE=$(realpath "$OUTFILE")


echo "Running $0 \n $(date) @ $(hostname)"
echo "-----------------------------------"
echo "Output File: $OUTFILE"
echo "Python path: $(which python)"
echo "Python version: $(python --version)"

# loop over all files.
for idx in ${!INPUT_FILES[@]}
do
    IN_FILE=$(realpath "${INPUT_FILES[$idx]}")
    INPUT_FILES[$idx]=$IN_FILE
    echo "Input File $idx: ${INPUT_FILES[$idx]}"
done

# check if run_vroot is available
# in the external_packages directory.
if [ ! -d "external_packages/root_plot_utils" ] || [ -z "$(which run_vroot)" ]; then
    echo "run_vroot not found, installing..."
    if [ ! -d "external_packages/root_plot_utils" ]; then
        git clone git@github.com:xju2/root_plot_utils.git external_packages/root_plot_utils
    fi

    cd external_packages/root_plot_utils
    git checkout v1.1.2
    pip install -e .
fi
echo "run_vroot path: $(which run_vroot)"

sampleName=$(basename "${INPUT_FILES[0]}" | awk -F. '{print $7}')
IDPVM_MODE=$(basename "${INPUT_FILES[0]}" | awk -F. '{print $3}')
OUTDIR=$(dirname "${INPUT_FILES[0]}")/comparison
mkdir -p "$OUTDIR"

echo "Sample Name: $sampleName"
echo "IDPVM Mode: $IDPVM_MODE"

# define a dictionary for sample labels.
declare -A sampleLabels
sampleLabels=(
    ["ttbarPU0"]="t#bar{t}, <#mu> = 0, ${IDPVM_MODE}"
    ["ttbarPU200"]="t#bar{t}, <#mu> = 200, ${IDPVM_MODE}"
    ["ZmumuPU0"]="Z/#mu#mu, <#mu> = 0, ${IDPVM_MODE}"
    ["ZmumuPU200"]="Z/#mu#mu, <#mu> = 200, ${IDPVM_MODE}"
    ["MuonPU0"]="#mu, <#mu> = 0, ${IDPVM_MODE}"
    ["ElectronPU0"]="e, <#mu> = 0, ${IDPVM_MODE}"
    ["PionPU0"]="#pi, <#mu> = 0, ${IDPVM_MODE}"
)



COMMAND_OPTS=(
    task_name=gnn4itk
    task=compare_two_files
    task.reference_file.path="${INPUT_FILES[0]}"
    task.reference_file.name=main
    task.comparator_file.path="${INPUT_FILES[1]}"
    task.comparator_file.name="GNN w/ Metric Learning"
    "histograms=glob(rel24_idpvm*)"
    "canvas.other_label.text='#sqrt{s} = 14 TeV, ${sampleLabels[${sampleName}]}, Hard Scatter'"
    canvas.otypes=png,pdf
    task.outdir=${OUTDIR}
)

echo -e "run_vroot -m \"${COMMAND_OPTS[*]}\""

run_vroot -m "${COMMAND_OPTS[@]}"

echo "$OUTDIR" > "$OUTFILE"
echo "DONE $(date +%Y-%m-%dT%H:%M:%S)"