#!/bin/bash

cd $SOURCEDIR || { echo "Failed to change directory to $SOURCEDIR"; exit 1; }

git clone ssh://git@gitlab.cern.ch:7999/xju/athena.git --single-branch && cd athena 


git remote add atlas https://gitlab.cern.ch/atlas/athena.git
git fetch atlas
git checkout -b atlas_main atlas/main

source /global/cfs/cdirs/atlas/scripts/setupATLAS.sh
setupATLAS

asetup Athena,main,here,latest

ATHENA_LOC=$(which athena)

cp $(dirname ${ATHENA_LOC})/../python/AthExOnnxRuntime/AthExOnnxRuntime_test_infer.py .

athena --CA AthExOnnxRuntime_test_infer.py

