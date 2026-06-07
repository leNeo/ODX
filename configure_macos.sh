#!/bin/bash

set -euo pipefail

uname_s="$(uname -s)"
if [[ "${uname_s}" != "Darwin" ]]; then
    echo "This script is meant for MacOS only."
    exit 1
fi

if [[ "${2:-}" =~ ^[0-9]+$ ]] ; then
    processes="${2}"
else
    processes=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || sysctl -n hw.ncpu)
fi

export CMAKE_BUILD_PARALLEL_LEVEL="${processes}"
export OMP_NUM_THREADS="${processes}"
export OPENBLAS_NUM_THREADS="${processes}"
export VECLIB_MAXIMUM_THREADS="${processes}"
export OMP_PROC_BIND=spread
export OMP_PLACES=cores
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++

ensure_prereqs() {
    export DEBIAN_FRONTEND=noninteractive

    if ! command -v xcodebuild &> /dev/null; then
        echo "You need to install Xcode first. Go to the App Store and download Xcode"
        exit 1
    fi

    if ! command -v brew &> /dev/null; then
        echo "You need to install Homebrew first. https://brew.sh/"
        exit 1
    fi

}

installreqs() {
    ensure_prereqs
    
    brew install cmake python@3.12 tbb eigen gdal boost cgal libomp

    export OpenMP_ROOT
    OpenMP_ROOT="$(brew --prefix libomp)"

    # Homebrew Python is externally managed (PEP 668), so install every
    # Python dependency in ODX's own virtual environment.
    python3.12 -m venv "${RUNPATH}/venv"
    venv_python="${RUNPATH}/venv/bin/python3"
    "${venv_python}" -m pip install --upgrade pip setuptools wheel

    requirements_file=$(mktemp)
    trap 'rm -f "${requirements_file}"' EXIT
    grep -v "^gdal\\[numpy\\].*sys_platform == 'darwin'" \
        "${RUNPATH}/requirements.txt" > "${requirements_file}"
    "${venv_python}" -m pip install --ignore-installed -r "${requirements_file}"
    rm -f "${requirements_file}"
    trap - EXIT

    gdal_version=$(gdal-config --version)
    "${venv_python}" -m pip install --no-binary gdal "gdal[numpy]==${gdal_version}"
}
    
install() {
    installreqs

    if [[ -d "${RUNPATH}/SuperBuild/build" ]] &&
        grep -Rqs "gcc-12" "${RUNPATH}/SuperBuild/build"; then
        echo "Removing build products created with the incompatible Homebrew GCC compiler"
        rm -rf \
            "${RUNPATH}/SuperBuild/build" \
            "${RUNPATH}/SuperBuild/install"
    fi
    
    echo "Compiling SuperBuild"
    cd "${RUNPATH}/SuperBuild"
    mkdir -p build
    cd build
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_C_COMPILER="${CC}" \
        -DCMAKE_CXX_COMPILER="${CXX}"
    cmake --build . --parallel "${processes}"

    cd "${RUNPATH}"

    echo "Configuration Finished"
}

uninstall() {
    echo "Removing SuperBuild and build directories"
    cd "${RUNPATH}/SuperBuild"
    rm -rfv build src download install
    cd ..
    rm -rfv build
}

reinstall() {
    echo "Reinstalling ODX modules"
    uninstall
    install
}

clean() {
    rm -rf \
        "${RUNPATH}/SuperBuild/build" \
        "${RUNPATH}/SuperBuild/download" \
        "${RUNPATH}/SuperBuild/src"

    # find in /code and delete static libraries and intermediate object files
    find "${RUNPATH}" -type f -name "*.a" -delete -or -type f -name "*.o" -delete
}

usage() {
    echo "Usage:"
    echo "bash configure.sh <install|update|uninstall|installreqs|help> [nproc]"
    echo "Subcommands:"
    echo "  install"
    echo "    Installs all dependencies and modules for running OpenDroneMap"
    echo "  reinstall"
    echo "    Removes SuperBuild and build modules, then re-installs them. Note this does not update OpenDroneMap to the latest version. "
    echo "  uninstall"
    echo "    Removes SuperBuild and build modules. Does not uninstall dependencies"
    echo "  installreqs"
    echo "    Only installs the requirements (does not build SuperBuild)"
    echo "  clean"
    echo "    Cleans the SuperBuild directory by removing temporary files. "
    echo "  help"
    echo "    Displays this message"
    echo "[nproc] optionally sets the number of parallel build processes."
}

if [[ "${1:-}" =~ ^(install|reinstall|uninstall|installreqs|clean)$ ]]; then
    RUNPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    "${1}"
else
    echo "Invalid instructions." >&2
    usage
    exit 1
fi
