#!/bin/bash

setup_athena_from_json() {
    local input_file="$1"
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file $input_file does not exist."
        exit 1
    fi
    echo "Setup Athena from JSON file: $input_file"
    CURRENT_LOC=$(realpath $(pwd))
    echo "Current directory: $CURRENT_LOC"
    SOURCE_DIR=$(jq -r '.source_dir' "$input_file")
    RELEASE=$(jq -r '.release' "$input_file")
    LOCAL_SETUP=$(jq -r '.local_setup' "$input_file")

    if [[ -z "$SOURCE_DIR" || -z "$RELEASE" ]]; then
        echo "Error: Missing source_dir or release in JSON file."
        exit 1
    fi
    echo "Move to $SOURCE_DIR and setup Athena $RELEASE."
    SOURCE_DIR=$(realpath "$SOURCE_DIR")
    cd ${SOURCE_DIR} || { echo "Failed to change directory to $SOURCE_DIR"; exit 1; }
    asetup ${RELEASE}

    echo "$(which athena)"

    if [[ ! -z "$LOCAL_SETUP" ]]; then
        echo "Setting up local environment from $LOCAL_SETUP"
        source $(\ls $LOCAL_SETUP)
    fi
    echo "Athena environment set up successfully."
    cd ${CURRENT_LOC}
    echo "Returned to original directory: $(pwd)"
}
