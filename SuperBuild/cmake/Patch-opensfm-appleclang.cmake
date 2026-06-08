set(triangulation_header
    "${OPENSFM_SOURCE_DIR}/opensfm/src/geometry/triangulation.h")

file(READ "${triangulation_header}" contents)

set(old_abs "std::abs<T>(det)")
set(new_abs "std::abs(det)")

string(FIND "${contents}" "${old_abs}" old_abs_position)
string(FIND "${contents}" "${new_abs}" new_abs_position)

if(NOT old_abs_position EQUAL -1)
    string(REPLACE "${old_abs}" "${new_abs}" contents "${contents}")
    file(WRITE "${triangulation_header}" "${contents}")
elseif(new_abs_position EQUAL -1)
    message(FATAL_ERROR
        "Could not find the expected abs expression in ${triangulation_header}")
endif()
