# BZip2 (for bspatch)
find_package(BZip2  REQUIRED)

find_package(lz4 CONFIG REQUIRED)
# FP16 for conversions
find_path(FP16_INCLUDE_DIR NAMES fp16.h)

if(DEPTHAI_ENABLE_KOMPUTE)
    find_package(kompute  CONFIG REQUIRED)
endif()

# libarchive for firmware packages
find_package(LibArchive REQUIRED)
find_package(liblzma CONFIG REQUIRED)
# httplib for Gate communication
find_package(httplib CONFIG REQUIRED)
# ZLIB for compressing Apps
find_package(ZLIB REQUIRED)
find_package(Eigen3 CONFIG REQUIRED)

# spdlog for library and device logging
find_package(fmt CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(xtensor CONFIG REQUIRED)
find_package(unofficial-fp16 CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)

# Log collection dependencies
if(DEPTHAI_ENABLE_CURL)
    find_package(CURL CONFIG REQUIRED)
    find_package(cpr CONFIG REQUIRED)
endif()

find_package(yaml-cpp REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
# libnop exports its target without a namespace, so the imported name is plain `libnop`.
find_package(libnop CONFIG REQUIRED)
find_package(semver CONFIG REQUIRED)
find_package(magic_enum CONFIG REQUIRED)
find_package(XLink CONFIG REQUIRED)
set(DEPTHAI_OPENCV_COMPONENTS core imgproc videoio highgui calib3d)
if(DEPTHAI_BUILD_BETA)
    # OpenCV_LIBS lists only the requested components, and REQUIRED_OPENCV_LIBRARIES below is
    # checked against it: an unrequested stitching module switches OpenCV support off entirely.
    list(APPEND DEPTHAI_OPENCV_COMPONENTS features2d stitching)
endif()
find_package(OpenCV 4 REQUIRED COMPONENTS ${DEPTHAI_OPENCV_COMPONENTS})
find_package(cpr CONFIG REQUIRED)
# mcap is NOT resolved as a package. Upstream vendors its headers under
# include/3rdparty/mcap and consumes them header-only behind MCAP_STATIC, so an external
# mcap would be a second copy of the same headers rather than a replacement for them.
find_package(Protobuf CONFIG REQUIRED)


########################
# OpenCV Support 1
########################
set(THIRDPARTY_OPENCV_LIBRARIES "" CACHE STRING "Optional libraries to link OpenCV support, e.g. TBB::tbb")
set(TARGET_OPENCV_NAME ${PROJECT_NAME}-opencv)
set(TARGET_OPENCV_ALIAS opencv)
if(DEPTHAI_OPENCV_SUPPORT)
    set(REQUIRED_OPENCV_LIBRARIES "opencv_core" "opencv_imgproc" "opencv_videoio" "opencv_highgui" "opencv_calib3d")
    if(DEPTHAI_BUILD_BETA)
        list(APPEND REQUIRED_OPENCV_LIBRARIES "opencv_features2d" "opencv_stitching")
    endif()
    set(OPENCV_SUPPORT_AVAILABLE ${OpenCV_FOUND})

    foreach(lib ${REQUIRED_OPENCV_LIBRARIES})
        if(NOT (lib IN_LIST OpenCV_LIBS))
            set(OPENCV_SUPPORT_AVAILABLE FALSE)
        endif()
    endforeach()

    if(OPENCV_SUPPORT_AVAILABLE)
        # Add public compile definition indicating that OpenCV support is available
        set(DEPTHAI_HAVE_OPENCV_SUPPORT ON)
        if(DEPTHAI_BUILD_BETA AND "opencv_stitching" IN_LIST OpenCV_LIBS)
            set(DEPTHAI_HAVE_OPENCV_STITCHING ON)
        endif()

        message(STATUS "OpenCV and required libraries (${REQUIRED_OPENCV_LIBRARIES}) found. OpenCV Support enabled")
    else()
        message(STATUS "OpenCV or required libraries (${REQUIRED_OPENCV_LIBRARIES}) not found. OpenCV Support disabled")
    endif()
endif()




# Create core library
set(TARGET_CORE_SOURCES
    # depthai-bootloader-shared sources
    "${DEPTHAI_BOOTLOADER_SHARED_SOURCES}"
    # sources
    src/common/ModelType.cpp
    src/device/Device.cpp
    src/device/DeviceBase.cpp
    src/device/DeviceBootloader.cpp
    src/device/HealthCheck.cpp
    # src/device/CallbackHandler.cpp
    src/device/CalibrationHandler.cpp
    src/device/Version.cpp
    src/pipeline/Pipeline.cpp
    src/pipeline/PipelineStateApi.cpp
    src/pipeline/AssetManager.cpp
    src/pipeline/MessageQueue.cpp
    src/pipeline/Node.cpp
    src/pipeline/InputQueue.cpp
    src/pipeline/ThreadedNode.cpp
    src/pipeline/ThreadedHostNode.cpp
    src/pipeline/DeviceNode.cpp
    src/pipeline/DeviceNodeGroup.cpp
    src/pipeline/node/internal/PipelineEventAggregation.cpp
    src/pipeline/node/internal/PipelineStateMerge.cpp
    src/pipeline/node/internal/XLinkIn.cpp
    src/pipeline/node/internal/XLinkOut.cpp
    src/pipeline/node/ColorCamera.cpp
    src/pipeline/node/Camera.cpp
    src/pipeline/node/Thermal.cpp
    src/pipeline/node/ToF.cpp
    src/pipeline/node/MessageDemux.cpp
    src/pipeline/node/MonoCamera.cpp
    src/pipeline/node/StereoDepth.cpp
    src/pipeline/node/Sync.cpp
    src/pipeline/node/NeuralNetwork.cpp
    src/pipeline/node/ImageManip.cpp
    src/pipeline/node/Warp.cpp
    src/pipeline/node/VideoEncoder.cpp
    src/pipeline/node/DetectionNetwork.cpp
    src/pipeline/node/Script.cpp
    src/pipeline/node/BenchmarkIn.cpp
    src/pipeline/node/BenchmarkOut.cpp
    src/pipeline/node/SpatialDetectionNetwork.cpp
    src/pipeline/node/SystemLogger.cpp
    src/pipeline/node/SpatialLocationCalculator.cpp
    src/pipeline/node/AprilTag.cpp
    src/pipeline/node/ObjectTracker.cpp
    src/pipeline/node/IMU.cpp
    src/pipeline/node/EdgeDetector.cpp
    src/pipeline/node/SPIIn.cpp
    src/pipeline/node/FeatureTracker.cpp
    src/pipeline/node/Align.cpp
    src/pipeline/node/ImageAlign.cpp
    src/pipeline/node/ToF.cpp
    src/pipeline/node/DetectionParser.cpp
    src/pipeline/node/SegmentationParser.cpp
    src/pipeline/utilities/DetectionParser/DetectionParserUtils.cpp
    src/pipeline/utilities/SpatialLocationCalculator/SpatialUtils.cpp
    src/pipeline/utilities/SegmentationParser/SegmentationParserUtils.cpp
    src/pipeline/node/test/MyProducer.cpp
    src/pipeline/node/test/MyConsumer.cpp
    src/pipeline/node/UVC.cpp
    src/pipeline/node/internal/XLinkInHost.cpp
    src/pipeline/node/internal/XLinkOutHost.cpp
    src/pipeline/node/host/HostNode.cpp
    src/pipeline/node/host/RGBD.cpp
    src/pipeline/node/Vpp.cpp
    src/pipeline/node/Gate.cpp
    src/pipeline/datatype/DatatypeEnum.cpp
    src/pipeline/datatype/ADataType.cpp
    src/pipeline/node/PointCloud.cpp
    src/pipeline/node/NeuralDepth.cpp
    src/pipeline/node/Depth.cpp
    src/pipeline/node/NeuralAssistedStereo.cpp
    src/beta/node/ToFStereoFusion.cpp
    src/pipeline/node/Rectification.cpp
    src/pipeline/datatype/Buffer.cpp
    src/pipeline/datatype/ImgFrame.cpp
    src/pipeline/datatype/ImgTransformations.cpp
    src/pipeline/datatype/EncodedFrame.cpp
    src/pipeline/datatype/ImgAnnotations.cpp
    src/pipeline/datatype/ImageManipConfig.cpp
    src/pipeline/datatype/ImageFiltersConfig.cpp
    src/pipeline/datatype/ImageAlignConfig.cpp
    src/pipeline/datatype/AlignConfig.cpp
    src/pipeline/datatype/CameraControl.cpp
    src/pipeline/datatype/NNData.cpp
    src/pipeline/datatype/ImgDetectionsT.cpp
    src/pipeline/datatype/SegmentationMask.cpp
    src/pipeline/datatype/ImgDetections.cpp
    src/pipeline/datatype/SpatialImgDetections.cpp
    src/pipeline/datatype/SystemInformation.cpp
    src/pipeline/datatype/SystemInformationRVC4.cpp
    src/pipeline/datatype/StreamMessageParser.cpp
    src/pipeline/datatype/SpatialLocationCalculatorData.cpp
    src/pipeline/datatype/SpatialLocationCalculatorConfig.cpp
    src/pipeline/datatype/SegmentationParserConfig.cpp
    src/pipeline/datatype/AprilTags.cpp
    src/pipeline/datatype/AprilTagConfig.cpp
    src/pipeline/datatype/Tracklets.cpp
    src/pipeline/datatype/IMUData.cpp
    src/pipeline/datatype/StereoDepthConfig.cpp
    src/pipeline/datatype/NeuralDepthConfig.cpp
    src/pipeline/datatype/EdgeDetectorConfig.cpp
    src/pipeline/datatype/TrackedFeatures.cpp
    src/pipeline/datatype/FeatureTrackerConfig.cpp
    src/pipeline/datatype/ToFConfig.cpp
    src/pipeline/datatype/BenchmarkReport.cpp
    src/pipeline/datatype/PointCloudConfig.cpp
    src/pipeline/datatype/ObjectTrackerConfig.cpp
    src/pipeline/datatype/PointCloudData.cpp
    src/pipeline/datatype/PipelineEvent.cpp
    src/pipeline/datatype/PipelineState.cpp
    src/pipeline/datatype/PipelineEventAggregationConfig.cpp
    src/pipeline/datatype/RGBDData.cpp
    src/pipeline/datatype/MapData.cpp
    src/pipeline/datatype/MessageGroup.cpp
    src/pipeline/datatype/ThermalConfig.cpp
    src/pipeline/datatype/TransformData.cpp
    src/pipeline/datatype/PacketizedData.cpp
    src/properties/Properties.cpp
    src/capabilities/Capabilities.cpp
    src/pipeline/datatype/VppConfig.cpp
    src/pipeline/datatype/GateControl.cpp
    src/utility/H26xParsers.cpp
    src/utility/ImageManipImpl.cpp
    src/utility/ObjectTrackerImpl.cpp
    src/utility/Memory.cpp
    src/utility/VectorMemory.cpp
    src/utility/SharedMemory.cpp
    src/utility/ProtoSerializable.cpp
    src/utility/Initialization.cpp
    src/utility/Resources.cpp
    src/utility/Platform.cpp
    src/utility/PipelineEventDispatcher.cpp
    src/utility/PipelineImplHelper.cpp
    src/utility/RecordReplay.cpp
    src/utility/McapImpl.cpp
    src/utility/Environment.cpp
    src/utility/Compression.cpp
    src/utility/XLinkGlobalProfilingLogger.cpp
    src/utility/Logging.cpp
    src/utility/Checksum.cpp
    src/utility/matrixOps.cpp
    src/utility/EepromDataParser.cpp
    src/utility/LogCollection.cpp
    src/utility/MemoryWrappers.cpp
    src/utility/Serialization.cpp
    src/utility/OCVPorts.cpp
    src/xlink/XLinkConnection.cpp
    src/xlink/XLinkStream.cpp
    src/openvino/OpenVINO.cpp
    src/openvino/BlobReader.cpp
    src/bspatch/bspatch.c
    src/device/DeviceGate.cpp
    src/utility/ArchiveUtil.cpp
    src/nn_archive/NNArchive.cpp
    src/nn_archive/NNArchiveVersionedConfig.cpp
    src/modelzoo/Zoo.cpp
    # Added in depthai 3.6.1 / 3.7.1
    src/device/CrashDump.cpp
    src/device/CrashDumpManager.cpp
    src/device/Platform.cpp
    src/pipeline/datatype/Extrinsics.cpp
    src/pipeline/datatype/Transformable.cpp
    src/pipeline/datatype/GPUStereoConfig.cpp
    src/pipeline/node/GPUStereo.cpp
    src/pipeline/utilities/Alignment/AlignmentUtilities.cpp
    src/utility/Telemetry.cpp
    src/utility/Uuid.cpp
)

if(DEPTHAI_BUILD_BETA)
    list(APPEND TARGET_CORE_SOURCES
        src/beta/BetaNode.cpp
        src/beta/datatype/Classifications.cpp
        src/beta/datatype/Clusters.cpp
        src/beta/datatype/ImgDetectionsFilterConfig.cpp
        src/beta/datatype/Keypoints.cpp
        src/beta/datatype/Lines.cpp
        src/beta/datatype/Map2D.cpp
        src/beta/datatype/Predictions.cpp
        src/beta/datatype/ClassificationSequenceParserConfig.cpp
        src/beta/datatype/FastSAMParserConfig.cpp
        src/beta/datatype/HRNetParserConfig.cpp
        src/beta/datatype/MLSDParserConfig.cpp
        src/beta/datatype/MPPalmDetectionParserConfig.cpp
        src/beta/datatype/MapOutputParserConfig.cpp
        src/beta/datatype/PPTextDetectionParserConfig.cpp
        src/beta/datatype/RFDETRParserConfig.cpp
        src/beta/datatype/SCRFDParserConfig.cpp
        src/beta/datatype/SuperAnimalParserConfig.cpp
        src/beta/datatype/XFeatMonoParserConfig.cpp
        src/beta/datatype/XFeatStereoParserConfig.cpp
        src/beta/datatype/YuNetParserConfig.cpp
        src/beta/node/ClassificationParser.cpp
        src/beta/node/ClassificationSequenceParser.cpp
        src/beta/node/EmbeddingsParser.cpp
        src/beta/node/FastSAMParser.cpp
        src/beta/node/HRNetParser.cpp
        src/beta/node/ImageOutputParser.cpp
        src/beta/node/ImgDetectionsFilter.cpp
        src/beta/node/KeypointParser.cpp
        src/beta/node/LaneDetectionParser.cpp
        src/beta/node/MapOutputParser.cpp
        src/beta/node/MLSDParser.cpp
        src/beta/node/MPPalmDetectionParser.cpp
        src/beta/node/PPTextDetectionParser.cpp
        src/beta/node/RegressionParser.cpp
        src/beta/node/RFDETRParser.cpp
        src/beta/node/SCRFDParser.cpp
        src/beta/node/SuperAnimalParser.cpp
        src/beta/node/Stitching.cpp
        src/beta/node/XFeatMonoParser.cpp
        src/beta/node/XFeatStereoParser.cpp
        src/beta/node/YuNetParser.cpp
        src/beta/properties/ImgDetectionsFilterProperties.cpp
        src/beta/utilities/Classification/ClassificationUtils.cpp
        src/beta/utilities/Detection/DetectionUtils.cpp
        src/beta/utilities/Detection/MaskUtils.cpp
        src/beta/utilities/FastSAM/FastSAMUtils.cpp
        src/beta/utilities/Keypoints/KeypointsUtils.cpp
        src/beta/utilities/LaneDetection/LaneDetectionUtils.cpp
        src/beta/utilities/MediaPipe/MediaPipeUtils.cpp
        src/beta/utilities/MLSD/MLSDUtils.cpp
        src/beta/utilities/PPText/PPTextUtils.cpp
        src/beta/utilities/RFDETR/RFDETRUtils.cpp
        src/beta/utilities/SCRFD/SCRFDUtils.cpp
        src/beta/utilities/XFeat/XFeatUtils.cpp
        src/beta/utilities/YuNet/YuNetUtils.cpp
    )
endif()

if(DEPTHAI_ENABLE_EVENTS_MANAGER)
    list(APPEND TARGET_CORE_SOURCES
        src/utility/EventsManager.cpp
    )
endif()

if(DEPTHAI_ENABLE_REMOTE_CONNECTION)
    list(APPEND TARGET_CORE_SOURCES
        src/remote_connection/RemoteConnection.cpp
        src/remote_connection/RemoteConnectionImpl.cpp
    )
endif()

if(DEPTHAI_ENABLE_PROTOBUF)
    list(APPEND TARGET_CORE_SOURCES
        src/utility/ProtoSerialize.cpp
    )
endif()

if(DEPTHAI_DYNAMIC_CALIBRATION_SUPPORT)
    list(APPEND TARGET_CORE_SOURCES
        src/pipeline/node/DynamicCalibrationNode.cpp
        src/pipeline/datatype/DynamicCalibrationResults.cpp
        src/pipeline/datatype/DynamicCalibrationControl.cpp
        # Added in depthai 3.6.1 / 3.7.1
        src/pipeline/node/AutoCalibration.cpp
        src/pipeline/datatype/AutoCalibrationResult.cpp
        src/pipeline/datatype/AutoCalibrationConfig.cpp
    )
endif()

set(TARGET_OPENCV_SOURCES
    src/opencv/ColorizeDepthFrame.cpp
    src/opencv/ImgFrame.cpp
    src/pipeline/node/host/Display.cpp
    src/pipeline/node/host/HostCamera.cpp
    src/pipeline/node/host/Record.cpp
    src/pipeline/node/host/Replay.cpp
    src/pipeline/node/ImageFilters.cpp
    src/opencv/RecordReplay.cpp
    src/opencv/HolisticRecordReplay.cpp
)

if(DEPTHAI_BUILD_BETA AND DEPTHAI_HAVE_OPENCV_SUPPORT)
    list(APPEND TARGET_OPENCV_SOURCES
        src/beta/utilities/Stitching/Stitching.cpp
        src/beta/utilities/Stitching/FixedPanoramaCompositor.cpp
        src/beta/utilities/Stitching/PlanarStitcher.cpp
    )
endif()

set(TARGET_PCL_SOURCES src/pcl/PointCloudData.cpp)

set(TARGET_BASALT_SOURCES src/basalt/BasaltVIO.cpp)

set(TARGET_RTABMAP_SOURCES
    src/rtabmap/RTABMapConversions.cpp
    src/rtabmap/RTABMapVIO.cpp
    src/rtabmap/RTABMapSLAM.cpp
)

if(DEPTHAI_HAVE_OPENCV_SUPPORT AND DEPTHAI_MERGED_TARGET)
    list(APPEND TARGET_CORE_SOURCES
        ${TARGET_OPENCV_SOURCES}
    )
endif()

if(DEPTHAI_HAVE_PCL_SUPPORT AND DEPTHAI_MERGED_TARGET)
    list(APPEND TARGET_CORE_SOURCES
        ${TARGET_PCL_SOURCES}
    )
endif()

if(DEPTHAI_HAVE_BASALT_SUPPORT AND DEPTHAI_MERGED_TARGET)
    list(APPEND TARGET_CORE_SOURCES
        ${TARGET_BASALT_SOURCES}
    )
endif()

if(DEPTHAI_HAVE_RTABMAP_SUPPORT AND DEPTHAI_MERGED_TARGET)
    list(APPEND TARGET_CORE_SOURCES
        ${TARGET_RTABMAP_SOURCES}
    )
endif()

if(DEPTHAI_GENERATE_HOUSING_COORDS)
    include(DepthaiGenerateHousingCoordinates)
    DepthaiGenerateHousingCoordinates(
        ${CMAKE_CURRENT_BINARY_DIR}/HousingCoordinates.cpp        # Output file
        ${CMAKE_CURRENT_LIST_DIR}/shared/depthai_boards/batch/housing # Housing json directory
    )
    list(APPEND TARGET_CORE_SOURCES
        ${CMAKE_CURRENT_BINARY_DIR}/HousingCoordinates.cpp
    )
endif()

target_sources(${TARGET_CORE_NAME} PRIVATE ${TARGET_CORE_SOURCES})

#add_library(${TARGET_CORE_NAME} ${TARGET_CORE_SOURCES})
#add_library("${PROJECT_NAME}::${TARGET_CORE_ALIAS}" ALIAS ${TARGET_CORE_NAME})
# Specify that we are building core
target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_TARGET_CORE)
if(DEPTHAI_BUILD_BETA)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_HAVE_BETA)
endif()
if(DEPTHAI_BUILD_BETA AND DEPTHAI_HAVE_OPENCV_STITCHING)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_HAVE_OPENCV_STITCHING)
endif()
# Specifies name of generated IMPORTED target (set to alias)
set_target_properties(${TARGET_CORE_NAME} PROPERTIES EXPORT_NAME ${TARGET_CORE_ALIAS})
# Add to list of targets to export and install
list(APPEND targets_to_export ${TARGET_CORE_NAME})


# Set compiler features (c++17), and disables extensions (g++17)
#set_property(TARGET ${TARGET_CORE_NAME} PROPERTY CXX_STANDARD 17)
#set_property(TARGET ${TARGET_CORE_NAME} PROPERTY CXX_STANDARD_REQUIRED ON)
#set_property(TARGET ${TARGET_CORE_NAME} PROPERTY CXX_EXTENSIONS OFF)
# Add interface transitive property (C++23)
target_compile_features(${TARGET_CORE_NAME} INTERFACE cxx_std_23)


# Add include directories
target_include_directories(${TARGET_CORE_NAME}
  PUBLIC
  # Relative path to include directories after installed
  "$<INSTALL_INTERFACE:include>"
  "$<INSTALL_INTERFACE:include/${DEPTHAI_SHARED_3RDPARTY_HEADERS_PATH}>"

  # Build time path to include directories
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>"
  "$<BUILD_INTERFACE:${DEPTHAI_SHARED_PUBLIC_INCLUDE}>"
  "$<BUILD_INTERFACE:${DEPTHAI_BOOTLOADER_SHARED_PUBLIC_INCLUDE}>"
  #INTERFACE
  #    # ...
  PRIVATE
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include/depthai>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include/depthai>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/src>"
  "$<BUILD_INTERFACE:${DEPTHAI_SHARED_INCLUDE}>"
  "$<BUILD_INTERFACE:${DEPTHAI_BOOTLOADER_SHARED_INCLUDE}>"
)

target_include_directories(${TARGET_CORE_NAME} SYSTEM
    PUBLIC
        "$<BUILD_INTERFACE:${DEPTHAI_SHARED_3RDPARTY_INCLUDE}>"
)

# link libraries
target_link_libraries(${TARGET_CORE_NAME}
    PUBLIC
        nlohmann_json::nlohmann_json
        # libnop is PUBLIC because depthai/utility/Serialization.hpp includes nop/ headers, so
        # every consumer compiles against them. Declaring it is not cosmetic: without the
        # usage requirement it resolves only where a package manager happens to put every
        # package's headers on one include path, and fails anywhere else.
        libnop
    INTERFACE
        XLinkPublic
    PRIVATE
        fmt::fmt
        yaml-cpp::yaml-cpp
        spdlog::spdlog
        XLink
        Threads::Threads
        BZip2::BZip2
        LibArchive::LibArchive
        ZLIB::ZLIB
        httplib::httplib
        semver::semver
        magic_enum::magic_enum
        liblzma::liblzma
        lz4::lz4
        Eigen3::Eigen
)

if (LINUX)
    target_link_libraries(${TARGET_CORE_NAME} PUBLIC udev)
endif()

if(DEPTHAI_ENABLE_MP4V2)
    message(STATUS "DepthAI recording enabled, finding the mp4v2 library!")
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE mp4v2::mp4v2)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_MP4V2)
endif()

if(DEPTHAI_ENABLE_PROTOBUF)
    # Load protobuf support into library messages_proto
    message(STATUS "Protobuf support enabled")
    add_subdirectory(protos)
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE protobuf::libprotobuf messages)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_ENABLE_PROTOBUF)
endif()

if(DEPTHAI_ENABLE_REMOTE_CONNECTION)
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE
        foxglove-websocket::foxglove-websocket
    )
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_REMOTE_CONNECTION)
endif()

if(DEPTHAI_HAS_APRIL_TAG)
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE
        apriltag::apriltag
    )
endif()

if(DEPTHAI_ENABLE_CURL)
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE
        CURL::libcurl
        cpr::cpr
    )
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_CURL)
endif()



# Add compile & CMake definitions
set(DEPTHAI_DEVICE_VERSION "${DEPTHAI_DEVICE_SIDE_COMMIT}")
target_compile_definitions(${TARGET_CORE_NAME}
    PRIVATE
        # Add depthai-device version
        DEPTHAI_DEVICE_VERSION="${DEPTHAI_DEVICE_VERSION}"
        # Add depthai-bootloader version
        DEPTHAI_BOOTLOADER_VERSION="${DEPTHAI_BOOTLOADER_VERSION}"
        # Add depthai-device-kb version
        DEPTHAI_DEVICE_RVC3_VERSION="${DEPTHAI_DEVICE_RVC3_VERSION}"
        # Add depthai-device-rvc4 version
        DEPTHAI_DEVICE_RVC4_VERSION="${DEPTHAI_DEVICE_RVC4_VERSION}"
)



# Add compile flag if libusb is available
if(DEPTHAI_ENABLE_LIBUSB)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_LIBUSB)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_HAVE_LIBUSB_SUPPORT)
    set(DEPTHAI_HAVE_LIBUSB_SUPPORT ON)
endif()

if(DEPTHAI_XTENSOR_SUPPORT)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_XTENSOR_SUPPORT)
    target_link_libraries(${TARGET_CORE_NAME} PUBLIC xtensor)
endif()

# Specify available FW
if(DEPTHAI_ENABLE_DEVICE_FW)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_DEVICE_FW)
endif()
if(DEPTHAI_ENABLE_DEVICE_BOOTLOADER_FW)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_DEVICE_BOOTLOADER_FW)
endif()
if(DEPTHAI_ENABLE_DEVICE_RVC3_FW)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_DEVICE_RVC3_FW)
endif()
if(DEPTHAI_ENABLE_DEVICE_RVC4_FW)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_DEVICE_RVC4_FW)
endif()
if(DEPTHAI_EMBED_FRONTEND)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_EMBED_FRONTEND)
endif()
if(DEPTHAI_HAS_APRIL_TAG)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_HAS_APRIL_TAG)
endif()

# Add Backward dependency if enabled (On by default)
if(DEPTHAI_ENABLE_BACKWARD)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_ENABLE_BACKWARD)
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE Backward::Backward)
endif()

# Add patch only mode definition
if(DEPTHAI_USB2_PATCH_ONLY_MODE)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_PATCH_ONLY_MODE)
endif()

if(DEPTHAI_INTERNAL_DEVICE_BUILD_RVC4)
    target_compile_definitions(${TARGET_CORE_NAME} PRIVATE DEPTHAI_INTERNAL_DEVICE_BUILD_RVC4)
endif()

# Link merged target libraries and add compile definitions
if(DEPTHAI_HAVE_OPENCV_SUPPORT AND DEPTHAI_MERGED_TARGET)
    # Link to OpenCV (publically)
    target_link_libraries(${TARGET_CORE_NAME} PUBLIC ${REQUIRED_OPENCV_LIBRARIES} ${THIRDPARTY_OPENCV_LIBRARIES})

    # Specify that we are building target opencv
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_TARGET_OPENCV)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_HAVE_OPENCV_SUPPORT)

endif()

if(DEPTHAI_HAVE_PCL_SUPPORT AND DEPTHAI_MERGED_TARGET)
    # Link to PCL (publically)
    target_link_libraries(${TARGET_CORE_NAME} PUBLIC ${PCL_LIBRARIES})

    # Specify that we are building target pcl
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_TARGET_PCL)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_HAVE_PCL_SUPPORT)
    target_link_directories(${TARGET_CORE_NAME} PUBLIC
      $<BUILD_INTERFACE:${PCL_LIBRARY_DIRS}>
      $<INSTALL_INTERFACE:include>
    )
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC ${PCL_DEFINITIONS})
endif()

if(DEPTHAI_HAVE_RTABMAP_SUPPORT AND DEPTHAI_MERGED_TARGET)
    # Link to rtabmap
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE rtabmap::core ${THIRDPARTY_RTABMAP_LIBRARIES})

    # add compile defs
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_TARGET_RTABMAP)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_HAVE_RTABMAP_SUPPORT)
    add_flag(${TARGET_CORE_NAME} -Wno-switch-enum)
endif()

if(DEPTHAI_HAVE_BASALT_SUPPORT AND DEPTHAI_MERGED_TARGET)
    # Link to Basalt
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE ${THIRDPARTY_BASALT_LIBRARIES})

    # add compile defs
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_TARGET_BASALT)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_HAVE_BASALT_SUPPORT)
endif()

if(DEPTHAI_MERGED_TARGET)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_MERGED_TARGET)
endif()

if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC MCAP_STATIC)
endif()

if(DEPTHAI_DYNAMIC_CALIBRATION_SUPPORT)
    # Link the dynamic calibration target
    target_link_libraries(${TARGET_CORE_NAME} PRIVATE dynamic_calibration_imported)
    target_compile_definitions(${TARGET_CORE_NAME} PUBLIC DEPTHAI_HAVE_DYNAMIC_CALIBRATION_SUPPORT)
endif()




########################
# OpenCV Support 2
########################
if(DEPTHAI_HAVE_OPENCV_SUPPORT AND NOT DEPTHAI_MERGED_TARGET)
    # Add depthai-core-opencv library and depthai::core::opencv alias
    add_library(${TARGET_OPENCV_NAME}
      ${TARGET_OPENCV_SOURCES}
    )
    add_library("${PROJECT_NAME}::${TARGET_OPENCV_ALIAS}" ALIAS ${TARGET_OPENCV_NAME})
    # Specifies name of generated IMPORTED target (set to alias)
    set_target_properties(${TARGET_OPENCV_NAME} PROPERTIES EXPORT_NAME ${TARGET_OPENCV_ALIAS})

    # Add default flags
    add_default_flags(${TARGET_OPENCV_NAME})

    # Link to OpenCV (publically)
    target_link_libraries(${TARGET_OPENCV_NAME} PUBLIC ${REQUIRED_OPENCV_LIBRARIES} ${THIRDPARTY_OPENCV_LIBRARIES})

    # Specify that we are building target opencv
    target_compile_definitions(${TARGET_OPENCV_NAME} PUBLIC DEPTHAI_TARGET_OPENCV)
    target_compile_definitions(${TARGET_OPENCV_NAME} PUBLIC DEPTHAI_HAVE_OPENCV_SUPPORT)
    if(DEPTHAI_BUILD_BETA AND DEPTHAI_HAVE_OPENCV_STITCHING)
        target_compile_definitions(${TARGET_OPENCV_NAME} PUBLIC DEPTHAI_HAVE_OPENCV_STITCHING)
    endif()
    # Add public dependency to depthai::core library
    target_link_libraries(${TARGET_OPENCV_NAME} PUBLIC ${TARGET_CORE_NAME})

    # Add to clangformat target
    if(COMMAND target_clangformat_setup)
        target_clangformat_setup(${TARGET_OPENCV_NAME} "")
    endif()

    # Add to list of targets to export and install
    list(APPEND targets_to_export ${TARGET_OPENCV_NAME})
endif()



if (APPLE AND NOT IOS)
    find_library(COREFOUNDATION_LIBRARY CoreFoundation)
    find_library(COCOA_LIBRARY Cocoa)
    find_library(IOKIT_LIBRARY IOKit)
    find_library(SECURITY_LIBRARY Security)

    target_link_libraries(${TARGET_CORE_NAME}
      PRIVATE
          ${COCOA_LIBRARY}
          ${COREFOUNDATION_LIBRARY}
          ${IOKIT_LIBRARY}
          ${SECURITY_LIBRARY}
    )
endif()




########################
# Build configuration
########################
# Add year information
string(TIMESTAMP BUILD_DATETIME "%Y-%m-%d %H:%M:%S +0000" UTC)
message(STATUS "BUILD_DATETIME: ${BUILD_DATETIME}, BUILD_COMMIT: ${BUILD_COMMIT}, BUILD_COMMIT_DATETIME: ${BUILD_COMMIT_DATETIME}")

# Configure build information (version, opencv, pcl support)
set(DEPTHAI_VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/include/depthai/build/version.hpp")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/depthai/build")
configure_file(
  "${PROJECT_SOURCE_DIR}/cmake/version.hpp.in"
  "${DEPTHAI_VERSION_HEADER}"
)




########################
# Export and install
########################
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Add additional targets to export group
if(NOT BUILD_SHARED_LIBS)
     list(APPEND targets_to_export ${DEPTHAI_RESOURCE_LIBRARY_NAME} cmrc-base)
     if(DEPTHAI_ENABLE_PROTOBUF)
         list(APPEND targets_to_export messages)
     endif()
     if(DEPTHAI_ENABLE_REMOTE_CONNECTION)
#         list(APPEND targets_to_export foxglove_websocket)
     endif()
endif()

# Export targets (capability to import current build directory)
export(TARGETS ${targets_to_export} NAMESPACE ${PROJECT_NAME}:: FILE "${PROJECT_NAME}Targets.cmake")

# Dependencies file
configure_file("../cmake/${PROJECT_NAME}Dependencies.cmake" ${PROJECT_NAME}Dependencies.cmake COPYONLY)

# Write project version
write_basic_package_version_file(${PROJECT_NAME}ConfigVersion.cmake VERSION ${PROJECT_VERSION} COMPATIBILITY AnyNewerVersion)

# Configure config file (one for exporting build directory, one for installation)
configure_file(../cmake/${PROJECT_NAME}Config.cmake.in ${PROJECT_NAME}Config.cmake @ONLY)

# Config for installation
set(DEPTHAI_DEPENDENCIES_INSTALLATION_PATH_REL "./dependencies")
configure_file(../cmake/${PROJECT_NAME}Config.cmake.in _install/${PROJECT_NAME}Config.cmake @ONLY)

# Modify RPath to point to the cmake/depthai/dependencies/lib
# note: macOS is APPLE and also UNIX!
if(APPLE)
    set_target_properties(${TARGET_CORE_NAME} PROPERTIES INSTALL_RPATH "@loader_path;@loader_path/")
elseif(UNIX)
    set_target_properties(${TARGET_CORE_NAME} PROPERTIES INSTALL_RPATH "$ORIGIN:$ORIGIN/")
endif()

# Export to CMake registry if specified
if(CMAKE_EXPORT_PACKAGE_REGISTRY)
    export(PACKAGE depthai)
endif()

if(DEPTHAI_INSTALL)
    # Install targets
    install(
      TARGETS ${targets_to_export}
      EXPORT ${PROJECT_EXPORT_GROUP}
      RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
      LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    )

    # Install depthai public headers
    install(DIRECTORY include/depthai DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
    install(FILES "${DEPTHAI_VERSION_HEADER}" DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/depthai/build")
    # Install depthai-bootloader-shared public headers
    install(DIRECTORY "${DEPTHAI_BOOTLOADER_SHARED_PUBLIC_INCLUDE}/" DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
    # Install resources if not RC'd
    if(NOT DEPTHAI_BINARIES_RESOURCE_COMPILE)
        install(DIRECTORY "${DEPTHAI_RESOURCES_OUTPUT_DIR}/" DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}")
    endif()
    # Install any required dll files
    if(DEFINED required_dll_files)
        set(DLL_INSTALLATION_DIR "${CMAKE_INSTALL_LIBDIR}")
        if(WIN32)
            set(DLL_INSTALLATION_DIR "${CMAKE_INSTALL_BINDIR}")
        endif()
        message(STATUS "Required dlls for core are: ${required_dll_files} and they will be installed to ${DLL_INSTALLATION_DIR}")
        install(FILES ${required_dll_files} DESTINATION "${DLL_INSTALLATION_DIR}")
    endif()

    # Install export group (information about targets)
    install(EXPORT ${PROJECT_EXPORT_GROUP}
      NAMESPACE ${PROJECT_NAME}::
      DESTINATION "share/${PROJECT_NAME}"
    )

    # Install CMake specific files
    install(FILES
      "${CMAKE_CURRENT_BINARY_DIR}/_install/${PROJECT_NAME}Config.cmake"
      "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
      DESTINATION "share/${PROJECT_NAME}"
    )

endif()

