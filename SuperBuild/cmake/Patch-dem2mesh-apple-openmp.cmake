if(NOT APPLE)
    return()
endif()

file(READ "${SOURCE_FILE}" contents)

set(modern_link
    "target_link_libraries(\${PROJECT_NAME} \${GDAL_LIBRARY} jmeshlib OpenMP::OpenMP_CXX)")
string(FIND "${contents}" "${modern_link}" modern_link_position)
if(NOT modern_link_position EQUAL -1)
    return()
endif()

set(legacy_detection [=[
if(APPLE)
    if(CMAKE_C_COMPILER_ID MATCHES "Clang")
        set(OpenMP_C "${CMAKE_C_COMPILER}")
        set(OpenMP_C_FLAGS "-Xclang -fopenmp -Wno-unused-command-line-argument")
        set(OpenMP_C_LIB_NAMES "libomp" "libgomp" "libiomp5")
        set(OpenMP_libomp_LIBRARY ${OpenMP_C_LIB_NAMES})
        set(OpenMP_libgomp_LIBRARY ${OpenMP_C_LIB_NAMES})
        set(OpenMP_libiomp5_LIBRARY ${OpenMP_C_LIB_NAMES})
    endif()
    if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
      set(OpenMP_CXX "${CMAKE_CXX_COMPILER}")
      set(OpenMP_CXX_FLAGS "-Xclang -fopenmp -Wno-unused-command-line-argument")
      set(OpenMP_CXX_LIB_NAMES "libomp" "libgomp" "libiomp5")
      set(OpenMP_libomp_LIBRARY ${OpenMP_CXX_LIB_NAMES})
      set(OpenMP_libgomp_LIBRARY ${OpenMP_CXX_LIB_NAMES})
      set(OpenMP_libiomp5_LIBRARY ${OpenMP_CXX_LIB_NAMES})
    endif()

endif()
]=])

set(legacy_flags [=[
if(OPENMP_FOUND)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
    if(APPLE)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fopenmp")
    endif()
endif()
]=])

set(legacy_link
    "target_link_libraries(\${PROJECT_NAME} \${GDAL_LIBRARY} jmeshlib)")

foreach(expected IN ITEMS "${legacy_detection}" "${legacy_flags}" "${legacy_link}")
    string(FIND "${contents}" "${expected}" expected_position)
    if(expected_position EQUAL -1)
        message(FATAL_ERROR "Cannot patch dem2mesh: expected source block was not found")
    endif()
endforeach()

string(REPLACE "${legacy_detection}" "" contents "${contents}")
string(REPLACE "${legacy_flags}" "" contents "${contents}")
string(REPLACE "${legacy_link}" "${modern_link}" contents "${contents}")

file(WRITE "${SOURCE_FILE}" "${contents}")
