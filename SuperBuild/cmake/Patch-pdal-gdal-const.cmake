file(READ "${SOURCE_FILE}" contents)

set(modern_declaration "const char * const *papszMetadata = NULL;")
string(FIND "${contents}" "${modern_declaration}" modern_position)
if(NOT modern_position EQUAL -1)
    return()
endif()

set(legacy_declaration "char **papszMetadata = NULL;")
string(FIND "${contents}" "${legacy_declaration}" legacy_position)
if(legacy_position EQUAL -1)
    message(FATAL_ERROR "Cannot patch PDAL: expected GDAL metadata declaration was not found")
endif()

string(REPLACE "${legacy_declaration}" "${modern_declaration}" contents "${contents}")
file(WRITE "${SOURCE_FILE}" "${contents}")
