file(READ "${SOURCE_FILE}" contents)

set(modern_openmp [=[
find_package(OpenMP REQUIRED)
link_libraries(OpenMP::OpenMP_CXX)
]=])

string(FIND "${contents}" "${modern_openmp}" modern_position)
if(NOT modern_position EQUAL -1)
    return()
endif()

set(legacy_openmp [=[
find_package(OpenMP REQUIRED)
add_compile_options(${OpenMP_CXX_FLAGS})
]=])

string(FIND "${contents}" "${legacy_openmp}" legacy_position)
if(legacy_position EQUAL -1)
    message(FATAL_ERROR "Cannot patch MVE: expected OpenMP block was not found")
endif()

string(REPLACE "${legacy_openmp}" "${modern_openmp}" contents "${contents}")
file(WRITE "${SOURCE_FILE}" "${contents}")
