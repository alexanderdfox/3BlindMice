cmake_minimum_required(VERSION 3.10)
project(ThreeBlindMice)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Windows-specific settings
if(WIN32)
    # Enable Unicode
    add_definitions(-DUNICODE -D_UNICODE)
    
    # Set subsystem to console for CLI version
    set(CMAKE_WIN32_EXECUTABLE TRUE)
endif()

# Find Swift
find_program(SWIFT_EXECUTABLE swift)
if(NOT SWIFT_EXECUTABLE)
    message(FATAL_ERROR "Swift not found. Please install Swift for Windows.")
endif()

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/cpp)

# C++ source files
set(CPP_SOURCES
    src/cpp/hid_manager.cpp
    src/cpp/display_manager.cpp
)

# Create C++ library
add_library(ThreeBlindMiceLib STATIC ${CPP_SOURCES})

# Link Windows libraries
target_link_libraries(ThreeBlindMiceLib
    user32
    kernel32
    advapi32
)

# Swift source files
set(SWIFT_SOURCES
    src/swift/main.swift
    src/swift/MultiMouseManager.swift
    src/swift/DisplayManager.swift
    src/hipaa/HIPAASecurity.swift
    src/hipaa/HIPAADataManager.swift
)

# Create Swift executable
add_executable(ThreeBlindMice ${SWIFT_SOURCES})

# Link with C++ library
target_link_libraries(ThreeBlindMice ThreeBlindMiceLib)

# Set output directory
set_target_properties(ThreeBlindMice PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# Copy Swift runtime libraries
if(WIN32)
    # Find Swift runtime directory
    execute_process(
        COMMAND ${SWIFT_EXECUTABLE} --print-target-info
        OUTPUT_VARIABLE SWIFT_TARGET_INFO
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    # Extract runtime path (simplified - in practice you'd parse the JSON)
    set(SWIFT_RUNTIME_DIR "C:/Program Files/Swift/lib/swift/windows/x86_64")
    
    # Copy runtime DLLs
    file(GLOB SWIFT_DLLS "${SWIFT_RUNTIME_DIR}/*.dll")
    foreach(DLL ${SWIFT_DLLS})
        get_filename_component(DLL_NAME ${DLL} NAME)
        configure_file(${DLL} ${CMAKE_BINARY_DIR}/bin/${DLL_NAME} COPYONLY)
    endforeach()
endif()

# Installation
install(TARGETS ThreeBlindMice
    RUNTIME DESTINATION bin
)

# Create Visual Studio solution
if(WIN32)
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ThreeBlindMice)
endif()

# Print build information
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Swift executable: ${SWIFT_EXECUTABLE}")
message(STATUS "Output directory: ${CMAKE_BINARY_DIR}/bin")
