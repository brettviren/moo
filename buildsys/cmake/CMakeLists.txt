project("moo-buildsys-cmake")
cmake_minimum_required(VERSION 3.17) # older may also work
add_custom_target(ModelDump
  COMMAND moo -T ${CMAKE_SOURCE_DIR} -M ${CMAKE_SOURCE_DIR} render -o model-dump.txt model.jsonnet dump.txt.j2
  )
