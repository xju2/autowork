#!/usr/bin/env bash

SOURCEDIR=$(pwd)
OUTFILE="build.log"
NWORKERS=32

HELP_MSG="Usage: $0 [-d source_directory] [-o output_file] [-j nworkers]"

while getopts ":d:o:j:" opt; do
  case ${opt} in
    d )
      SOURCEDIR=$OPTARG
      ;;
    o )
      OUTFILE=$OPTARG
      ;;
    j )
        NWORKERS=$OPTARG
        ;;
    \? )
      echo $HELP_MSG
      exit 1
      ;;
  esac
done

OUTFILE=$(realpath "$OUTFILE")

## log the parameters...
echo "Running $0 on $(date) @ $(hostname)" > $OUTFILE
echo "-----------------------------------" >> $OUTFILE
echo "Output file: ${OUTFILE}" >> $OUTFILE
echo "Source directory: ${SOURCEDIR}" >> $OUTFILE
echo "NWORKERS: ${NWORKERS}" >> $OUTFILE


cd $SOURCEDIR || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS
asetup Athena,main,here,latest

CUDACXX=/usr/local/cuda/bin/nvcc cmake -S traccc-athena -B build -DCMAKE_CUDA_ARCHITECTURES=80
cmake --build build -- -j $NWORKERS

echo "-----------------------------------" >> $OUTFILE
echo "Date: $(date)" >> $OUTFILE
