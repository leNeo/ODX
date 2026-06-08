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
    file(WRITE "${openmvs_cmake}" "${contents}")
elseif(new_find_position EQUAL -1)
    message(FATAL_ERROR "Could not find the expected Boost declaration in ${openmvs_cmake}")
endif()
