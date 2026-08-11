cmake_minimum_required(VERSION 3.30)

# Create depthai project
project(depthai VERSION "3.8.0" LANGUAGES CXX C)

set(DEPTHAI_PRE_RELEASE_TYPE "") # Valid options are "alpha", "beta", "rc", ""
set(DEPTHAI_PRE_RELEASE_VERSION "0") # Valid options are "0", "1", "2", ...

# Set DEPTHAI_VERSION universally, not conditionally
if(DEPTHAI_PRE_RELEASE_TYPE STREQUAL "")
    set(DEPTHAI_VERSION ${PROJECT_VERSION})
else()
    set(DEPTHAI_VERSION ${PROJECT_VERSION}-${DEPTHAI_PRE_RELEASE_TYPE}.${DEPTHAI_PRE_RELEASE_VERSION})
endif()

# Add module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake/")

# Force Colored output when using Ninja
# Global option - affects all targets
option(FORCE_COLORED_OUTPUT "Always produce ANSI-colored output (GNU/Clang only)" ON)
if(FORCE_COLORED_OUTPUT)
    if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
       add_compile_options(-fdiagnostics-color=always)
    elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
       add_compile_options(-fcolor-diagnostics)
    endif()
endif()

# Examples are off by default and are not part of the library.
# They pull OpenCV and argparse in on their own, so a consumer building only the library
# never resolves those on the examples' behalf.
option(DEPTHAI_BUILD_EXAMPLES "Build depthai examples" OFF)

### Constants
set(PROJECT_EXPORT_GROUP "${PROJECT_NAME}Targets")

## Check if cloned or sources
find_package(Git)
if(GIT_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --show-toplevel
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        RESULT_VARIABLE _git_root_dir_error
        OUTPUT_VARIABLE _git_root_dir
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(DEPTHAI_DOWNLOADED_SOURCES ON)
    if(_git_root_dir_error EQUAL 0 AND "${_git_root_dir}" STREQUAL "${CMAKE_CURRENT_LIST_DIR}")
        set(DEPTHAI_DOWNLOADED_SOURCES OFF)
    endif()
    message("Git root dir (${_git_root_dir_error}): ${_git_root_dir}")
    message("DepthAI as downloaded sources: ${DEPTHAI_DOWNLOADED_SOURCES}")
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT_VARIABLE BUILD_COMMIT
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} show -s --format=%ci ${BUILD_COMMIT}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT_VARIABLE BUILD_COMMIT_DATETIME
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif()

### Get and find dependencies

# Headers that upstream vendors rather than resolving as packages (mcap, nanorpc).
set(DEPTHAI_SHARED_3RDPARTY_INCLUDE
    ${CMAKE_CURRENT_LIST_DIR}/source/include/3rdparty/
)
# Add depthai-bootloader-shared. Vendored as plain files rather than a git submodule, so that
# a source archive of this repository is complete on its own -- a submodule is absent from
# every tarball GitHub generates, which is what a package manager actually fetches.
include(${CMAKE_CURRENT_LIST_DIR}/shared/depthai-bootloader-shared.cmake)

### End of dependencies

set(TARGET_CORE_NAME ${PROJECT_NAME}-core)
set(TARGET_CORE_ALIAS core)

add_library(${TARGET_CORE_NAME} "")
add_library("${PROJECT_NAME}::${TARGET_CORE_ALIAS}" ALIAS ${TARGET_CORE_NAME})

include(cmake/resources.cmake)
FetchResources()

add_subdirectory(source)

if(DEPTHAI_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
