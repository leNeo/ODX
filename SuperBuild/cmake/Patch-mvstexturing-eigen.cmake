file(READ "${ROOT_FILE}" root_contents)

set(legacy_openmp [=[
FIND_PACKAGE(OpenMP)
if(OPENMP_FOUND)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
endif()
]=])
set(modern_openmp [=[
find_package(OpenMP REQUIRED)
include_directories(SYSTEM ${OpenMP_CXX_INCLUDE_DIRS} ${OpenMP_CXX_INCLUDE_DIR})
link_libraries(OpenMP::OpenMP_CXX)
]=])
set(previous_openmp [=[
find_package(OpenMP REQUIRED)
link_libraries(OpenMP::OpenMP_CXX)
]=])

string(FIND "${root_contents}" "${modern_openmp}" modern_openmp_position)
if(modern_openmp_position EQUAL -1)
    set(openmp_replaced FALSE)
    foreach(candidate IN ITEMS "${legacy_openmp}" "${previous_openmp}")
        string(FIND "${root_contents}" "${candidate}" candidate_position)
        if(NOT candidate_position EQUAL -1)
            string(REPLACE
                "${candidate}" "${modern_openmp}"
                root_contents "${root_contents}")
            set(openmp_replaced TRUE)
            break()
        endif()
    endforeach()
    if(NOT openmp_replaced)
        message(FATAL_ERROR "Cannot patch MvsTexturing: expected OpenMP block was not found")
    endif()
endif()

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
endif()

file(WRITE "${ROOT_FILE}" "${root_contents}")

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
