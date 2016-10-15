# Including this module creates, for each node in the directory tree, a target
# that generates doxygen documentation for the current subdirectory
# (recursively by default).
#
# The target names consist of ${CMAKE_CURRENT_SOURCE_DIR} with the
# ${CMAKE_SOURCE_DIR} prefix removed and "/" replaced with "_", plus a static
# suffix defined by the DOXYGEN_TARGET_SUFFIX variable ("doc" by default).
#
# Examples for the default suffix:
# * On the top level, the target is called "doc"
# * In a directory called "foo", the target is called "foo_doc"
# * In a directory called "foo/bar", the target is called "foo_bar_doc"
#
# If the variable DOXYGEN_DOXYFILE_LOCATION is defined, the Doxyfile specified
# will be used to generate the documentation. Otherwise, a default
# configuration will be generated, with the RECURSIVE option set to YES.
# In both cases, the INPUT option will be set to ${CMAKE_CURRENT_SOURCE_DIR}.
#
# If a static Doxyfile template is insufficient, the
# DOXYGEN_DOXYFILE_IN_LOCATION variable can be set to specify the location of a
# file that will be used as input to configure_file(). The
# DOXYGEN_DOXYFILE_LOCATION variable will automatially be set to the output of
# configure_file(), thus providing the variable expansion described in the
# function's documentation.
#
# A custom doxygen location can be specified via the DOXYGEN_EXECUTABLE
# variable.
#
# Tested on Linux.

if(NOT DEFINED DOXYGEN_EXECUTABLE)
    set(DOXYGEN_EXECUTABLE doxygen)
endif()
if(NOT DEFINED DOXYGEN_TARGET_SUFFIX)
    set(DOXYGEN_TARGET_SUFFIX doc)
endif()
if(DOXYGEN_DOXYFILE_IN_LOCATION)
    configure_file(${DOXYGEN_DOXYFILE_IN_LOCATION} ${CMAKE_BINARY_DIR}/Doxyfile.template)
    set(DOXYGEN_DOXYFILE_LOCATION ${CMAKE_BINARY_DIR}/Doxyfile.template)
endif()
 
function(get_doxygen_target_prefix output)
   if(ARGN STREQUAL CMAKE_SOURCE_DIR)
       set(${output} "" PARENT_SCOPE)
   else()
       string(REPLACE ${CMAKE_SOURCE_DIR}/ "" ret ${ARGN})
       string(REPLACE / _ ret "${ret}")
       set(${output} ${ret}_ PARENT_SCOPE)
   endif()
endfunction()
 
function(add_doxygen_target)
    get_doxygen_target_prefix(prefix ${CMAKE_CURRENT_SOURCE_DIR})
    set(target ${prefix}${DOXYGEN_TARGET_SUFFIX})
    if(NOT TARGET ${target})
        set(output ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
        if(DOXYGEN_DOXYFILE_LOCATION)
            set(input ${DOXYGEN_DOXYFILE_LOCATION})
            add_custom_command(OUTPUT ${output} 
                COMMAND ${CMAKE_COMMAND} -E copy ${input} ${output}
                COMMAND ${CMAKE_COMMAND} -E echo INPUT=${CMAKE_CURRENT_SOURCE_DIR} >>${output} 
                COMMAND ${DOXYGEN_EXECUTABLE} -s -u
                DEPENDS ${input})
        else()
            add_custom_command(OUTPUT ${output} 
                COMMAND ${CMAKE_COMMAND} -E echo INPUT=${CMAKE_CURRENT_SOURCE_DIR} >${output} 
                COMMAND ${CMAKE_COMMAND} -E echo RECURSIVE=YES >>${output} 
                COMMAND ${DOXYGEN_EXECUTABLE} -s -u)
        endif()
        add_custom_target(${target} ${DOXYGEN_EXECUTABLE} DEPENDS ${output})
    endif()
endfunction()

function(add_subdirectory)
    _add_subdirectory(${ARGN})
    add_doxygen_target()
endfunction()
function(add_executable)
    _add_executable(${ARGN})
    add_doxygen_target()
endfunction()
function(add_library)
    _add_library(${ARGN})
    add_doxygen_target()
endfunction()
function(add_custom_target)
    _add_custom_target(${ARGN})
    add_doxygen_target()
endfunction()
