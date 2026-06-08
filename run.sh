#!/bin/bash

set -e

RUNPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -d "${RUNPATH}/venv" ]; then
    source "${RUNPATH}/venv/bin/activate"
fi
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${RUNPATH}/SuperBuild/install/lib"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:+${DYLD_LIBRARY_PATH}:}${RUNPATH}/SuperBuild/install/lib"
exec python3 "${RUNPATH}/run.py" "$@"
