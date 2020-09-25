project("moo-buildsys-cmake")
cmake_minimum_required(VERSION 3.17) # older may also work

execute_process(
  COMMAND moo -T ${CMAKE_SOURCE_DIR} -M ${CMAKE_SOURCE_DIR} imports model.jsonnet
  OUTPUT_VARIABLE MODEL_DEPENDENCIES_LINES
  RESULT_VARIABLE RETURN_VALUE
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)
if (NOT RETURN_VALUE EQUAL 0)
  message(FATAL_ERROR "Failed to get the dependencies")
endif()
string(REPLACE "\n" ";" MODEL_DEPENDENCIES ${MODEL_DEPENDENCIES_LINES})

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/model-dump.txt DESTINATION ${CMAKE_INSTALL_PREFIX})

add_custom_command(
  OUTPUT model-dump.txt
  COMMAND moo -T ${CMAKE_SOURCE_DIR} -M ${CMAKE_SOURCE_DIR} render -o model-dump.txt model.jsonnet dump.txt.j2
  DEPENDS model.jsonnet dump.txt.j2 ${MODEL_DEPENDENCIES}
  COMMENT "Generating model-dump.txt"
)
add_custom_target(ModelDump DEPENDS model-dump.txt)

message("implicit dependencies: ${MODEL_DEPENDENCIES}")
