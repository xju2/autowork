#!/bin/bash

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
        i) INPUT_FILES="$OPTARG" ;;
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
for IN_FILE in ${INPUT_FILES[@]}
do
    echo "Input File: $IN_FILE"
done

# check if root_plot_utils is available
# in the external_packages directory.
if [ ! -d external_packages/root_plot_utils ]; then
    echo "root_plot_utils not found, installing..."
    git clone git@github.com:xju2/root_plot_utils.git external_packages/root_plot_utils
    cd external_packages/root_plot_utils
    git checkout v1.1.1
    pip install .
fi
echo "run_vroot path: $(which run_vroot)"

COMMAND_OPTS=""

# run_vroot -m \
#   task_name=gnn4itk task=compare_two_files ${COMMAND_OPTS}

#   task.reference_file.path=data/gnn4itk/idpvm.ckf.${IDPVM_MODE}.local.gnn4itkTriton.none.${sampleName}.root \
#   task.reference_file.name=main \
#   task.comparator_file.path=data/gnn4itk/idpvm.gnn4itkML.${IDPVM_MODE}.triton.gnn4itkTriton.tracking.${sampleName}.root \
#   task.comparator_file.name="GNN w/ Metric Learning" \
#   "histograms=glob(rel24_idpvm*)" \
#   "canvas.other_label.text='#sqrt{s} = 14 TeV, ${sampleLabel}'" \
#   canvas.otypes=png,pdf

# touch $OUTFILE

echo "DONE $(date +%Y-%m-%dT%H:%M:%S)"