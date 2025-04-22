#!/bin/bash

# Default values for arguments
INPUT_FILE=""
OUTPUT_FILE=""
MODE="build"
WORKERS=16

# Function to display usage
usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i <input_file>   : Input JSON configuration file"
    echo "  -o <output_file>  : Output file for build logs"
    echo "  -m <mode>         : Mode of operation (default: $MODE)"
    echo "  -t <threads>      : Number of threads to use (default: $WORKERS)"
    exit 1
}

# Parse arguments
while getopts "i:o:m:t:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        m) MODE="$OPTARG" ;;
        t) WORKERS="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check for mandatory arguments
if [[ -z "$INPUT_FILE" || -z "$OUTPUT_FILE" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

OUTPUT_FILE=$(realpath "$OUTPUT_FILE")
# Main script logic
echo "Running custom Athena build with the following parameters:"
echo "Input File: $INPUT_FILE"
echo "Output File: $OUTPUT_FILE"
echo "Mode: $MODE"
echo "Number of Threads: $WORKERS"

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
    VALIDATION=$(jq -r '.validation_cmd[]' "$json_file")

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

# deactivate the herited python environment.
source workflow/scripts/deactivate_python_env.sh


cd ${SOURCE_DIR} || { echo "Failed to change directory to $SOURCE_DIR"; exit 1; }

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,${RELEASE},here

which python
export PATH=/cvmfs/sft.cern.ch/lcg/contrib/ninja/1.11.1/Linux-x86_64/bin:$PATH

if [[ "$MODE" == "build" ]]; then
    cmake -B build -S athena/Projects/WorkDir -DATLAS_PACKAGE_FILTER_FILE=./package_filters.txt -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE || { echo "Error: CMake configuration failed."; exit 1; }
    cmake --build build -- -j ${WORKERS} || { echo "Error: CMake build failed."; exit 1; }
else

    # Run the Athena job
    source build/x86_64-el9-gcc*-opt/setup.sh
    export ATHENA_CORE_NUMBER=${WORKERS}

    mkdir run
    cd run
    echo "Running Athena job $(realpath run)"
    while IFS= read -r validation; do
        echo "Running validation command: $validation"
        eval "$validation" || { echo "Error: Validation command failed."; exit 1; }
    done <<< "${VALIDATION}"
fi

# Write output log
echo "DONE $(date)" > "$OUTPUT_FILE"
