#!/bin/bash

uname=$(uname)
if [[ "$uname" != "Darwin" ]]; then
    echo "This script is meant for MacOS only."
    exit 1
fi

if [[ $2 =~ ^[0-9]+$ ]] ; then
    processes=$2
else
    processes=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || sysctl -n hw.ncpu)
fi

export CMAKE_BUILD_PARALLEL_LEVEL=$processes
export OMP_NUM_THREADS=$processes
export OPENBLAS_NUM_THREADS=$processes
export VECLIB_MAXIMUM_THREADS=$processes
export OMP_PROC_BIND=spread
export OMP_PLACES=cores

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
    
    brew install cmake gcc@12 python@3.12 tbb eigen gdal boost cgal libomp

    python3.12 -m pip install virtualenv

    if [ ! -e ${RUNPATH}/venv ]; then
        python3.12 -m virtualenv venv
    fi

    source venv/bin/activate

    requirements_file=$(mktemp)
    grep -v "^gdal\\[numpy\\].*sys_platform == 'darwin'" \
        requirements.txt > "${requirements_file}"
    pip install --ignore-installed -r "${requirements_file}"
    rm -f "${requirements_file}"

    gdal_version=$(gdal-config --version)
    pip install --no-binary gdal "gdal[numpy]==${gdal_version}"
}
    
install() {
    installreqs
    
    echo "Compiling SuperBuild"
    cd ${RUNPATH}/SuperBuild
    mkdir -p build && cd build
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES=arm64
    cmake --build . --parallel $processes

    cd ${RUNPATH}

    echo "Configuration Finished"
}

uninstall() {
    echo "Removing SuperBuild and build directories"
    cd ${RUNPATH}/SuperBuild
    rm -rfv build src download install
    cd ../
    rm -rfv build
}

reinstall() {
    echo "Reinstalling ODX modules"
    uninstall
    install
}

clean() {
    rm -rf \
        ${RUNPATH}/SuperBuild/build \
        ${RUNPATH}/SuperBuild/download \
        ${RUNPATH}/SuperBuild/src

    # find in /code and delete static libraries and intermediate object files
    find ${RUNPATH} -type f -name "*.a" -delete -or -type f -name "*.o" -delete
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
    echo "[nproc] is an optional argument that can set the number of processes for the make -j tag. By default it uses $(nproc)"
}

if [[ $1 =~ ^(install|reinstall|uninstall|installreqs|clean)$ ]]; then
    RUNPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    "$1"
else
    echo "Invalid instructions." >&2
    usage
    exit 1
fi
