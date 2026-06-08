cmake_minimum_required(VERSION 3.28)

project(ODX-SuperBuild)

# Setup SuperBuild root location
set(SB_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})

if (NOT CMAKE_BUILD_TYPE)
    message(STATUS "No build type selected, default to Release")
    set(CMAKE_BUILD_TYPE "Release")
endif()

if (WIN32)
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "" FORCE)
endif()

if (APPLE)
    find_program(HOMEBREW_EXECUTABLE brew)
    mark_as_advanced(FORCE HOMEBREW_EXECUTABLE)
    if (HOMEBREW_EXECUTABLE)
        # Detected a Homebrew install, query for its install prefix.
        execute_process(COMMAND ${HOMEBREW_EXECUTABLE} --prefix
            OUTPUT_VARIABLE HOMEBREW_INSTALL_PREFIX
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        message(STATUS "Detected Homebrew with install prefix: "
            "${HOMEBREW_INSTALL_PREFIX}, adding to CMake search paths.")
        list(APPEND CMAKE_PREFIX_PATH "${HOMEBREW_INSTALL_PREFIX}")
    endif()

    # AppleClang links against the active macOS SDK correctly. Homebrew GCC
    # can fail to find libSystem when used with newer Xcode SDKs.
    find_program(APPLE_C_COMPILER clang REQUIRED PATHS /usr/bin NO_DEFAULT_PATH)
    find_program(APPLE_CXX_COMPILER clang++ REQUIRED PATHS /usr/bin NO_DEFAULT_PATH)
    set(APPLE_OPENMP_ROOT "${HOMEBREW_INSTALL_PREFIX}/opt/libomp")
    set(APPLE_CMAKE_ARGS
        "-DCMAKE_C_COMPILER=${APPLE_C_COMPILER}"
        "-DCMAKE_CXX_COMPILER=${APPLE_CXX_COMPILER}"
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    )
    message(STATUS "Using AppleClang: ${APPLE_C_COMPILER}, ${APPLE_CXX_COMPILER}")

    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
        list(APPEND APPLE_CMAKE_ARGS
            "-DCMAKE_OSX_ARCHITECTURES=arm64"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_C_FLAGS_RELEASE=-O3 -mcpu=native -DNDEBUG"
            "-DCMAKE_CXX_FLAGS_RELEASE=-O3 -mcpu=native -DNDEBUG"
        )
        message(STATUS "Enabling native Apple Silicon release optimizations")
    endif()

    set(APPLE_OPENMP_CMAKE_ARGS
        ${APPLE_CMAKE_ARGS}
        "-DOpenMP_ROOT=${APPLE_OPENMP_ROOT}"
        "-DOpenMP_C_FLAGS=-Xclang -fopenmp"
        "-DOpenMP_CXX_FLAGS=-Xclang -fopenmp"
        "-DOpenMP_C_LIB_NAMES=libomp"
        "-DOpenMP_CXX_LIB_NAMES=libomp"
        "-DOpenMP_C_INCLUDE_DIR=${APPLE_OPENMP_ROOT}/include"
        "-DOpenMP_CXX_INCLUDE_DIR=${APPLE_OPENMP_ROOT}/include"
        "-DOpenMP_libomp_LIBRARY=${APPLE_OPENMP_ROOT}/lib/libomp.dylib"
    )
    message(STATUS "Using Homebrew OpenMP: ${APPLE_OPENMP_ROOT}")
endif()

################################
# Setup SuperBuild directories #
################################

# Setup location where source tar-balls are downloaded
set(SB_DOWNLOAD_DIR "${SB_ROOT_DIR}/download"
    CACHE PATH "Location where source tar-balls are (to be) downloaded.")
mark_as_advanced(SB_DOWNLOAD_DIR)

message(STATUS "SuperBuild files will be downloaded to: ${SB_DOWNLOAD_DIR}")


# Setup location where source tar-balls are located
set(SB_SOURCE_DIR "${SB_ROOT_DIR}/src"
    CACHE PATH "Location where source tar-balls are (will be).")
mark_as_advanced(SB_SOURCE_DIR)
set(SB_BUILD_DIR "${SB_ROOT_DIR}/build")

message(STATUS "SuperBuild source files will be extracted to: ${SB_SOURCE_DIR}")


# Setup location where source tar-balls are located
set(SB_INSTALL_DIR "${SB_ROOT_DIR}/install"
    CACHE PATH "Location where source tar-balls are (will be) installed.")
mark_as_advanced(SB_SOURCE_DIR)

message(STATUS "SuperBuild source files will be installed to: ${SB_INSTALL_DIR}")


# Setup location where binary files are located
set(SB_BINARY_DIR "${SB_ROOT_DIR}/build"
    CACHE PATH "Location where files are (will be) located.")
mark_as_advanced(SB_BINARY_DIR)

message(STATUS "SuperBuild binary files will be located to: ${SB_BINARY_DIR}")

if (WIN32)
  if (NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    message(FATAL_ERROR "CMAKE_TOOLCHAIN_FILE not set. You need to set it to the path of vcpkg.cmake")
  endif()
  get_filename_component(CMAKE_TOOLCHAIN_DIR ${CMAKE_TOOLCHAIN_FILE} DIRECTORY)
  get_filename_component(VCPKG_ROOT "${CMAKE_TOOLCHAIN_DIR}/../../" ABSOLUTE)
  set(WIN32_CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
  set(PYTHON_HOME "${SB_ROOT_DIR}/../venv")
  set(PYTHON_EXE_PATH "${PYTHON_HOME}/Scripts/python")

  # Use the GDAL version that comes with pip
  set(GDAL_ROOT "${PYTHON_HOME}/Lib/site-packages/osgeo")
  set(GDAL_LIBRARY "${GDAL_ROOT}/gdal.lib")
  set(GDAL_INCLUDE_DIR "${GDAL_ROOT}/include/gdal")

  message("Copying VCPKG DLLs...")
  file(GLOB COPY_DLLS "${VCPKG_ROOT}/installed/x64-windows/bin/*.dll")
  file(COPY ${COPY_DLLS} DESTINATION "${SB_INSTALL_DIR}/bin")

  message("Copying CUDA DLLs...")
  file(GLOB CUDA_DLLS "$ENV{CUDA_PATH}/bin/cudart64*.dll")
  file(COPY ${CUDA_DLLS} DESTINATION "${SB_INSTALL_DIR}/bin")

  set(WIN32_GDAL_ARGS -DGDAL_FOUND=TRUE -DGDAL_LIBRARY=${GDAL_LIBRARY} -DGDAL_INCLUDE_DIR=${GDAL_INCLUDE_DIR})
elseif(APPLE)
    set(PYTHON_HOME "${SB_ROOT_DIR}/../venv")
    set(PYTHON_EXE_PATH "${PYTHON_HOME}/bin/python")
else()
    set(PYTHON_EXE_PATH "/usr/bin/python3")
    set(PYTHON_HOME "/usr/local/")
endif()

# Path to additional CMake modules
set(CMAKE_MODULE_PATH ${SB_ROOT_DIR}/cmake)

include(ExternalProject)
include(ExternalProject-Setup)

#########################################
# Download and install third party libs #
#########################################

set(ODM_OpenCV_Version 4.12.0)
option(ODM_BUILD_OpenCV "Force to build OpenCV library" OFF)
SETUP_EXTERNAL_PROJECT(OpenCV ${ODM_OpenCV_Version} ${ODM_BUILD_OpenCV})

set(ODM_GFlags_Version 2.2.2)
option(ODM_BUILD_GFlags "Force to build GFlags library" OFF)
SETUP_EXTERNAL_PROJECT(GFlags ${ODM_GFlags_Version} ${ODM_BUILD_GFlags})

externalproject_add(eigen34
    GIT_REPOSITORY  https://gitlab.com/libeigen/eigen.git
    GIT_TAG         7176ae16238ded7fb5ed30a7f5215825b3abd134
    UPDATE_COMMAND  ""
    SOURCE_DIR      ${SB_SOURCE_DIR}/eigen34
    CMAKE_ARGS      -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
                    -DBUILD_TESTING=OFF
                    ${APPLE_CMAKE_ARGS}
)

set(ODM_Ceres_Version 2.0.0)
option(ODM_BUILD_Ceres "Force to build Ceres library" OFF)
SETUP_EXTERNAL_PROJECT(Ceres ${ODM_Ceres_Version} ${ODM_BUILD_Ceres})

set(custom_libs OpenSfM
				LASzip
				PDAL
				PDALPython
				Untwine
				Entwine
				MvsTexturing
				OpenMVS
				FPCFilter
				Obj2Tiles
				OpenPointClass
				ExifTool
				RenderDEM
)

externalproject_add(mve
    GIT_REPOSITORY  https://github.com/WebODM/mve.git
    GIT_TAG         066ff646837ef3f95905af45406391f76d4b266d
    UPDATE_COMMAND  ""
    SOURCE_DIR      ${SB_SOURCE_DIR}/mve
    PATCH_COMMAND   ${CMAKE_COMMAND}
                    -DSOURCE_FILE=<SOURCE_DIR>/CMakeLists.txt
                    -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Patch-mve-openmp.cmake
    CMAKE_ARGS      ${WIN32_CMAKE_ARGS} ${APPLE_OPENMP_CMAKE_ARGS}
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ""
)

foreach(lib ${custom_libs})
	SETUP_EXTERNAL_PROJECT_CUSTOM(${lib})
endforeach()

include(ProcessorCount)
ProcessorCount(nproc)

if (WIN32)
    set (POISSON_BUILD_CMD ${CMAKE_MAKE_PROGRAM} ${SB_SOURCE_DIR}/PoissonRecon/PoissonRecon.vcxproj /p:configuration=${CMAKE_BUILD_TYPE} /p:Platform=x64 /p:PlatformToolset=${CMAKE_VS_PLATFORM_TOOLSET} /p:WindowsTargetPlatformVersion=${CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION})
    set (POISSON_BIN_PATH "x64/${CMAKE_BUILD_TYPE}/PoissonRecon.exe")
else()
    set (POISSON_BUILD_CMD  make -j${nproc} poissonrecon)
    set (POISSON_BIN_PATH "Linux/PoissonRecon")
    if (APPLE)
        set(POISSON_BUILD_CMD COMPILER=${APPLE_CXX_COMPILER} make -j${nproc} -f Makefile.macos poissonrecon)
        set(POISSON_PATCH_COMMAND
            ${CMAKE_COMMAND}
            -DSOURCE_FILE=<SOURCE_DIR>/Makefile.macos
            -DOPENMP_ROOT=${APPLE_OPENMP_ROOT}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Patch-poissonrecon-apple-openmp.cmake
            COMMAND ${CMAKE_COMMAND}
            -DSOURCE_FILE=<SOURCE_DIR>/PNG/pngconf.h
            -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Patch-poissonrecon-apple-png.cmake)
    endif()
endif()
externalproject_add(poissonrecon
    GIT_REPOSITORY    https://github.com/pierotofy/PoissonRecon.git
    GIT_TAG           3912
    PREFIX            ${SB_BINARY_DIR}/PoissonRecon
    SOURCE_DIR        ${SB_SOURCE_DIR}/PoissonRecon
    UPDATE_COMMAND    ""
    PATCH_COMMAND     ${POISSON_PATCH_COMMAND}
    CONFIGURE_COMMAND ""
    BUILD_IN_SOURCE 1
    BUILD_COMMAND    ${POISSON_BUILD_CMD}
    INSTALL_COMMAND  ${CMAKE_COMMAND} -E copy ${SB_SOURCE_DIR}/PoissonRecon/Bin/${POISSON_BIN_PATH} ${SB_INSTALL_DIR}/bin
)

externalproject_add(dem2mesh
    GIT_REPOSITORY    https://github.com/WebODM/dem2mesh.git
    GIT_TAG           623c8536941175c630fabe4f1352ddc314d98120
    PREFIX            ${SB_BINARY_DIR}/dem2mesh
    SOURCE_DIR        ${SB_SOURCE_DIR}/dem2mesh
    PATCH_COMMAND     ${CMAKE_COMMAND}
                      -DSOURCE_FILE=<SOURCE_DIR>/CMakeLists.txt
                      -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Patch-dem2mesh-apple-openmp.cmake
    CMAKE_ARGS        -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
                      ${WIN32_GDAL_ARGS}
                      ${APPLE_OPENMP_CMAKE_ARGS}
)

externalproject_add(dem2points
    GIT_REPOSITORY    https://github.com/WebODM/dem2points.git
    GIT_TAG           master
    PREFIX            ${SB_BINARY_DIR}/dem2points
    SOURCE_DIR        ${SB_SOURCE_DIR}/dem2points
    CMAKE_ARGS        -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
                      ${WIN32_GDAL_ARGS}
                      ${APPLE_CMAKE_ARGS}
)

externalproject_add(odm_orthophoto
    DEPENDS           opencv eigen34
    GIT_REPOSITORY    https://github.com/WebODM/odm_orthophoto.git
    GIT_TAG           55b66d87cc168b8ab287bf10e81d4da0890f84f1
    PREFIX            ${SB_BINARY_DIR}/odm_orthophoto
    SOURCE_DIR        ${SB_SOURCE_DIR}/odm_orthophoto
    CMAKE_ARGS        -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
                      -DOpenCV_DIR=${SB_INSTALL_DIR}/lib/cmake/opencv4
                      -DEigen3_DIR=${SB_INSTALL_DIR}/share/eigen3/cmake
                      -DEIGEN3_INCLUDE_DIR=${SB_INSTALL_DIR}/include/eigen3
                      ${WIN32_CMAKE_ARGS} ${WIN32_GDAL_ARGS}
                      ${APPLE_OPENMP_CMAKE_ARGS}
)

externalproject_add(fastrasterfilter
    GIT_REPOSITORY    https://github.com/WebODM/FastRasterFilter.git
    GIT_TAG           2f16676a9b3d05d3b35ab01b6d2380c8f3a42270
    PREFIX            ${SB_BINARY_DIR}/fastrasterfilter
    SOURCE_DIR        ${SB_SOURCE_DIR}/fastrasterfilter
    CMAKE_ARGS        -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
                      ${WIN32_CMAKE_ARGS} ${WIN32_GDAL_ARGS}
                      ${APPLE_OPENMP_CMAKE_ARGS}
)

externalproject_add(lastools
    GIT_REPOSITORY    https://github.com/WebODM/LAStools.git
    GIT_TAG           63ef3a4096c7a74173bccfca800b4e655ee00ae4
    PREFIX            ${SB_BINARY_DIR}/lastools
    SOURCE_DIR        ${SB_SOURCE_DIR}/lastools
    CMAKE_ARGS        -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
                      ${APPLE_CMAKE_ARGS}
)

externalproject_add(draco
    GIT_REPOSITORY    https://github.com/pierotofy/draco
    GIT_SHALLOW       ON
    GIT_TAG           396
    PREFIX            ${SB_BINARY_DIR}/draco
    SOURCE_DIR        ${SB_SOURCE_DIR}/draco
    CMAKE_ARGS        -DDRACO_TRANSCODER_SUPPORTED=ON 
                      -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR} 
                      ${WIN32_CMAKE_ARGS}
                      ${APPLE_CMAKE_ARGS}
)
