if(DEPTHAI_BOOTLOADER_SHARED_LOCAL)
    set(DEPTHAI_BOOTLOADER_SHARED_FOLDER ${DEPTHAI_BOOTLOADER_SHARED_LOCAL})
else()
    set(DEPTHAI_BOOTLOADER_SHARED_FOLDER ${CMAKE_CURRENT_LIST_DIR}/depthai-bootloader-shared)
endif()

set(DEPTHAI_BOOTLOADER_SHARED_SOURCES
    ${DEPTHAI_BOOTLOADER_SHARED_FOLDER}/src/SBR.c
    ${DEPTHAI_BOOTLOADER_SHARED_FOLDER}/src/Bootloader.cpp
)

set(DEPTHAI_BOOTLOADER_SHARED_PUBLIC_INCLUDE
    ${DEPTHAI_BOOTLOADER_SHARED_FOLDER}/include
)

set(DEPTHAI_BOOTLOADER_SHARED_INCLUDE
    ${DEPTHAI_BOOTLOADER_SHARED_FOLDER}/src
)

# depthai-bootloader-shared commit hash.
#
# Upstream discovers this by running `git submodule status` and then `git rev-parse HEAD`
# inside the submodule working tree. Neither works here: the sources are vendored as plain
# files, so there is no submodule to interrogate and `git rev-parse HEAD` in that folder
# answers with THIS repository's HEAD -- a hash that looks valid and is wrong. It is fed to
# DepthaiBootloaderDownload() as the value to enforce against, so a wrong-but-plausible hash
# is worse than no hash: with DEPTHAI_BOOTLOADER_SHARED_COMMIT_HASH_ENFORCE on (which CI sets)
# it enforces a match against a hash that has nothing to do with the bootloader.
#
# The commit is a fact about what was vendored, so it is recorded as one. Update this line in
# the same commit that updates the files under depthai-bootloader-shared/.
if(NOT DEPTHAI_BOOTLOADER_SHARED_LOCAL)
    set(DEPTHAI_BOOTLOADER_SHARED_COMMIT_HASH "b287ecbacd3b0c963b5dfcf95767123b0c143b57")
    set(DEPTHAI_BOOTLOADER_SHARED_COMMIT_FOUND TRUE)
else()
    set(DEPTHAI_BOOTLOADER_SHARED_COMMIT_FOUND FALSE)
endif()

# Make sure files exist
foreach(source_file ${DEPTHAI_BOOTLOADER_SHARED_SOURCES})
    if(NOT EXISTS ${source_file})
        message(FATAL_ERROR "depthai-bootloader-shared sources missing at ${DEPTHAI_BOOTLOADER_SHARED_FOLDER}. They are vendored in this repository, so this means the checkout or archive is incomplete.")
    endif()
endforeach()