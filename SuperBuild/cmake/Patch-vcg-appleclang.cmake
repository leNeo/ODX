set(selection_header
    "${VCG_SOURCE_DIR}/vcg/complex/algorithms/update/selection.h")

file(READ "${selection_header}" contents)

set(old_call "Allocator<ComputeMeshType>::template IsValidHandle(*_m, vsH)")
set(new_call "Allocator<ComputeMeshType>::IsValidHandle(*_m, vsH)")

string(FIND "${contents}" "${old_call}" old_call_position)
string(FIND "${contents}" "${new_call}" new_call_position)

if(NOT old_call_position EQUAL -1)
    string(REPLACE "${old_call}" "${new_call}" contents "${contents}")
    file(WRITE "${selection_header}" "${contents}")
elseif(new_call_position EQUAL -1)
    message(FATAL_ERROR
        "Could not find the expected IsValidHandle call in ${selection_header}")
endif()
