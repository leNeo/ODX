file(READ "${SOURCE_FILE}" contents)

set(modern_cflags
    "CFLAGS += -Xclang -fopenmp -I${OPENMP_ROOT}/include -Wno-deprecated -std=c++17 -pthread -Wno-invalid-offsetof")
set(modern_lflags
    "LFLAGS += -L${OPENMP_ROOT}/lib -lomp -lc++ -lpthread -L/opt/homebrew/lib")

set(upstream_cflags
    "CFLAGS += -fopenmp -Wno-deprecated -std=c++14 -pthread -Wno-invalid-offsetof")
set(previous_cflags
    "CFLAGS += -Xclang -fopenmp -I${OPENMP_ROOT}/include -Wno-deprecated -std=c++14 -pthread -Wno-invalid-offsetof")
set(upstream_lflags
    "LFLAGS += -lgomp -lstdc++ -lpthread -L/opt/homebrew/lib")

string(FIND "${contents}" "${modern_cflags}" modern_cflags_position)
if(modern_cflags_position EQUAL -1)
    set(cflags_replaced FALSE)
    foreach(candidate IN ITEMS "${upstream_cflags}" "${previous_cflags}")
        string(FIND "${contents}" "${candidate}" candidate_position)
        if(NOT candidate_position EQUAL -1)
            string(REPLACE "${candidate}" "${modern_cflags}" contents "${contents}")
            set(cflags_replaced TRUE)
            break()
        endif()
    endforeach()
    if(NOT cflags_replaced)
        message(FATAL_ERROR "Cannot patch PoissonRecon: expected compiler flags were not found")
    endif()
endif()

string(FIND "${contents}" "${modern_lflags}" modern_lflags_position)
if(modern_lflags_position EQUAL -1)
    string(FIND "${contents}" "${upstream_lflags}" upstream_lflags_position)
    if(upstream_lflags_position EQUAL -1)
        message(FATAL_ERROR "Cannot patch PoissonRecon: expected linker flags were not found")
    endif()
    string(REPLACE "${upstream_lflags}" "${modern_lflags}" contents "${contents}")
endif()

file(WRITE "${SOURCE_FILE}" "${contents}")
