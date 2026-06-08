file(READ "${ROOT_FILE}" root_contents)

set(legacy_root_include
    "    \${CMAKE_SOURCE_DIR}/elibs/eigen")
set(modern_root_include
    "    \${EIGEN_INCLUDE_DIR}")

string(FIND "${root_contents}" "${modern_root_include}" modern_root_position)
if(modern_root_position EQUAL -1)
    string(FIND "${root_contents}" "${legacy_root_include}" legacy_root_position)
    if(legacy_root_position EQUAL -1)
        message(FATAL_ERROR "Cannot patch MvsTexturing: expected Eigen include was not found")
    endif()
    string(REPLACE
        "${legacy_root_include}" "${modern_root_include}"
        root_contents "${root_contents}")
    file(WRITE "${ROOT_FILE}" "${root_contents}")
endif()

file(READ "${ELIBS_FILE}" elibs_contents)

set(legacy_external [=[
externalproject_add(ext_eigen
    PREFIX          ext_eigen
    URL             https://gitlab.com/libeigen/eigen/-/archive/3.3.2/eigen-3.3.2.tar.gz
    URL_MD5         02edfeec591ae09848223d622700a10b
    SOURCE_DIR      ${CMAKE_SOURCE_DIR}/elibs/eigen
    CONFIGURE_COMMAND ""
    BUILD_COMMAND   ""
    INSTALL_COMMAND ""
)
]=])

set(modern_external [=[
if(EIGEN_INCLUDE_DIR)
    add_custom_target(ext_eigen)
else()
    externalproject_add(ext_eigen
        PREFIX          ext_eigen
        URL             https://gitlab.com/libeigen/eigen/-/archive/3.3.2/eigen-3.3.2.tar.gz
        URL_MD5         02edfeec591ae09848223d622700a10b
        SOURCE_DIR      ${CMAKE_SOURCE_DIR}/elibs/eigen
        CONFIGURE_COMMAND ""
        BUILD_COMMAND   ""
        INSTALL_COMMAND ""
    )
endif()
]=])

string(FIND "${elibs_contents}" "${modern_external}" modern_external_position)
if(modern_external_position EQUAL -1)
    string(FIND "${elibs_contents}" "${legacy_external}" legacy_external_position)
    if(legacy_external_position EQUAL -1)
        message(FATAL_ERROR "Cannot patch MvsTexturing: expected Eigen project was not found")
    endif()
    string(REPLACE
        "${legacy_external}" "${modern_external}"
        elibs_contents "${elibs_contents}")
    file(WRITE "${ELIBS_FILE}" "${elibs_contents}")
endif()
