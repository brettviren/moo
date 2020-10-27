# fixme: move into find_package(moo)!
# For now, use eg cmake -DMOO_CMD=$(which moo)
set(MOO_CMD "moo" CACHE STRING "The 'moo' command")


# https://cmake.org/pipermail/cmake/2009-December/034253.html

# Given a source file name set <prefix>_DEPS_FILE to a file name and
# <prefix>_DEPS_NAME to a variable name.  The file name is suitable
# for use in "moo imports -o ${<prefix>_DEPS_FILE} ..." such that when
# this file is included into cmake the ${${<prefix>_DEPS_NAME}} will
# contain the list of import dependencies that moo calculated.
function(moo_deps_name source prefix)
  get_filename_component(basename ${source} NAME)
  get_filename_component(fullpath ${source} REALPATH)
  string(CONCAT DEPS_NAME "${basename}" "_deps") #make unique
  string(REGEX REPLACE "[^a-zA-Z0-9]" "_" DEPS_NAME "${DEPS_NAME}")
  set("${prefix}_DEPS_FILE" "${CMAKE_CURRENT_BINARY_DIR}/${DEPS_NAME}.cmake" PARENT_SCOPE)
  string(TOUPPER "${DEPS_NAME}" DEPS_NAME)
  set("${prefix}_DEPS_NAME" "${DEPS_NAME}" PARENT_SCOPE)
endfunction()

##
macro(moo_codegen)
  cmake_parse_arguments(MC "" "MODEL;TEMPL;CODEGEN;MPATH;TPATH;GRAFT;TLAS" "" ${ARGN})

  if (NOT DEFINED MC_MPATH)
    set(MC_MPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()
  if (NOT DEFINED MC_TPATH)
    set(MC_TPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  moo_deps_name(${MC_MODEL} MC_MODEL)
  moo_deps_name(${MC_TEMPL} MC_TEMPL)

  list(TRANSFORM $MC_GRAFT APPEND "-g")
  list(TRANSFORM $MC_TLAS APPEND "-A")
  set(MC_BASE_ARGS -T ${MC_TPATH} -M ${MC_MPATH} ${MC_GRAFT} ${MC_TLAS})

  set(MC_MODEL_DEPS_ARGS ${MC_BASE_ARGS} imports -o ${MC_MODEL_DEPS_FILE} ${MC_MODEL})
  #message("model deps args ${MC_MODEL_DEPS_ARGS}")

  set(MC_TEMPL_DEPS_ARGS ${MC_BASE_ARGS} imports -o ${MC_TEMPL_DEPS_FILE} ${MC_TEMPL})
  #message("templ deps args ${MC_TEMPL_DEPS_ARGS}")

  execute_process(
    COMMAND ${MOO_CMD} ${MC_MODEL_DEPS_ARGS}
    RESULT_VARIABLE RETURN_VALUE)
  if (NOT RETURN_VALUE EQUAL 0)
    message(FATAL_ERROR "Failed to prime dependencies for ${MC_MODEL}")
  endif()
  include(${MC_MODEL_DEPS_FILE})

  message("model deps name: ${MC_MODEL_DEPS_NAME}")
  message("model deps file: ${MC_MODEL_DEPS_FILE}")
  message("model deps: ${${MC_MODEL_DEPS_NAME}}")


  execute_process(
    COMMAND ${MOO_CMD} ${MC_TEMPL_DEPS_ARGS}
    RESULT_VARIABLE RETURN_VALUE)
  if (NOT RETURN_VALUE EQUAL 0)
    message(FATAL_ERROR "Failed to prime dependencies for ${MC_TEMPL}")
  endif()
  include(${MC_TEMPL_DEPS_FILE})

  set(MC_CODEGEN_ARGS ${MC_BASE_ARGS} render -o ${MC_CODEGEN} ${MC_MODEL} ${MC_TEMPL})
  message("codegen args ${MC_CODEGEN_ARGS}")
  add_custom_command(
    COMMAND ${MOO_CMD} ARGS ${MC_CODEGEN_ARGS}
    COMMENT "generate code ${MC_CODEGEN}"
    DEPENDS "${MC_MODEL}" "${MC_TEMPL}" "${${MC_MODEL_DEPS_NAME}}" "${${MC_TEMPL_DEPS_NAME}}"
    OUTPUT "${MC_CODEGEN}")

  add_custom_command(
    COMMAND ${MOO_CMD} ARGS ${MC_MODEL_DEPS_ARGS}
    COMMENT "remake model dependencies ${MC_MODEL_DEPS_FILE}"
    DEPENDS ${MC_MODEL} ${${MC_MODEL_DEPS_NAME}} # bootstrap problems?
    OUTPUT ${MC_MODEL_DEPS_FILE})

  add_custom_command(
    COMMAND ${MOO_CMD} ARGS ${MC_TEMPL_DEPS_ARGS}
    COMMENT "remake templ dependencies ${MC_TEMPL_DEPS_FILE}"
    DEPENDS ${MC_TEMPL} ${${MC_TEMPL_DEPS_NAME}} # bootstrap problems?
    OUTPUT ${MC_TEMPL_DEPS_FILE})

endmacro()

