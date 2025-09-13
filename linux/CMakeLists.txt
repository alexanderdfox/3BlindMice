cmake_minimum_required(VERSION 3.10)

# Force use of system compilers instead of Swift toolchain compilers
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)

project(ThreeBlindMice)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Find required packages
find_package(PkgConfig REQUIRED)

# Find X11
pkg_check_modules(X11 REQUIRED x11)
pkg_check_modules(XTEST REQUIRED xtst)

# Find evdev
find_library(EVDEV_LIB evdev)
if(NOT EVDEV_LIB)
    message(FATAL_ERROR "libevdev not found. Please install libevdev-dev")
endif()

# Find Swift
find_program(SWIFT_EXECUTABLE swift)
if(NOT SWIFT_EXECUTABLE)
    message(FATAL_ERROR "Swift not found. Please install Swift for Linux.")
endif()

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/c)
include_directories(${X11_INCLUDE_DIRS})
include_directories(${XTEST_INCLUDE_DIRS})

# C source files
set(C_SOURCES
    src/c/evdev_manager.c
    src/c/display_manager.c
)

# Create C library
add_library(ThreeBlindMiceLib STATIC ${C_SOURCES})

# Link libraries
target_link_libraries(ThreeBlindMiceLib
    ${X11_LIBRARIES}
    ${XTEST_LIBRARIES}
    ${EVDEV_LIB}
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

# Link with C library
target_link_libraries(ThreeBlindMice ThreeBlindMiceLib)

# Set output directory
set_target_properties(ThreeBlindMice PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# Installation
install(TARGETS ThreeBlindMice
    RUNTIME DESTINATION bin
)

# Install udev rules
install(FILES udev/99-threeblindmice.rules
    DESTINATION /etc/udev/rules.d/
)

# Print build information
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Swift executable: ${SWIFT_EXECUTABLE}")
message(STATUS "X11 libraries: ${X11_LIBRARIES}")
message(STATUS "XTEST libraries: ${XTEST_LIBRARIES}")
message(STATUS "evdev library: ${EVDEV_LIB}")
message(STATUS "Output directory: ${CMAKE_BINARY_DIR}/bin")
