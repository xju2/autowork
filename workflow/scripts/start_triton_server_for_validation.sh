#!/bin/bash

INPUT_FILE=""
OUTPUT=""

# Parse arguments
while getopts "i:o:" opt; do
  case $opt in
    i) INPUT_FILE="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

INPUT_FILE=$(realpath "$INPUT_FILE")
OUTPUT=$(realpath "$OUTPUT")

echo "Running $0"
echo "$(date) $(hostname)"
echo "Input File: $INPUT_FILE"
echo "Output File: $OUTPUT"

if [[ -z "$INPUT_FILE" || -z "$OUTPUT" ]]; then
  echo "Error: Missing required arguments."
  echo "Usage: $0 -i <input_file> -o <output_file>"
  exit 1
fi

# Check if the input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: Input file $INPUT_FILE does not exist."
  exit 1
fi

# Check if the output file exists
if [[ -f "$OUTPUT" ]]; then
  echo "Output file $OUTPUT already exists."
  # now check if the Triton server is runnning.
  TritonServerName=`cat $OUPUT`
  curl -v ${TritonServerName}:8000/v2/health/ready
  if [[ $? -ne 0 ]]; then
    echo "Triton server is not running."
    echo "remove the $OUTPUT file and launch the server"
    rm -f $OUTPUT
  else
    echo "Triton server is running. Exiting."
    exit 0
  fi
fi

# parse the input json file.
SOURCE_DIR=$(jq -r '.source_dir' "$INPUT_FILE")
REPO_URL=$(jq -r '.repo_url' "$INPUT_FILE")

echo "Start Triton Server for validation"
echo "SOURCE_DIR: $SOURCE_DIR"
echo "OUTPUT: $OUTPUT"
echo "REPO_URL: $REPO_URL"
echo "SOURCE_DIR: $SOURCE_DIR"


cd ${SOURCE_DIR} || { echo "Failed to change directory to $SOURCE_DIR"; exit 1; }

REPO_NAME=$(basename "$REPO_URL" .git)

if [[ ! -d "$REPO_NAME" ]]; then
  echo "Cloning repository $REPO_URL into $SOURCE_DIR"
  git clone "$REPO_URL" "$REPO_NAME"
fi
cd "$REPO_NAME" || { echo "Failed to change directory to $REPO_NAME"; exit 1; }

srun -C gpu -N 1 -G 1 -c 10 -n 1 -t 4:00:00 -A m3443 \
  -q interactive /bin/bash -c "./scripts/start-tritonserver.sh -o $OUTPUT " &

# wait for the Triton server to start.
sleep 30