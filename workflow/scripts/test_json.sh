#!/bin/bash
INPUT_FILE=""

usage() {
    echo "Usage: $0 -i <input_file>"
    echo "  -i <input_file> : Input JSON file containing configuration"
    exit 1
}

while getopts "i:h" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage exit 1 ;;
    esac
done

INPUT_FILE=$(realpath "$INPUT_FILE")

echo "Running $0 \n $(date) @ $(hostname)"
echo "-----------------------------------"
echo "Input File: $INPUT_FILE"

json_file="$INPUT_FILE"

# parse the JSON file.
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

echo "Source Directory: $SOURCE_DIR"
echo "Release: $RELEASE"
echo "Packages: $PACKAGES"
echo "Executable Commands: $EXE_CMDS"
echo "Athena Repository: $ATHENA_URL"
echo "Athena Reference: $ATHENA_REF"


echo "Executing command: "
while IFS= read -r cmd; do
    echo "$cmd"
    eval "$cmd" || { echo "Error: Validation command failed. $cmd"; exit 1; }
done <<< "${EXE_CMDS}"
