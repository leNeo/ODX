set(triangulation_header
    "${OPENSFM_SOURCE_DIR}/opensfm/src/geometry/triangulation.h")

file(READ "${triangulation_header}" contents)

set(old_abs_block
"#ifdef __aarch64__
  if (std::abs<T>(det) < eps) {
#else
  if (abs(det) < eps) {
#endif")
set(intermediate_abs_block
"#ifdef __aarch64__
  if (std::abs(det) < eps) {
#else
  if (abs(det) < eps) {
#endif")
set(new_abs_block
"  using std::abs;
  if (abs(det) < eps) {")

string(FIND "${contents}" "${old_abs_block}" old_abs_position)
string(FIND "${contents}" "${intermediate_abs_block}" intermediate_abs_position)
string(FIND "${contents}" "${new_abs_block}" new_abs_position)

if(NOT old_abs_position EQUAL -1)
    string(REPLACE "${old_abs_block}" "${new_abs_block}" contents "${contents}")
    file(WRITE "${triangulation_header}" "${contents}")
elseif(NOT intermediate_abs_position EQUAL -1)
    string(REPLACE "${intermediate_abs_block}" "${new_abs_block}"
        contents "${contents}")
    file(WRITE "${triangulation_header}" "${contents}")
elseif(new_abs_position EQUAL -1)
    message(FATAL_ERROR
        "Could not find the expected abs expression in ${triangulation_header}")
endif()
