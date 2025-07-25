#!/bin/bash

# Default values for arguments
INPUT_FILE=""
OUTPUT_FILE=""
MODE="build"
WORKERS=1
SETUP_FILE=""

# Function to display usage
usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i <input_file>   : Input JSON configuration file"
    echo "  -o <output_file>  : Output file for build logs"
    echo "  -m <mode>         : Mode of operation (default: $MODE)"
    echo "  -t <threads>      : Number of threads to use (default: $WORKERS)"
    echo "  -s <setup_file>   : Setup file (default: $SETUP_FILE)"
    exit 1
}

# Parse arguments
while getopts "i:o:m:t:s:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        m) MODE="$OPTARG" ;;
        t) WORKERS="$OPTARG" ;;
        s) SETUP_FILE="$OPTARG" ;;
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
echo "Running $0 \n $(date) @ $(hostname)"
echo "Running custom Athena build with the following parameters:"
echo "Input File: $INPUT_FILE"
echo "Output File: $OUTPUT_FILE"
echo "Mode: $MODE"
echo "Number of Threads: $WORKERS"
echo "Setup File: $SETUP_FILE"

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
    EXE_CMDS=$(jq -r '
        .exe_cmd[] |
        if type == "string" then
            .
        else
            join(" ")
        end
        ' "$json_file")

    # Athena Repository URL and reference
    ATHENA_URL=$(jq -r '.athena_repository' "$json_file")
    ATHENA_REF=$(jq -r '.athena_tag' "$json_file")

    # atlasexternal related variables
    EXTERNAL_URL=$(jq -r '.external_url' "$json_file")
    EXTERNAL_REF=$(jq -r '.external_ref' "$json_file")
    EXCMAKEARGS=$(jq -r '.extra_cmake_args' "$json_file")
    EXTERNAL_ASETUP=$(jq -r '.external_asetup' "$json_file")
}

fetch_athena_repo() {
    local repo="$1"
    local tag="$2"
    local src_dir="$3"

    if ! command -v git &>/dev/null; then
        echo "Error: git is required but not installed."
        exit 1
    fi

    if [[ -z "$repo" || -z "$tag" || -z "$src_dir" ]]; then
        echo "Error: fetch_athena_repo missing arguments."
        exit 1
    fi

    if [[ ! -d "$src_dir/.git" ]]; then
        echo "Cloning Athena repository...${src_dir}"
        git clone "$repo" "$src_dir"
        cd "$src_dir"
        echo "Checking out tag/branch: $tag"
        git checkout "$tag"
    else
        echo "Athena repository already exists."
        cd "$src_dir"
    fi

    if [[ -f .gitmodules ]]; then
        echo "Updating submodules..."
        git submodule update --init --recursive
    fi

    cd - >/dev/null
}

# Example usage
parse_json "${INPUT_FILE}"

# deactivate the herited python environment.
source workflow/scripts/deactivate_python_env.sh

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
export PATH=/cvmfs/sft.cern.ch/lcg/contrib/ninja/1.11.1/Linux-x86_64/bin:$PATH

# ! only after parsing the input JSON file.
# ! do not change the location of this line.
if [[ -f "$SETUP_FILE" ]]; then
    SETUP_FILE=$(realpath "$SETUP_FILE")
    echo "Set up environment from $SETUP_FILE"
    SOURCE_DIR=$(jq -r '.source_dir' "$SETUP_FILE")
    RELEASE=$(jq -r '.release' "$SETUP_FILE")
fi

SOURCE_DIR=$(realpath "$SOURCE_DIR")
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Source directory $SOURCE_DIR does not exist."
    echo "Creating directory $SOURCE_DIR"
    mkdir -p "$SOURCE_DIR" || { echo "Failed to create directory $SOURCE_DIR"; exit 1; }
fi
cd ${SOURCE_DIR} || { echo "Failed to change directory to $SOURCE_DIR"; exit 1; }

SPARSE_BUILD_DIR="sparse_build"

if [[ "$MODE" == "build_athena" ]]; then

    # Fetch Athena repository only at build_athena stage
    fetch_athena_repo "$ATHENA_URL" "$ATHENA_REF" "athena"

    # check if SETUP_FILE is provided.
    # If so, setup the source_dir and athena environment from there.
    echo "{" > "$OUTPUT_FILE"
    echo "  \"source_dir\": \"${SOURCE_DIR}\"," >> "$OUTPUT_FILE"
    echo "  \"release\": \"${RELEASE}\"," >> "$OUTPUT_FILE"

    asetup ${RELEASE}

    echo "Building customized Athena in $SOURCE_DIR"
    echo "Original athena: $(which athena)"

    # check if required variables are in the json file
    if [[ -z "$PACKAGES" ]]; then
        echo "Error: Missing required fields in the JSON file."
        exit 1
    fi

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

    cmake -B ${SPARSE_BUILD_DIR} -S athena/Projects/WorkDir -DATLAS_PACKAGE_FILTER_FILE=./package_filters.txt -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE || { echo "Error: CMake configuration failed."; exit 1; }
    cmake --build ${SPARSE_BUILD_DIR} -- -j ${WORKERS} || { echo "Error: CMake build failed."; exit 1; }

    echo "  \"local_setup\": \"${SPARSE_BUILD_DIR}/x86_64-el9-gcc*-opt/setup.sh\"" >> "${OUTPUT_FILE}"
    echo "}" >> "$OUTPUT_FILE"

elif [[ "$MODE" == "run_athena" ]]; then

    echo "Running Athena in $SOURCE_DIR"
    # check if required variables are in the json file
    if [[ -z "$RELEASE" || -z "$EXE_CMDS" ]]; then
        echo "Error: Missing required fields in the JSON file."
        exit 1
    fi

    # Run the Athena job
    asetup ${RELEASE}
    echo "Using athena from: $(which athena)"

    if [[ -d ${SPARSE_BUILD_DIR} ]]; then
        echo "Sparse build directory exists. Using it."
        source ${SPARSE_BUILD_DIR}/x86_64-el9-gcc*-opt/setup.sh
    fi
    export ATHENA_CORE_NUMBER=${WORKERS}

    echo "Executing command: " > "${OUTPUT_FILE}"
    while IFS= read -r cmd; do
        echo "Running: $cmd"
        eval "$cmd" || { echo "Error: Validation command failed."; exit 1; }
        echo $cmd >> "${OUTPUT_FILE}"
    done <<< "${EXE_CMDS}"

    # append all log.* files to the log file.
    echo "Appending athena logs"
    for log_file in log.*; do
        echo "+++ $log_file"
        cat "$log_file"
    done

    echo "DONE." >> "${OUTPUT_FILE}"

elif [[ "$MODE" == "build_external" ]]; then
    echo "Building atlasexternals in $SOURCE_DIR"
    # check if required variables are in the json file
    if [[ -z "$EXTERNAL_URL" || -z "$EXTERNAL_REF" ]]; then
        echo "Error: Missing required fields in the JSON file."
        exit 1
    fi
    # check if athena directory is there.
    if [[ ! -d "athena" ]]; then
        echo "Error: athena directory does not exist."
        echo "Checkout the latest ATLAS athena code from git."
        echo "and create a new branch."
        git clone ssh://git@gitlab.cern.ch:7999/atlas/athena.git --single-branch
        cd athena
        git branch debug_main
        git checkout debug_main
        cd ..
    fi


    asetup ${EXTERNAL_ASETUP}
    echo "Using athena from: $(which athena)"
    export AtlasExternals_URL=$EXTERNAL_URL
    export AtlasExternals_REF=$EXTERNAL_REF

    export G4PATH=/cvmfs/atlas-nightlies.cern.ch/repo/sw/main_Athena_x86_64-el9-gcc13-opt/Geant4

    time ./athena/Projects/Athena/build_externals.sh -i -t Release \
      -x "${EXCMAKEARGS}" \
      -k "-j ${WORKERS}" 2>&1

    echo "{" > "$OUTPUT_FILE"
    echo "  \"source_dir\": \"${SOURCE_DIR}\"," >> "$OUTPUT_FILE"
    echo "  \"release\": \"${EXTERNAL_ASETUP}\"" >> "$OUTPUT_FILE"
    echo "}" >> "$OUTPUT_FILE"

elif [[ "$MODE" == "build_external_athena" ]]; then

    echo "Building athena on top of atlasexternals in $SOURCE_DIR"
    time ./athena/Projects/Athena/build.sh -acmi \
      -x "-DATLAS_ENABLE_CI_TESTS=TRUE -DATLAS_EXTERNAL=${ATLASAuthXML} -DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE -G Ninja" \
      -k "-j ${WORKERS}" 2>&1 || { echo "Error: Athena build failed."; exit 1; }

    Athena_VERSION=$(\ls build/install/Athena/)
    ## write output to a json file.
    echo "{" > "$OUTPUT_FILE"
    echo "  \"source_dir\": \"${SOURCE_DIR}\"," >> "$OUTPUT_FILE"
    echo "  \"release\": \"Athena,${Athena_VERSION} --releasepath=${SOURCE_DIR}/build/install\"" >> "$OUTPUT_FILE"
    echo "}" >> "$OUTPUT_FILE"

else
    echo "Error: Invalid mode. Must be one of [build_athena, run_athena, build_external, build_external_athena]."
    exit 1
fi

echo "DONE on $(date +%Y-%m-%dT%H:%M:%S)"
