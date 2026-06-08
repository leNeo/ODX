set(_proj_name opencv)
set(_SB_BINARY_DIR "${SB_BINARY_DIR}/${_proj_name}")
set(OCV_WITH_FFMPEG ON)

if (WIN32)
  set(OCV_CMAKE_EXTRA_ARGS -DPYTHON3_NUMPY_INCLUDE_DIRS=${PYTHON_HOME}/lib/site-packages/numpy/_core/include
                             -DPYTHON3_PACKAGES_PATH=${PYTHON_HOME}/lib/site-packages
                             -DPYTHON3_EXECUTABLE=${PYTHON_EXE_PATH}
                             -DWITH_MSMF=OFF
                             -DOPENCV_LIB_INSTALL_PATH=${SB_INSTALL_DIR}/lib
                             -DOPENCV_BIN_INSTALL_PATH=${SB_INSTALL_DIR}/bin)
elseif(APPLE)
  # macOS is unable to automatically detect our Python libs
  set(OCV_WITH_FFMPEG OFF)
  execute_process(
    COMMAND ${PYTHON_EXE_PATH} -c "import numpy; print(numpy.get_include())"
    OUTPUT_VARIABLE PYTHON_NUMPY_INCLUDE_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
  )
  execute_process(
    COMMAND ${PYTHON_EXE_PATH} -c "import sys; print(sys.version_info.major)"
    OUTPUT_VARIABLE PYTHON_VERSION_MAJOR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
  )
  execute_process(
    COMMAND ${PYTHON_EXE_PATH} -c "import sys; print(sys.version_info.minor)"
    OUTPUT_VARIABLE PYTHON_VERSION_MINOR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
  )
  execute_process(
    COMMAND ${PYTHON_EXE_PATH} -c "import sysconfig; print(sysconfig.get_path('purelib'))"
    OUTPUT_VARIABLE PYTHON_PACKAGES_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
  )
  execute_process(
    COMMAND ${PYTHON_EXE_PATH} -c "import sysconfig; print(sysconfig.get_path('include'))"
    OUTPUT_VARIABLE PYTHON_INCLUDE_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY
  )

  set(PYTHON_VERSION "${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}")
  set(PYTHON_LIBRARY
      "${HOMEBREW_INSTALL_PREFIX}/opt/python@${PYTHON_VERSION}/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/lib/libpython${PYTHON_VERSION}.dylib")

  set(OCV_CMAKE_EXTRA_ARGS -DPYTHON3_NUMPY_INCLUDE_DIRS=${PYTHON_NUMPY_INCLUDE_DIR}
                           -DPython3_NumPy_INCLUDE_DIRS=${PYTHON_NUMPY_INCLUDE_DIR}
                           -DPYTHON3_PACKAGES_PATH=${PYTHON_PACKAGES_PATH}
                           -DPYTHON3_EXECUTABLE=${PYTHON_EXE_PATH}
                           -DPython3_EXECUTABLE=${PYTHON_EXE_PATH}
                           -DPYTHON3_LIBRARIES=${PYTHON_LIBRARY}
                           -DPYTHON3_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}
                           -DPYTHON3_INCLUDE_PATH=${PYTHON_INCLUDE_DIR}
                           -DPYTHON3INTERP_FOUND=ON
                           -DPYTHON3LIBS_FOUND=ON
                           -DPYTHON_DEFAULT_AVAILABLE=ON
                           -DPYTHON_DEFAULT_EXECUTABLE=${PYTHON_EXE_PATH}
                           -DPYTHON3_VERSION_MAJOR=${PYTHON_VERSION_MAJOR}
                           -DPYTHON3_VERSION_MINOR=${PYTHON_VERSION_MINOR}
                           -DOPENCV_CONFIG_INSTALL_PATH=
                           -DOPENCV_PYTHON_INSTALL_PATH=${SB_INSTALL_DIR}/lib/python${PYTHON_VERSION}/dist-packages
                           -DHAVE_opencv_python3=ON
                           -DOPENCV_PYTHON_SKIP_DETECTION=ON
                           -DOPENCV_LIB_INSTALL_PATH=${SB_INSTALL_DIR}/lib
                           -DOPENCV_BIN_INSTALL_PATH=${SB_INSTALL_DIR}/bin)
else()
  set(OCV_CMAKE_EXTRA_ARGS -DPYTHON3_NUMPY_INCLUDE_DIRS=${PYTHON_HOME}/lib/python3.12/dist-packages/numpy/_core/include
                             -DPYTHON3_PACKAGES_PATH=${PYTHON_HOME}/lib/python3.12/dist-packages
                             -DPYTHON3_EXECUTABLE=${PYTHON_EXE_PATH})
endif()

ExternalProject_Add(${_proj_name}
  PREFIX            ${_SB_BINARY_DIR}
  TMP_DIR           ${_SB_BINARY_DIR}/tmp
  STAMP_DIR         ${_SB_BINARY_DIR}/stamp
  #--Download step--------------
  DOWNLOAD_DIR      ${SB_DOWNLOAD_DIR}
  URL               https://github.com/opencv/opencv/archive/4.12.0.zip
  #--Update/Patch step----------
  UPDATE_COMMAND    ""
  #--Configure step-------------
  SOURCE_DIR        ${SB_SOURCE_DIR}/${_proj_name}
  CMAKE_ARGS
    -DBUILD_opencv_core=ON
    -DBUILD_opencv_imgproc=ON
    -DBUILD_opencv_highgui=ON
    -DBUILD_opencv_video=ON
    -DBUILD_opencv_ml=ON
    -DBUILD_opencv_features2d=ON
    -DBUILD_opencv_calib3d=ON
    -DBUILD_opencv_contrib=ON
    -DBUILD_opencv_flann=ON
    -DBUILD_opencv_objdetect=ON
    -DBUILD_opencv_photo=ON
    -DBUILD_opencv_legacy=ON
    -DBUILD_opencv_python3=ON
    -DWITH_FFMPEG=${OCV_WITH_FFMPEG}
    -DWITH_CUDA=OFF
    -DWITH_GTK=OFF
    -DWITH_VTK=OFF
    -DWITH_EIGEN=OFF
    -DWITH_OPENNI=OFF
    -DWITH_OPENEXR=OFF
    -DWITH_JPEGXL=ON
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_PERF_TESTS=OFF
    -DBUILD_DOCS=OFF
    -DBUILD_opencv_apps=OFF
    -DBUILD_opencv_gpu=OFF
    -DBUILD_opencv_videostab=OFF
    -DBUILD_opencv_nonfree=OFF
    -DBUILD_opencv_stitching=OFF
    -DBUILD_opencv_world=OFF
    -DBUILD_opencv_superres=OFF
    -DBUILD_opencv_java=OFF
    -DBUILD_opencv_ocl=OFF
    -DBUILD_opencv_ts=OFF
    -DBUILD_opencv_xfeatures2d=ON
    -DOPENCV_ALLOCATOR_STATS_COUNTER_TYPE=int64_t
    -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
    ${WIN32_CMAKE_ARGS}
    ${APPLE_CMAKE_ARGS}
    ${OCV_CMAKE_EXTRA_ARGS}
  #--Build step-----------------
  BINARY_DIR        ${_SB_BINARY_DIR}
  #--Install step---------------
  INSTALL_DIR       ${SB_INSTALL_DIR}
  #--Output logging-------------
  LOG_DOWNLOAD      OFF
  LOG_CONFIGURE     OFF
  LOG_BUILD         OFF
)
