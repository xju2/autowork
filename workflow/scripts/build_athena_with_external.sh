#!/bin/bash

INPUT_FILE=""
OUTPUT_FILE=""
WORKERS=1

usage() {
    echo "Usage: $0 -i <input_file> -o <output_file>"
    echo "  -i <input_file>   : Input JSON configuration file"
    echo "  -o <output_file>  : Output file for build logs"
    echo "  -t <threads>      : Number of threads to use (default: $WORKERS)"
    exit 1
}

while getopts "i:o:t:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        t) WORKERS="$OPTARG" ;;
        *) usage ;;
    esac
done

OUTPUT_FILE=$(realpath "$OUTPUT_FILE")

# Log the parameters
echo "Running $0 \n $(date) @ $(hostname)"
echo "Running Athena build on top of atlasexternal"
echo "Input File: $INPUT_FILE"
echo "Output File: $OUTPUT_FILE"
echo "Number of Threads: $WORKERS"

# deactivate the herited python environment.
source workflow/scripts/deactivate_python_env.sh


source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS

# read the input file to get SOURCE_DIR, ASETUP.
export G4PATH=/cvmfs/atlas-nightlies.cern.ch/repo/sw/main_Athena_x86_64-el9-gcc13-opt/Geant4
export ATLASAuthXML=/global/cfs/cdirs/atlas/xju/data/xml
export PATH=/cvmfs/sft.cern.ch/lcg/contrib/ninja/1.11.1/Linux-x86_64/bin:$PATH

while read -r cmd; do
    echo "Running validation command: $cmd"
    eval "$cmd"
done < "$INPUT_FILE"

echo "Building Athena at $(pwd)"
which python
which gcc

time ./athena/Projects/Athena/build.sh -acmi -t Release \
  -x "-DATLAS_ENABLE_CI_TESTS=TRUE -DATLAS_EXTERNAL=${ATLASAuthXML} -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE" \
  -k "-j ${WORKERS}" 2>&1 || { echo "Error: Athena build failed."; exit 1; }


Athena_VERSION=$(\ls build/install/Athena/)
## write output to a json file.
echo "{" > "$OUTPUT_FILE"
echo "  \"source_dir\": \"${SOURCE_DIR}\"," >> "$OUTPUT_FILE"
echo "  \"release\": \"Athena,${Athena_VERSION} --releasepath=${SOURCE_DIR}/build/install\"" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"
