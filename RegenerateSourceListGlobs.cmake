# Including this module will cause CMake to be re-run any time a file is
# created/deleted/renamed inside a directory containing source files referred
# in calls to add_executable()/add_library()/add_custom_target(). This should
# make using GLOBs for source file lists safe. Works only with makefiles.
#
# Tested on Linux.
#
# Thanks to Bartosz Szurgot and Aleksander Żak for ideas/improvements.

set(_mod RegenerateSourceListGlobs)
string(LENGTH ${CMAKE_BINARY_DIR} _cbdl)

if(CMAKE_GENERATOR STREQUAL "Unix Makefiles")
    set(_rules "${_mod}.timestamp: ; ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}; >$@\n${_mod}.timestamp:")
    add_custom_target(${_mod} +make -C ${CMAKE_BINARY_DIR} -f ${_mod}.rules MAKEFLAGS="")
else()
    message(FATAL_ERROR "${_mod} does not support the \"${CMAKE_GENERATOR}\" generator")
endif()

file(WRITE ${CMAKE_BINARY_DIR}/${_mod}.timestamp "")
file(WRITE ${CMAKE_BINARY_DIR}/${_mod}.rules "${_rules}")

function(regenerate_source_list_globs target)
    get_target_property(sources ${target} SOURCES)
    set(paths)
    foreach(source ${sources})
        get_filename_component(abs_file_path ${source} ABSOLUTE)
        get_filename_component(path ${abs_file_path} PATH)
        string(LENGTH ${path} pl)
        if(pl LESS _cbdl)
            list(APPEND paths ${path})
        else()
            string(SUBSTRING ${path} 0 ${_cbdl} prefix)
            if(NOT prefix STREQUAL CMAKE_BINARY_DIR)
                list(APPEND paths ${path})
            endif()
        endif()
    endforeach()
    if(paths)
        list(REMOVE_DUPLICATES paths)
        string(REPLACE ";" " " paths "${paths}")
        file(APPEND ${CMAKE_BINARY_DIR}/${_mod}.rules " ${paths}")
    endif()
    add_dependencies(${target} ${_mod})
endfunction()

function(add_executable target)
    _add_executable(${target} ${ARGN})
    regenerate_source_list_globs(${target})
endfunction()
function(add_library target)
    _add_library(${target} ${ARGN})
    regenerate_source_list_globs(${target})
endfunction()
function(add_custom_target target)
    _add_custom_target(${target} ${ARGN})
    regenerate_source_list_globs(${target})
endfunction()
