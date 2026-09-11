# Fetches the device-side firmware, bootloader, RVC3/RVC4 firmware and visualizer blobs,
# then optionally resource-compiles them into the core library.
# Extracted verbatim from the upstream root CMakeLists.txt so the root file can stay small;
# every download stays an anonymous HTTPS fetch checked against a published sha256.
macro(FetchResources)
# Set constant
set(DEPTHAI_RESOURCES_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/resources")

# Include configuration
include(Depthai/DepthaiDeviceSideConfig)    # Depthai device binary commit/version configuration
include(Depthai/DepthaiBootloaderConfig)    # Depthai bootloader binary commit/version configuration
include(Depthai/DepthaiDeviceKbConfig)      # depthai-device-kb fwp commit/version configuration
include(Depthai/DepthaiDeviceRVC4Config)    # depthai-device-rvc4 fwp commit/version configuration
include(Depthai/DepthaiVisualizerConfig)    # depthai-visualizer commit/version configuration

# Include downloaders
include(DepthaiDownloader)                  # Depthai device binary downloader
include(DepthaiBootloaderDownloader)        # Depthai bootloader binary downloader
include(DepthaiDeviceKbDownloader)          # depthai-device-kb fwp downloader
include(DepthaiVisualizerDownloader)        # depthai-visualizer downloader

# depthai-shared enforce commit hash match if CI
if($ENV{CI})
    # TODO(themarpe) - Disable before final merge
    # set(DEPTHAI_SHARED_COMMIT_HASH_ENFORCE ON)
    set(DEPTHAI_SHARED_COMMIT_HASH_ENFORCE OFF)
    set(DEPTHAI_BOOTLOADER_SHARED_COMMIT_HASH_ENFORCE ON)
endif()

# No user specified paths, download from server
message(STATUS "Downloading Depthai device side binaries from server...")

# Then get the Depthai device side binaries (local or download)
if(DEPTHAI_CMD_PATH OR DEPTHAI_USB2_CMD_PATH OR DEPTHAI_USB2_PATCH_PATH)
    # At least one of the paths is set. include binaries locally
    message(STATUS "Using local Depthai device side binaries...")

    DepthaiLocal(
        PATCH_ONLY ${DEPTHAI_USB2_PATCH_ONLY_MODE}
        "${DEPTHAI_RESOURCES_OUTPUT_DIR}"            # Output folder
        DEPTHAI_RESOURCE_LIST                       # List of output resources
        "${DEPTHAI_CMD_PATH}"                       # depthai.cmd
        "${DEPTHAI_USB2_CMD_PATH}"                  # depthai-usb2.cmd
        "${DEPTHAI_USB2_PATCH_PATH}"                # depthai-usb2-patch.patch
    )

else()
    # No user specified paths, download from server
    message(STATUS "Downloading Depthai device side binaries from server...")
endif()

if(DEPTHAI_ENABLE_DEVICE_FW)
    # Add device FW

    DepthaiDownload(
        "${DEPTHAI_SHARED_COMMIT_HASH}" "${DEPTHAI_SHARED_COMMIT_HASH_ENFORCE}"
        PATCH_ONLY ON
        "${DEPTHAI_RESOURCES_OUTPUT_DIR}"            # Output folder
        DEPTHAI_RESOURCE_LIST                       # List of output resources
        "${DEPTHAI_DEVICE_SIDE_MATURITY}"           # Maturity
        "${DEPTHAI_DEVICE_SIDE_COMMIT}"             # commit hash
        "${DEPTHAI_DEVICE_SIDE_VERSION}"            # Optional version
    )
    list(APPEND RESOURCE_COMPILED_FILES ${DEPTHAI_RESOURCE_LIST})
endif()

if(DEPTHAI_ENABLE_DEVICE_BOOTLOADER_FW)
    # Add bootloader FW
    DepthaiBootloaderDownload(
        "${DEPTHAI_BOOTLOADER_SHARED_COMMIT_HASH}" "${DEPTHAI_BOOTLOADER_SHARED_COMMIT_HASH_ENFORCE}"
        "${DEPTHAI_RESOURCES_OUTPUT_DIR}"                # Output folder
        DEPTHAI_BOOTLOADER_RESOURCE_LIST                # List of output resources
        "${DEPTHAI_BOOTLOADER_MATURITY}"                # Maturity
        "${DEPTHAI_BOOTLOADER_VERSION}"                 # if maturity == snapshot -> hash else version
    )
    list(APPEND RESOURCE_COMPILED_FILES ${DEPTHAI_BOOTLOADER_RESOURCE_LIST})
endif()

if(DEPTHAI_ENABLE_DEVICE_RVC3_FW)
    # Add device-kb FW
    DepthaiDeviceDownloader(
        "depthai-device-kb"
        "luxonis-keembay-snapshot-local"
        "luxonis-keembay-release-local"
        "${DEPTHAI_SHARED_COMMIT_HASH}" "${DEPTHAI_SHARED_COMMIT_HASH_ENFORCE}"
        "${DEPTHAI_RESOURCES_OUTPUT_DIR}"                # Output folder
        DEPTHAI_DEVICE_KB_RESOURCE_LIST                 # List of output resources
        "${DEPTHAI_DEVICE_KB_MATURITY}"                # Maturity
        "${DEPTHAI_DEVICE_RVC3_VERSION}"
    )
    list(APPEND RESOURCE_COMPILED_FILES ${DEPTHAI_DEVICE_KB_RESOURCE_LIST})
endif()

if(DEPTHAI_ENABLE_DEVICE_RVC4_FW)
    if(DEPTHAI_SANITIZE AND SANITIZE_THREAD)
        string(APPEND DEPTHAI_DEVICE_RVC4_VERSION "-tsan")
    elseif(DEPTHAI_SANITIZE)
        string(APPEND DEPTHAI_DEVICE_RVC4_VERSION "-asan-ubsan")
    endif()

    # Add device-RVC4 FW
    DepthaiDeviceDownloader(
        "depthai-device-rvc4"
        "luxonis-rvc4-snapshot-local"
        "luxonis-rvc4-release-local"
        "${DEPTHAI_SHARED_COMMIT_HASH}" "${DEPTHAI_SHARED_COMMIT_HASH_ENFORCE}"
        "${DEPTHAI_RESOURCES_OUTPUT_DIR}"                # Output folder
        DEPTHAI_DEVICE_RVC4_RESOURCE_LIST                 # List of output resources
        "${DEPTHAI_DEVICE_RVC4_MATURITY}"                # Maturity
        "${DEPTHAI_DEVICE_RVC4_VERSION}"
    )
    list(APPEND RESOURCE_COMPILED_FILES ${DEPTHAI_DEVICE_RVC4_RESOURCE_LIST})
endif()


if(DEPTHAI_EMBED_FRONTEND)
    DepthaiVisualizerDownloader(
        "${DEPTHAI_VISUALIZER_COMMIT}"                # Visualizer hash
        "${DEPTHAI_RESOURCES_OUTPUT_DIR}"
        DEPTHAI_VISUALIZER_RESOURCE_LIST                 # List of output resources
    )
    list(APPEND RESOURCE_COMPILED_FILES ${DEPTHAI_VISUALIZER_RESOURCE_LIST}) # TODO - Handle the case non debug case
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_VISUALIZER_VERSION="${DEPTHAI_VISUALIZER_COMMIT}")
endif()

message(STATUS "LIST OF RESOURCE COMPILED FILES: ${RESOURCE_COMPILED_FILES}")
if(DEPTHAI_BINARIES_RESOURCE_COMPILE)
    # Add RC and resource compile the binares
    include(CMakeRC)

    set(DEPTHAI_RESOURCE_LIBRARY_NAME "depthai-resources")

    # Add resource library
    cmrc_add_resource_library("${DEPTHAI_RESOURCE_LIBRARY_NAME}" NAMESPACE depthai
        WHENCE "${DEPTHAI_RESOURCES_OUTPUT_DIR}"
        "${RESOURCE_COMPILED_FILES}"
    )

    # Link to resource library
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE "${DEPTHAI_RESOURCE_LIBRARY_NAME}")

    # Set define that binaries are resource compiled
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_RESOURCE_COMPILED_BINARIES)

else()
    # TODO
    # Don't add RC and don't resource compile the binaries
    # Install to share/ instead for instance
endif()

endmacro()
