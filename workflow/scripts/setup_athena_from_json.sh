#!/bin/bash

# Function to compute source directory from worktree configuration or fallback to source_dir
compute_source_dir() {
    local worktree_base_dir="$1"
    local worktree_name="$2"
    local fallback_source_dir="$3"
    
    if [[ -n "$worktree_base_dir" && -n "$worktree_name" ]]; then
        # Use worktree configuration
        echo "$(realpath "$worktree_base_dir")/$worktree_name"
    else
        # Use fallback source_dir
        echo "$fallback_source_dir"
    fi
}

setup_athena_from_json() {
    local input_file="$1"
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file $input_file does not exist."
        exit 1
    fi
    echo "Setup Athena from JSON file: $input_file"
    CURRENT_LOC=$(realpath $(pwd))
    echo "Current directory: $CURRENT_LOC"
    
    # Parse both traditional and worktree configuration
    SOURCE_DIR=$(jq -r '.source_dir // empty' "$input_file")
    RELEASE=$(jq -r '.release' "$input_file")
    LOCAL_SETUP=$(jq -r '.local_setup' "$input_file")
    
    # Parse worktree configuration
    WORKTREE_BASE_DIR=$(jq -r '.worktree_base_dir // empty' "$input_file")
    WORKTREE_NAME=$(jq -r '.worktree_name // empty' "$input_file")
    
    # Compute actual source directory
    SOURCE_DIR=$(compute_source_dir "$WORKTREE_BASE_DIR" "$WORKTREE_NAME" "$SOURCE_DIR")

    if [[ -z "$SOURCE_DIR" || -z "$RELEASE" ]]; then
        echo "Error: Missing source_dir/worktree configuration or release in JSON file."
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
