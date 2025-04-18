#!/bin/bash

# Parse arguments
while getopts "c:k:t:o:d:i:" opt; do
  case $opt in
    c) TRITON_COMMON_VERSION="$OPTARG" ;;
    k) TRITON_CORE_VERSION="$OPTARG" ;;
    t) CLIENT_VERSION="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    d) SOURCEDIR="$OPTARG" ;;
    i) INPUTFILE="$OPTARG" ;;
    *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

INPUTFILE=$(realpath "$INPUTFILE")
OUTPUT=$(realpath "$OUTPUT")

if [ -f "$INPUTFILE" ]; then
  echo "Input file: $INPUTFILE"
else
  echo "Input file not found: $INPUTFILE"
  exit 1
fi
SERVER_URL=`cat $INPUTFILE`

# Ensure all required arguments are provided
if [[ -z "$TRITON_COMMON_VERSION" || -z "$TRITON_CORE_VERSION" || -z "$CLIENT_VERSION" || -z "$OUTPUT" ]]; then
  echo "Usage: $0 -c <triton_common_version> -k <triton_core_version> -t <client_version> -o <output> -d <SOURCEDIR>"
  exit 1
fi

NUM_JOBS=8

echo "Start valiating Triton on $(date)"
echo "Number of jobs: $NUM_JOBS"
echo "Output: $OUTPUT"
echo "SOURCEDIR: $SOURCEDIR"
echo "SERVER_URL: $SERVER_URL"

source workflow/scripts/deactivate_python_env.sh

cd "$SOURCEDIR" || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS

source /cvmfs/sft.cern.ch/lcg/views/dev3/latest/x86_64-el9-gcc13-opt/setup.sh

wget https://github.com/triton-inference-server/client/archive/refs/heads/${CLIENT_VERSION}.tar.gz
tar -xzf ${CLIENT_VERSION}.tar.gz

cd client-${CLIENT_VERSION}
cmake -B build -S src/c++ \
     -DBUILD_SHARED_LIBS=ON \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_CXX_STANDARD=20 \
     -DCMAKE_INSTALL_PREFIX=${PWD}/install \
     -DTRITON_ENABLE_CC_GRPC=ON \
     -DTRITON_ENABLE_CC_HTTP=OFF \
     -DTRITON_ENABLE_TESTS=OFF \
     -DTRITON_ENABLE_ZLIB=OFF \
     -DTRITON_USE_THIRD_PARTY=OFF \
     -DTRITON_REPO_ORGANIZATION=https://github.com/triton-inference-server \
     -DTRITON_KEEP_TYPEINFO=ON

cmake --build build --target install -- -j $NUM_JOBS
if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

echo "DONE Building on $(date)"

cd $SOURCEDIR
if [ ! -d "validate_triton_client" ]; then
    git clone https://github.com/xju2/validate_triton_client.git
fi

cd validate_triton_client
cmake -B build -S src -DCMAKE_INSTALL_PREFIX=${SOURCEDIR}/client-${CLIENT_VERSION}/install
cmake --build build --target install -- -j $NUM_JOBS
if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi
echo "DONE Building validate_triton_client on $(date)"

# run the validation.
./build/bin/test_resnet50  -u "${SERVER_URL}:8001" -i models/resnet50/img1.txt

touch $OUTPUT
