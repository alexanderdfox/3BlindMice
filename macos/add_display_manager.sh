#!/bin/bash

# Add DisplayManager.swift to Xcode project
PROJECT_FILE="ThreeBlindMice.xcodeproj/project.pbxproj"

# Generate unique IDs for the new file
DISPLAY_MANAGER_BUILD_ID="A1234567890123456789013A"
DISPLAY_MANAGER_FILE_ID="A1234567890123456789013B"

# Add to PBXBuildFile section
sed -i '' '/ThreeBlindMiceApp.swift in Sources/a\
		'$DISPLAY_MANAGER_BUILD_ID' /* DisplayManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = '$DISPLAY_MANAGER_FILE_ID' /* DisplayManager.swift */; };' "$PROJECT_FILE"

# Add to PBXFileReference section
sed -i '' '/ThreeBlindMiceApp.swift.*= {isa = PBXFileReference/a\
		'$DISPLAY_MANAGER_FILE_ID' /* DisplayManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DisplayManager.swift; sourceTree = "<group>"; };' "$PROJECT_FILE"

# Add to group
sed -i '' '/ThreeBlindMiceApp.swift/a\
				'$DISPLAY_MANAGER_FILE_ID' /* DisplayManager.swift */,' "$PROJECT_FILE"

# Add to Sources build phase
sed -i '' '/ThreeBlindMiceApp.swift in Sources/a\
				'$DISPLAY_MANAGER_BUILD_ID' /* DisplayManager.swift in Sources */,' "$PROJECT_FILE"

echo "✅ DisplayManager.swift added to Xcode project"
