file(READ "${SOURCE_FILE}" contents)

set(legacy_args [=[
        CMAKE_ARGS -DBUILD_STATIC_LIB=ON
                -DCMAKE_INSTALL_PREFIX=${LIGHTGBM_PREFIX}
]=])
set(modern_args [=[
        CMAKE_ARGS -DBUILD_STATIC_LIB=ON
                -DCMAKE_POLICY_VERSION_MINIMUM=3.5
                -DCMAKE_INSTALL_PREFIX=${LIGHTGBM_PREFIX}
]=])

string(FIND "${contents}" "${modern_args}" modern_position)
if(NOT modern_position EQUAL -1)
    return()
endif()

string(FIND "${contents}" "${legacy_args}" legacy_position)
if(legacy_position EQUAL -1)
    message(FATAL_ERROR "Cannot patch OpenPointClass: expected LightGBM arguments were not found")
endif()

string(REPLACE "${legacy_args}" "${modern_args}" contents "${contents}")
file(WRITE "${SOURCE_FILE}" "${contents}")
