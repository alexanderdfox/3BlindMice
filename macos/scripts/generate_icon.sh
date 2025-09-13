#!/bin/bash

# Generate app icons using the mouse emoji
echo "Generating app icons for 3 Blind Mice..."

# Check for ImageMagick (prefer magick over convert for v7+)
if command -v magick &> /dev/null; then
    echo "Using ImageMagick v7+ to generate icons..."
    
    # Create base icon with mouse emoji using default font
    magick -size 512x512 xc:transparent \
        -pointsize 400 \
        -gravity center -draw "text 0,0 '🐭'" \
        -background transparent \
        icon_512.png
    
    # Generate different sizes
    magick icon_512.png -resize 256x256 icon_256.png
    magick icon_512.png -resize 128x128 icon_128.png
    magick icon_512.png -resize 32x32 icon_32.png
    magick icon_512.png -resize 16x16 icon_16.png
    
    echo "Icons generated successfully!"
    echo "You can now add these to your Assets.xcassets/AppIcon.appiconset folder"
    
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick v6 to generate icons..."
    
    # Create base icon with mouse emoji using default font
    convert -size 512x512 xc:transparent \
        -pointsize 400 \
        -gravity center -draw "text 0,0 '🐭'" \
        -background transparent \
        icon_512.png
    
    # Generate different sizes
    convert icon_512.png -resize 256x256 icon_256.png
    convert icon_512.png -resize 128x128 icon_128.png
    convert icon_512.png -resize 32x32 icon_32.png
    convert icon_512.png -resize 16x16 icon_16.png
    
    echo "Icons generated successfully!"
    echo "You can now add these to your Assets.xcassets/AppIcon.appiconset folder"
    
else
    echo "ImageMagick not found. Please install it or manually create icons."
    echo "You can use any image editor to create icons with the 🐭 emoji."
    echo ""
    echo "To install ImageMagick:"
    echo "  brew install imagemagick"
fi
