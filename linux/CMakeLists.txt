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

# Enable Swift and ensure toolchain exists
enable_language(Swift)
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

# Create C shared library (not a static library)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
add_library(ThreeBlindMiceLib SHARED ${C_SOURCES})
set_target_properties(ThreeBlindMiceLib PROPERTIES
    OUTPUT_NAME "threeblindmice"
    VERSION 1.0.0
    SOVERSION 1
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# Link libraries
target_link_libraries(ThreeBlindMiceLib
    ${X11_LIBRARIES}
    ${XTEST_LIBRARIES}
    ${EVDEV_LIB}
)

# Swift executable target
set(SWIFT_SOURCES
    src/swift/main.swift
    src/swift/MultiMouseManager.swift
    src/swift/DisplayManager.swift
    src/hipaa/HIPAASecurity.swift
    src/hipaa/HIPAADataManager.swift
)

add_executable(ThreeBlindMice ${SWIFT_SOURCES})

# Ensure the executable can find the shared library at runtime
set_target_properties(ThreeBlindMice PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

target_link_libraries(ThreeBlindMice PRIVATE ThreeBlindMiceLib)

if(UNIX AND NOT APPLE)
    # On Linux, set RPATH to $ORIGIN to locate libthreeblindmice next to the binary
    set_target_properties(ThreeBlindMice PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "\$ORIGIN"
        SKIP_BUILD_RPATH FALSE
    )
endif()

# Install udev rules (if they exist)
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/udev/99-threeblindmice.rules)
    install(FILES udev/99-threeblindmice.rules
        DESTINATION /etc/udev/rules.d/
    )
endif()

# Print build information
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Swift executable: ${SWIFT_EXECUTABLE}")
message(STATUS "X11 libraries: ${X11_LIBRARIES}")
message(STATUS "XTEST libraries: ${XTEST_LIBRARIES}")
message(STATUS "evdev library: ${EVDEV_LIB}")
message(STATUS "Output directory: ${CMAKE_BINARY_DIR}/bin")
