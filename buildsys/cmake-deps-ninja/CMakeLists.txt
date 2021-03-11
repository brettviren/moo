project("moo-buildsys-cmake-deps")
cmake_minimum_required(VERSION 3.7...3.17) # Need 3.7 for DEPFILE in add_custom_command()

# fixme: needs to turn into a find_package(moo)!
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
include(moo)

moo_codegen(MODEL model.jsonnet TEMPL dump.txt.j2 CODEGEN model-dump.txt)

## We need some target to trigger the codegen.  Normally, this would
## be done by some "real" code target depending on the CODEGEN output.
##   cmake --build build/ -t DOIT
add_custom_target(DOIT ALL DEPENDS model-dump.txt)
