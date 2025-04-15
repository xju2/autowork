#!/bin/bash

# Default values for arguments
INPUT_FILE=""
OUTPUT_FILE=""
MODE="build"

# Function to display usage
usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i <input_file>   : Input JSON configuration file"
    echo "  -o <output_file>  : Output file for build logs"
    echo "  -m <mode>         : Mode of operation (default: $MODE)"
    exit 1
}

# Parse arguments
while getopts "i:o:m:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        m) MODE="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check for mandatory arguments
if [[ -z "$INPUT_FILE" || -z "$OUTPUT_FILE" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

# Main script logic
echo "Running custom Athena build with the following parameters:"
echo "Input File: $INPUT_FILE"
echo "Output File: $OUTPUT_FILE"
echo "Mode: $MODE"

# mode must be in ["build", "run"]
if [[ "$MODE" != "build" && "$MODE" != "run" ]]; then
    echo "Error: Invalid mode. Must be one of [build, run]."
    exit 1
fi


# Ensure the input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file $INPUT_FILE does not exist."
    exit 1
fi

# Function to extract packages and write to packages.txt
parse_json() {
    local json_file="$1"

    # Ensure jq is installed
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install jq to parse JSON files."
        exit 1
    fi

    # Extract packages from the JSON file
    SOURCE_DIR=$(jq -r '.source_dir' "$json_file")
    RELEASE=$(jq -r '.release' "$json_file")
    PACKAGES=$(jq -r '.packages[]' "$json_file")

        # Validate parsed values
    if [[ -z "$SOURCE_DIR" || -z "$RELEASE" || -z "$PACKAGES" ]]; then
        echo "Error: Failed to parse JSON file or missing required fields."
        exit 1
    fi

    # Print parsed values (optional, for debugging)
    echo "Parsed JSON Configuration:"
    echo "Source Directory: $SOURCE_DIR"
    echo "Release: $RELEASE"
    echo "Packages: $PACKAGES"
}

# Example usage
parse_json "${INPUT_FILE}"

SOURCE_DIR=$(realpath "$SOURCE_DIR")

package_filer_file=${SOURCE_DIR}/package_filters.txt
# loop over the packages and create a package filter file
if [[ -f "$package_filer_file" ]]; then
    echo "Package filter file already exists. Overwriting..."
    rm "$package_filer_file"
fi
echo "Creating package filter file at: $package_filer_file"
for package in ${PACKAGES}; do
    echo "+ $package" >> "$package_filer_file"
done
echo "- .*" >> "$package_filer_file"


cd ${SOURCE_DIR} || { echo "Failed to change directory to $SOURCE_DIR"; exit 1; }

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,${RELEASE},here

if [[ "$MODE" == "build"]]; then
    cmake -B build -S athena/Projects/WorkDir -DATLAS_PACKAGE_FILTER_FILE=../package_filters.txt
    cmake --build build --target install -j 8
else
    # Run the Athena job
    echo "Running Athena job..."
    source build/x*86_64*/setup.sh
    export ATHENA_CORE_NUMBER=8
fi

# Write output log
echo "DONE $(date)"
