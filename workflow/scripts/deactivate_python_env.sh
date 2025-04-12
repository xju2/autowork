#!/bin/bash

if [[ -n "$COMMON_SH_INCLUDED" ]]; then return; fi
COMMON_SH_INCLUDED=1

# Strip the venv's influence for this subprocess
if [ -n "$VIRTUAL_ENV" ]; then
    echo "virtual environment detected, deactivating..."
    CLEAN_PATH=$(echo "$PATH" | sed "s|$VIRTUAL_ENV/bin:||")
    export PATH="$CLEAN_PATH"
    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
    hash -r
fi

if [ -n "$CONDA_PREFIX" ]; then
    echo "conda environment detected, deactivating..."
    CLEAN_PATH=$(echo "$PATH" | sed "s|$CONDA_PREFIX/bin:||")
    export PATH="$CLEAN_PATH"
    unset CONDA_PREFIX
    unset CONDA_DEFAULT_ENV
    hash -r
fi
