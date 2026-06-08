set(openmvs_cmake "${OPENMVS_SOURCE_DIR}/CMakeLists.txt")

file(READ "${openmvs_cmake}" contents)

set(old_find
    "FIND_PACKAGE(Boost REQUIRED COMPONENTS iostreams program_options system serialization OPTIONAL_COMPONENTS python3)")
set(new_find
    "FIND_PACKAGE(Boost REQUIRED COMPONENTS iostreams program_options serialization OPTIONAL_COMPONENTS python3)")

string(FIND "${contents}" "${old_find}" old_find_position)
string(FIND "${contents}" "${new_find}" new_find_position)

if(NOT old_find_position EQUAL -1)
    string(REPLACE "${old_find}" "${new_find}" contents "${contents}")
elseif(new_find_position EQUAL -1)
    message(FATAL_ERROR "Could not find the expected Boost declaration in ${openmvs_cmake}")
endif()

set(old_openmp
    "SET(CMAKE_CXX_FLAGS \"\${CMAKE_CXX_FLAGS} \${OpenMP_CXX_FLAGS}\")")
set(new_openmp
"SET(CMAKE_CXX_FLAGS \"\${CMAKE_CXX_FLAGS} \${OpenMP_CXX_FLAGS}\")
		IF(OpenMP_CXX_INCLUDE_DIR)
			INCLUDE_DIRECTORIES(\${OpenMP_CXX_INCLUDE_DIR})
		ENDIF()")

string(FIND "${contents}" "${old_openmp}" old_openmp_position)
string(FIND "${contents}" "${new_openmp}" new_openmp_position)

if(NOT old_openmp_position EQUAL -1)
    string(REPLACE "${old_openmp}" "${new_openmp}" contents "${contents}")
elseif(new_openmp_position EQUAL -1)
    message(FATAL_ERROR "Could not find the expected OpenMP block in ${openmvs_cmake}")
endif()

file(WRITE "${openmvs_cmake}" "${contents}")
