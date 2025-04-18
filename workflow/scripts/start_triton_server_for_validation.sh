#!/bin/bash

# Parse arguments
while getopts "o:d:" opt; do
  case $opt in
    d) SOURCE_DIR="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

OUTPUT=$(realpath "$OUTPUT")

echo "Start Triton Server for validation"
echo "on $(date)"
echo "SOURCE_DIR: $SOURCE_DIR"
echo "OUTPUT: $OUTPUT"


cd ${SOURCE_DIR} || { echo "Failed to change directory to $SOURCE_DIR"; exit 1; }

[[ -d "validate_triton_client" ]] || \
    git clone https://github.com/xju2/validate_triton_client.git

cd validate_triton_client

touch $OUTPUT
srun -C gpu -N 1 -G 1 -c 10 -t 4:00:00 -A m3443 -q interactive /bin/bash -c "./scripts/start-tritonserver.sh -o $OUTPUT " &
