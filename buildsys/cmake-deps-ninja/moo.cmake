# fixme: move into find_package(moo)!
# For now, use eg cmake -DMOO_CMD=$(which moo)
set(MOO_CMD "moo" CACHE STRING "The 'moo' command")

macro(moo_codegen)
  cmake_parse_arguments(MC "" "MODEL;TEMPL;CODEGEN;MPATH;TPATH;GRAFT;TLAS" "" ${ARGN})

  if (NOT DEFINED MC_MPATH)
    set(MC_MPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()
  if (NOT DEFINED MC_TPATH)
    set(MC_TPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  list(TRANSFORM $MC_GRAFT APPEND "-g")
  list(TRANSFORM $MC_TLAS APPEND "-A")
  set(MC_BASE_ARGS -T ${MC_TPATH} -M ${MC_MPATH} ${MC_GRAFT} ${MC_TLAS})

  set(MC_MODEL_DEPS_ARGS ${MC_BASE_ARGS} imports -o ${MC_MODEL_DEPS_FILE} ${MC_MODEL})
  #message("model deps args ${MC_MODEL_DEPS_ARGS}")

  set(MC_TEMPL_DEPS_ARGS ${MC_BASE_ARGS} imports -o ${MC_TEMPL_DEPS_FILE} ${MC_TEMPL})

  set(MC_DEPS_FILE ${MC_CODEGEN}.d)
  set(MC_CODEGEN_ARGS ${MC_BASE_ARGS} render -o ${MC_CODEGEN} ${MC_MODEL} ${MC_TEMPL})
  set(MC_RENDER_DEPS_ARGS ${MC_BASE_ARGS} render-deps -o ${MC_DEPS_FILE} -t ${MC_CODEGEN} ${MC_MODEL} ${MC_TEMPL})
  
  message("codegen args ${MC_CODEGEN_ARGS}")
  add_custom_command(
    COMMAND ${MOO_CMD} ARGS ${MC_CODEGEN_ARGS}
    COMMAND ${MOO_CMD} ARGS ${MC_RENDER_DEPS_ARGS}
    COMMENT "generate code ${MC_CODEGEN}"
    DEPENDS "${MC_MODEL}" "${MC_TEMPL}"
    DEPFILE ${MC_DEPS_FILE}
    OUTPUT "${MC_CODEGEN}")

endmacro()

