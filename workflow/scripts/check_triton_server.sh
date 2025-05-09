#!/bin/bash

INPUT_FILE=""

# Parse arguments
while getopts "i:" opt; do
  case $opt in
    i) INPUT_FILE="$OPTARG" ;;
    *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

INPUT_FILE=$(realpath "$INPUT_FILE")

if [[ -f "$INPUT_FILE" ]]; then
  echo "Input file $INPUT_FILE already exists."
  # now check if the Triton server is running.
  TritonServerName=`cat $INPUT_FILE`
  curl -v ${TritonServerName}:8000/v2/health/ready
  if [[ $? -ne 0 ]]; then
    echo "Triton server ${TritonServerName} is not running."
    echo "remove the $INPUT_FILE file and launch the server"
    rm -f $INPUT_FILE
  else
    echo "Triton server ${TritonServerName} is running. Exiting."
    exit 0
  fi
fi
