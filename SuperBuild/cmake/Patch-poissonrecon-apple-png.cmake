file(READ "${SOURCE_FILE}" contents)

set(legacy_detection
    "defined(THINK_C) || defined(__SC__) || defined(TARGET_OS_MAC)")
set(modern_detection
    "defined(THINK_C) || defined(__SC__)")

string(FIND "${contents}" "${legacy_detection}" legacy_position)
if(legacy_position EQUAL -1)
    string(FIND "${contents}" "${modern_detection}" modern_position)
    if(modern_position EQUAL -1)
        message(FATAL_ERROR "Cannot patch PoissonRecon PNG: expected macOS detection was not found")
    endif()
    return()
endif()

string(REPLACE "${legacy_detection}" "${modern_detection}" contents "${contents}")
file(WRITE "${SOURCE_FILE}" "${contents}")
