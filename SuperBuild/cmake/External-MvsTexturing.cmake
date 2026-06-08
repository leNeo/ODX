set(_proj_name mvstexturing)
set(_SB_BINARY_DIR "${SB_BINARY_DIR}/${_proj_name}")

ExternalProject_Add(${_proj_name}
  DEPENDS           mve eigen34
  PREFIX            ${_SB_BINARY_DIR}
  TMP_DIR           ${_SB_BINARY_DIR}/tmp
  STAMP_DIR         ${_SB_BINARY_DIR}/stamp
  #--Download step--------------
  DOWNLOAD_DIR      ${SB_DOWNLOAD_DIR}/${_proj_name}
  GIT_REPOSITORY    https://github.com/WebODM/mvs-texturing
  GIT_TAG           a56b5e7f95f0bb1dd1e1eb89ce5da202349c0e01
  #--Update/Patch step----------
  UPDATE_COMMAND    ""
  PATCH_COMMAND
    ${CMAKE_COMMAND}
    -DROOT_FILE=<SOURCE_DIR>/CMakeLists.txt
    -DELIBS_FILE=<SOURCE_DIR>/elibs/CMakeLists.txt
    -P ${CMAKE_CURRENT_LIST_DIR}/Patch-mvstexturing-eigen.cmake
  #--Configure step-------------
  SOURCE_DIR        ${SB_SOURCE_DIR}/${_proj_name}
  CMAKE_ARGS
    -DRESEARCH=OFF
    -DEIGEN_INCLUDE_DIR=${SB_SOURCE_DIR}/eigen34
    -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
    -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
    ${WIN32_CMAKE_ARGS}
    ${APPLE_OPENMP_CMAKE_ARGS}
  #--Build step-----------------
  BINARY_DIR        ${_SB_BINARY_DIR}
  #--Install step---------------
  INSTALL_DIR       ${SB_INSTALL_DIR}
  #--Output logging-------------
  LOG_DOWNLOAD      OFF
  LOG_CONFIGURE     OFF
  LOG_BUILD         OFF
)
