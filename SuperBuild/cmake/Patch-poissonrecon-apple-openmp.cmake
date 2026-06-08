file(READ "${SOURCE_FILE}" contents)

set(modern_cflags
    "CFLAGS += -Xclang -fopenmp -I${OPENMP_ROOT}/include -Wno-deprecated -std=c++14 -pthread -Wno-invalid-offsetof")
set(modern_lflags
    "LFLAGS += -L${OPENMP_ROOT}/lib -lomp -lc++ -lpthread -L/opt/homebrew/lib")

string(FIND "${contents}" "${modern_cflags}" modern_position)
if(NOT modern_position EQUAL -1)
    return()
endif()

set(legacy_cflags
    "CFLAGS += -fopenmp -Wno-deprecated -std=c++14 -pthread -Wno-invalid-offsetof")
set(legacy_lflags
    "LFLAGS += -lgomp -lstdc++ -lpthread -L/opt/homebrew/lib")

foreach(expected IN ITEMS "${legacy_cflags}" "${legacy_lflags}")
    string(FIND "${contents}" "${expected}" expected_position)
    if(expected_position EQUAL -1)
        message(FATAL_ERROR "Cannot patch PoissonRecon: expected compiler flags were not found")
    endif()
endforeach()

string(REPLACE "${legacy_cflags}" "${modern_cflags}" contents "${contents}")
string(REPLACE "${legacy_lflags}" "${modern_lflags}" contents "${contents}")
file(WRITE "${SOURCE_FILE}" "${contents}")
