#!/usr/bin/env python3
"""
3 Blind Mice - Cross-Platform Icon Generator
============================================

Generates icons for all platforms (macOS, Windows, Linux, ChromeOS) from a single source image.
Supports multiple formats and sizes required by each platform.

Usage:
    python3 scripts/generate_icons.py [source_image] [output_dir]

Requirements:
    - Python 3.6+
    - Pillow (PIL) library
    - Source image (PNG, JPG, or other formats supported by Pillow)

Installation:
    pip install Pillow
"""

import os
import sys
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import subprocess

class IconGenerator:
    """Cross-platform icon generator for 3 Blind Mice"""
    
    def __init__(self, source_image=None, output_dir="assets/icons"):
        self.source_image = source_image
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Platform-specific icon requirements
        self.icon_sizes = {
            'macos': {
                'app_icon': [16, 32, 64, 128, 256, 512, 1024],
                'menu_bar': [16, 32],
                'dock': [32, 64, 128, 256, 512]
            },
            'windows': {
                'app_icon': [16, 24, 32, 48, 64, 96, 128, 256],
                'taskbar': [16, 24, 32],
                'desktop': [32, 48, 64, 96, 128, 256]
            },
            'linux': {
                'app_icon': [16, 24, 32, 48, 64, 96, 128, 256, 512],
                'desktop': [32, 48, 64, 96, 128, 256],
                'panel': [16, 24, 32]
            },
            'chromeos': {
                'extension': [16, 32, 48, 128],
                'app_icon': [16, 24, 32, 48, 64, 96, 128, 256]
            }
        }
        
        # Icon formats for each platform
        self.icon_formats = {
            'macos': ['png', 'icns'],
            'windows': ['png', 'ico'],
            'linux': ['png', 'svg'],
            'chromeos': ['png']
        }
    
    def check_dependencies(self):
        """Check if required dependencies are available"""
        try:
            import PIL
            print("✅ Pillow (PIL) library found")
            return True
        except ImportError:
            print("❌ Pillow library not found")
            print("Install with: pip install Pillow")
            return False
    
    def create_mouse_icon(self, size, style="default"):
        """Create a mouse-themed icon programmatically"""
        # Create a new image with transparent background
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Calculate dimensions based on size
        margin = max(2, size // 16)
        body_width = size - (margin * 2)
        body_height = int(body_width * 0.6)
        
        # Mouse body (rounded rectangle)
        body_x = margin
        body_y = margin + (size - body_height - margin) // 2
        
        # Draw mouse body
        if style == "minimal":
            # Minimal style - just outline
            draw.rounded_rectangle(
                [body_x, body_y, body_x + body_width, body_y + body_height],
                radius=body_width // 4,
                fill=(100, 100, 100, 200),
                outline=(200, 200, 200, 255),
                width=max(1, size // 32)
            )
        elif style == "colorful":
            # Colorful style
            colors = [
                (255, 100, 100, 255),  # Red
                (100, 255, 100, 255),  # Green
                (100, 100, 255, 255),  # Blue
                (255, 255, 100, 255),  # Yellow
            ]
            color = colors[size % len(colors)]
            draw.rounded_rectangle(
                [body_x, body_y, body_x + body_width, body_y + body_height],
                radius=body_width // 4,
                fill=color,
                outline=(255, 255, 255, 255),
                width=max(1, size // 32)
            )
        else:
            # Default style
            draw.rounded_rectangle(
                [body_x, body_y, body_x + body_width, body_y + body_height],
                radius=body_width // 4,
                fill=(150, 150, 150, 255),
                outline=(200, 200, 200, 255),
                width=max(1, size // 32)
            )
        
        # Draw mouse buttons (small rectangles on top)
        button_width = body_width // 3
        button_height = max(2, size // 16)
        button_y = body_y - button_height - max(1, size // 32)
        
        # Left button
        draw.rectangle(
            [body_x, button_y, body_x + button_width, button_y + button_height],
            fill=(180, 180, 180, 255),
            outline=(200, 200, 200, 255)
        )
        
        # Right button
        draw.rectangle(
            [body_x + button_width + max(1, size // 32), button_y, 
             body_x + (button_width * 2) + max(1, size // 32), button_y + button_height],
            fill=(180, 180, 180, 255),
            outline=(200, 200, 200, 255)
        )
        
        # Draw scroll wheel (small circle)
        wheel_size = max(2, size // 12)
        wheel_x = body_x + body_width // 2 - wheel_size // 2
        wheel_y = body_y + body_height // 2 - wheel_size // 2
        
        draw.ellipse(
            [wheel_x, wheel_y, wheel_x + wheel_size, wheel_y + wheel_size],
            fill=(100, 100, 100, 255),
            outline=(150, 150, 150, 255)
        )
        
        # Add "3" text for "3 Blind Mice"
        if size >= 32:
            try:
                # Try to use a system font
                font_size = max(8, size // 4)
                font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
            except:
                try:
                    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
                except:
                    font = ImageFont.load_default()
            
            # Draw "3" in the center
            text = "3"
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            
            text_x = (size - text_width) // 2
            text_y = (size - text_height) // 2
            
            draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
        
        return img
    
    def resize_image(self, image, size):
        """Resize image to specified size with high quality"""
        return image.resize((size, size), Image.Resampling.LANCZOS)
    
    def generate_icons_for_platform(self, platform, source_img=None):
        """Generate all required icons for a specific platform"""
        print(f"\n🎨 Generating icons for {platform.upper()}...")
        
        platform_dir = self.output_dir / platform
        platform_dir.mkdir(exist_ok=True)
        
        generated_files = []
        
        for category, sizes in self.icon_sizes[platform].items():
            print(f"  📁 {category}: ", end="")
            
            for size in sizes:
                # Create or resize image
                if source_img:
                    icon_img = self.resize_image(source_img, size)
                else:
                    icon_img = self.create_mouse_icon(size)
                
                # Generate different formats
                for fmt in self.icon_formats[platform]:
                    filename = f"icon_{size}x{size}.{fmt}"
                    filepath = platform_dir / filename
                    
                    if fmt == 'png':
                        icon_img.save(filepath, 'PNG')
                    elif fmt == 'ico' and platform == 'windows':
                        # Convert to ICO format for Windows
                        icon_img.save(filepath, 'ICO', sizes=[(size, size)])
                    elif fmt == 'icns' and platform == 'macos':
                        # Convert to ICNS format for macOS
                        icon_img.save(filepath, 'PNG')  # Save as PNG first
                        self.convert_to_icns(filepath)
                    elif fmt == 'svg' and platform == 'linux':
                        # Convert to SVG for Linux
                        self.convert_to_svg(icon_img, filepath)
                    
                    generated_files.append(filepath)
                    print(f"{size}x{size}.{fmt} ", end="")
            
            print()  # New line after each category
        
        return generated_files
    
    def convert_to_icns(self, png_path):
        """Convert PNG to ICNS format (macOS)"""
        icns_path = png_path.with_suffix('.icns')
        try:
            # Use iconutil on macOS
            subprocess.run([
                'iconutil', '-c', 'icns', 
                str(png_path.parent), '-o', str(icns_path)
            ], check=True, capture_output=True)
            print(f"✅ Converted to ICNS: {icns_path.name}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(f"⚠️  Could not convert to ICNS: {png_path.name}")
            # Keep the PNG file as fallback
    
    def convert_to_svg(self, image, svg_path):
        """Convert PIL image to SVG format"""
        try:
            # Simple SVG conversion
            width, height = image.size
            svg_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="{width}" height="{height}" xmlns="http://www.w3.org/2000/svg">
  <rect width="{width}" height="{height}" fill="none"/>
  <text x="{width//2}" y="{height//2}" text-anchor="middle" dominant-baseline="middle" 
        font-family="Arial, sans-serif" font-size="{width//4}" fill="#666">🐭</text>
</svg>'''
            
            with open(svg_path, 'w') as f:
                f.write(svg_content)
            print(f"✅ Created SVG: {svg_path.name}")
        except Exception as e:
            print(f"⚠️  Could not create SVG: {e}")
    
    def generate_all_platforms(self, source_img=None):
        """Generate icons for all platforms"""
        print("🐭 3 Blind Mice - Cross-Platform Icon Generator")
        print("=" * 50)
        
        if not self.check_dependencies():
            return False
        
        all_files = []
        
        # Generate icons for each platform
        for platform in self.icon_sizes.keys():
            files = self.generate_icons_for_platform(platform, source_img)
            all_files.extend(files)
        
        print(f"\n✅ Generated {len(all_files)} icon files")
        print(f"📁 Output directory: {self.output_dir.absolute()}")
        
        return all_files
    
    def create_platform_specific_manifests(self):
        """Create platform-specific manifest files for icons"""
        print("\n📋 Creating platform-specific manifests...")
        
        # macOS - Create icon set for Xcode
        macos_dir = self.output_dir / "macos"
        if macos_dir.exists():
            self.create_macos_iconset(macos_dir)
        
        # Windows - Create resource file
        windows_dir = self.output_dir / "windows"
        if windows_dir.exists():
            self.create_windows_resource(windows_dir)
        
        # Linux - Create desktop file
        linux_dir = self.output_dir / "linux"
        if linux_dir.exists():
            self.create_linux_desktop(linux_dir)
        
        # ChromeOS - Create extension manifest
        chromeos_dir = self.output_dir / "chromeos"
        if chromeos_dir.exists():
            self.create_chromeos_manifest(chromeos_dir)
    
    def create_macos_iconset(self, macos_dir):
        """Create macOS .iconset directory for Xcode"""
        iconset_dir = macos_dir / "ThreeBlindMice.iconset"
        iconset_dir.mkdir(exist_ok=True)
        
        # Copy icons to iconset format
        icon_mappings = {
            "icon_16x16.png": "icon_16x16.png",
            "icon_16x16@2x.png": "icon_32x32.png",
            "icon_32x32.png": "icon_32x32.png",
            "icon_32x32@2x.png": "icon_64x64.png",
            "icon_128x128.png": "icon_128x128.png",
            "icon_128x128@2x.png": "icon_256x256.png",
            "icon_256x256.png": "icon_256x256.png",
            "icon_256x256@2x.png": "icon_512x512.png",
            "icon_512x512.png": "icon_512x512.png",
            "icon_512x512@2x.png": "icon_1024x1024.png"
        }
        
        for source, target in icon_mappings.items():
            source_path = macos_dir / source
            target_path = iconset_dir / target
            if source_path.exists():
                import shutil
                shutil.copy2(source_path, target_path)
        
        print("✅ Created macOS .iconset directory")
    
    def create_windows_resource(self, windows_dir):
        """Create Windows resource file for icons"""
        rc_content = '''// Windows resource file for 3 Blind Mice icons
#include <windows.h>

// Application icon
IDI_APP_ICON ICON "icon_256x256.ico"

// Small icons for different contexts
IDI_APP_ICON_SMALL ICON "icon_16x16.ico"
IDI_APP_ICON_MEDIUM ICON "icon_32x32.ico"
IDI_APP_ICON_LARGE ICON "icon_128x128.ico"
'''
        
        rc_file = windows_dir / "app_icons.rc"
        with open(rc_file, 'w') as f:
            f.write(rc_content)
        
        print("✅ Created Windows resource file")
    
    def create_linux_desktop(self, linux_dir):
        """Create Linux desktop file"""
        desktop_content = '''[Desktop Entry]
Version=1.0
Type=Application
Name=3 Blind Mice
Comment=Multi-Mouse Triangulation Tool
Exec=threeblindmice
Icon=threeblindmice
Terminal=false
Categories=Utility;Accessibility;
Keywords=mouse;multi;accessibility;triangulation;
'''
        
        desktop_file = linux_dir / "threeblindmice.desktop"
        with open(desktop_file, 'w') as f:
            f.write(desktop_content)
        
        print("✅ Created Linux desktop file")
    
    def create_chromeos_manifest(self, chromeos_dir):
        """Create ChromeOS extension manifest snippet"""
        manifest_content = '''{
  "icons": {
    "16": "icon_16x16.png",
    "32": "icon_32x32.png",
    "48": "icon_48x48.png",
    "128": "icon_128x128.png"
  }
}'''
        
        manifest_file = chromeos_dir / "icon_manifest.json"
        with open(manifest_file, 'w') as f:
            f.write(manifest_content)
        
        print("✅ Created ChromeOS manifest snippet")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="Generate cross-platform icons for 3 Blind Mice",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 scripts/generate_icons.py                    # Generate programmatic icons
  python3 scripts/generate_icons.py logo.png           # Generate from source image
  python3 scripts/generate_icons.py logo.png custom/   # Custom output directory
        """
    )
    
    parser.add_argument(
        'source_image', 
        nargs='?', 
        help='Source image file (PNG, JPG, etc.)'
    )
    parser.add_argument(
        'output_dir', 
        nargs='?', 
        default='assets/icons',
        help='Output directory (default: assets/icons)'
    )
    parser.add_argument(
        '--style', 
        choices=['default', 'minimal', 'colorful'],
        default='default',
        help='Icon style for programmatic generation (default: default)'
    )
    parser.add_argument(
        '--platform', 
        choices=['macos', 'windows', 'linux', 'chromeos', 'all'],
        default='all',
        help='Target platform (default: all)'
    )
    
    args = parser.parse_args()
    
    # Initialize generator
    generator = IconGenerator(args.source_image, args.output_dir)
    
    # Load source image if provided
    source_img = None
    if args.source_image:
        try:
            source_img = Image.open(args.source_image)
            print(f"📷 Loaded source image: {args.source_image}")
            print(f"   Size: {source_img.size}")
            print(f"   Mode: {source_img.mode}")
        except Exception as e:
            print(f"❌ Error loading source image: {e}")
            return 1
    
    # Generate icons
    if args.platform == 'all':
        files = generator.generate_all_platforms(source_img)
    else:
        files = generator.generate_icons_for_platform(args.platform, source_img)
    
    # Create platform-specific manifests
    generator.create_platform_specific_manifests()
    
    print(f"\n🎉 Icon generation complete!")
    print(f"📊 Generated {len(files)} files")
    print(f"📁 Output: {generator.output_dir.absolute()}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
