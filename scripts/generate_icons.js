#!/usr/bin/env node

/**
 * 3 Blind Mice - Cross-Platform Icon Generator (Node.js)
 * ======================================================
 * 
 * Generates icons for all platforms using Sharp image processing library
 * 
 * Usage:
 *   node scripts/generate_icons.js [source_image] [output_dir]
 * 
 * Examples:
 *   node scripts/generate_icons.js                    # Generate from default icon.png
 *   node scripts/generate_icons.js logo.png            # Generate from custom source image
 *   node scripts/generate_icons.js logo.png custom/    # Custom output directory
 * 
 * Requirements:
 *   npm install sharp
 */

const fs = require('fs');
const path = require('path');
const { createCanvas, loadImage } = require('canvas');

// Configuration
const CONFIG = {
    iconSizes: {
        macos: [16, 32, 64, 128, 256, 512, 1024],
        windows: [16, 24, 32, 48, 64, 96, 128, 256],
        linux: [16, 24, 32, 48, 64, 96, 128, 256, 512],
        chromeos: [16, 32, 48, 128]
    },
    platforms: ['macos', 'windows', 'linux', 'chromeos']
};

class IconGenerator {
    constructor(sourceImage = null, outputDir = 'assets/icons') {
        // Use default icon.png if no source image provided
        if (sourceImage === null) {
            const scriptDir = path.dirname(__filename);
            const defaultIcon = path.join(scriptDir, 'icon.png');
            if (fs.existsSync(defaultIcon)) {
                this.sourceImage = defaultIcon;
                console.log(`📷 Using default icon: ${this.sourceImage}`);
            } else {
                this.sourceImage = null;
                console.log('⚠️  No default icon.png found, generating programmatic icons');
            }
        } else {
            this.sourceImage = sourceImage;
        }
        
        this.outputDir = path.resolve(outputDir);
        this.generatedFiles = [];
    }

    async checkDependencies() {
        console.log('🔍 Checking dependencies...');
        
        try {
            // Check if Sharp is available (preferred)
            require('sharp');
            console.log('✅ Sharp library found');
            this.useSharp = true;
            return true;
        } catch (e) {
            console.log('⚠️  Sharp not found, trying Canvas...');
        }

        try {
            // Check if Canvas is available
            require('canvas');
            console.log('✅ Canvas library found');
            this.useSharp = false;
            return true;
        } catch (e) {
            console.log('❌ Neither Sharp nor Canvas found');
            console.log('💡 Install dependencies:');
            console.log('   npm install sharp');
            console.log('   OR');
            console.log('   npm install canvas');
            return false;
        }
    }

    async createDirectories() {
        console.log('📁 Creating output directories...');
        
        for (const platform of CONFIG.platforms) {
            const platformDir = path.join(this.outputDir, platform);
            if (!fs.existsSync(platformDir)) {
                fs.mkdirSync(platformDir, { recursive: true });
            }
        }
        
        console.log('✅ Directories created');
    }

    async createMouseIcon(size, style = 'default') {
        if (this.useSharp) {
            return this.createMouseIconSharp(size, style);
        } else {
            return this.createMouseIconCanvas(size, style);
        }
    }

    async createMouseIconSharp(size, style = 'default') {
        const sharp = require('sharp');
        
        // Create SVG for the mouse icon
        const svg = this.generateMouseSVG(size, style);
        
        // Convert SVG to PNG
        const buffer = await sharp(Buffer.from(svg))
            .png()
            .toBuffer();
        
        return buffer;
    }

    async createMouseIconCanvas(size, style = 'default') {
        const canvas = createCanvas(size, size);
        const ctx = canvas.getContext('2d');
        
        // Clear background
        ctx.clearRect(0, 0, size, size);
        
        // Calculate dimensions
        const margin = Math.max(2, size / 16);
        const bodyWidth = size - (margin * 2);
        const bodyHeight = bodyWidth * 0.6;
        
        const bodyX = margin;
        const bodyY = margin + (size - bodyHeight - margin) / 2;
        
        // Draw mouse body
        ctx.fillStyle = style === 'colorful' ? '#ff6b6b' : '#999999';
        ctx.strokeStyle = '#cccccc';
        ctx.lineWidth = Math.max(1, size / 32);
        
        this.drawRoundedRect(ctx, bodyX, bodyY, bodyWidth, bodyHeight, bodyWidth / 4);
        ctx.fill();
        ctx.stroke();
        
        // Draw mouse buttons
        const buttonWidth = bodyWidth / 3;
        const buttonHeight = Math.max(2, size / 16);
        const buttonY = bodyY - buttonHeight - Math.max(1, size / 32);
        
        ctx.fillStyle = '#bbbbbb';
        ctx.strokeStyle = '#cccccc';
        
        // Left button
        ctx.fillRect(bodyX, buttonY, buttonWidth, buttonHeight);
        ctx.strokeRect(bodyX, buttonY, buttonWidth, buttonHeight);
        
        // Right button
        ctx.fillRect(bodyX + buttonWidth + Math.max(1, size / 32), buttonY, buttonWidth, buttonHeight);
        ctx.strokeRect(bodyX + buttonWidth + Math.max(1, size / 32), buttonY, buttonWidth, buttonHeight);
        
        // Draw scroll wheel
        const wheelSize = Math.max(2, size / 12);
        const wheelX = bodyX + bodyWidth / 2 - wheelSize / 2;
        const wheelY = bodyY + bodyHeight / 2 - wheelSize / 2;
        
        ctx.fillStyle = '#666666';
        ctx.strokeStyle = '#999999';
        ctx.beginPath();
        ctx.arc(wheelX + wheelSize / 2, wheelY + wheelSize / 2, wheelSize / 2, 0, 2 * Math.PI);
        ctx.fill();
        ctx.stroke();
        
        // Add "3" text
        if (size >= 32) {
            ctx.fillStyle = '#ffffff';
            ctx.font = `bold ${size / 4}px Arial`;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText('3', size / 2, size / 2);
        }
        
        return canvas.toBuffer('image/png');
    }

    generateMouseSVG(size, style = 'default') {
        const margin = Math.max(2, size / 16);
        const bodyWidth = size - (margin * 2);
        const bodyHeight = bodyWidth * 0.6;
        
        const bodyX = margin;
        const bodyY = margin + (size - bodyHeight - margin) / 2;
        
        const fillColor = style === 'colorful' ? '#ff6b6b' : '#999999';
        
        return `
<svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
  <rect width="${size}" height="${size}" fill="transparent"/>
  <rect x="${bodyX}" y="${bodyY}" width="${bodyWidth}" height="${bodyHeight}" 
        rx="${bodyWidth / 4}" ry="${bodyWidth / 4}" 
        fill="${fillColor}" stroke="#cccccc" stroke-width="${Math.max(1, size / 32)}"/>
  <rect x="${bodyX}" y="${bodyY - Math.max(2, size / 16) - Math.max(1, size / 32)}" 
        width="${bodyWidth / 3}" height="${Math.max(2, size / 16)}" 
        fill="#bbbbbb" stroke="#cccccc"/>
  <rect x="${bodyX + bodyWidth / 3 + Math.max(1, size / 32)}" 
        y="${bodyY - Math.max(2, size / 16) - Math.max(1, size / 32)}" 
        width="${bodyWidth / 3}" height="${Math.max(2, size / 16)}" 
        fill="#bbbbbb" stroke="#cccccc"/>
  <circle cx="${bodyX + bodyWidth / 2}" cy="${bodyY + bodyHeight / 2}" 
          r="${Math.max(1, size / 24)}" fill="#666666" stroke="#999999"/>
  ${size >= 32 ? `<text x="${size / 2}" y="${size / 2}" text-anchor="middle" 
        dominant-baseline="middle" font-family="Arial" font-size="${size / 4}" 
        font-weight="bold" fill="#ffffff">3</text>` : ''}
</svg>`;
    }

    drawRoundedRect(ctx, x, y, width, height, radius) {
        ctx.beginPath();
        ctx.moveTo(x + radius, y);
        ctx.lineTo(x + width - radius, y);
        ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
        ctx.lineTo(x + width, y + height - radius);
        ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
        ctx.lineTo(x + radius, y + height);
        ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
        ctx.lineTo(x, y + radius);
        ctx.quadraticCurveTo(x, y, x + radius, y);
        ctx.closePath();
    }

    async resizeImage(imageBuffer, size) {
        if (this.useSharp) {
            const sharp = require('sharp');
            return await sharp(imageBuffer)
                .resize(size, size)
                .png()
                .toBuffer();
        } else {
            // For Canvas, we need to load the image first
            const image = await loadImage(imageBuffer);
            const canvas = createCanvas(size, size);
            const ctx = canvas.getContext('2d');
            
            ctx.drawImage(image, 0, 0, size, size);
            return canvas.toBuffer('image/png');
        }
    }

    async generateIconsForPlatform(platform, sourceImgBuffer = null) {
        console.log(`\n🎨 Generating icons for ${platform.toUpperCase()}...`);
        
        const platformDir = path.join(this.outputDir, platform);
        const sizes = CONFIG.iconSizes[platform];
        
        for (const size of sizes) {
            const filename = `icon_${size}x${size}.png`;
            const filepath = path.join(platformDir, filename);
            
            let iconBuffer;
            
            if (sourceImgBuffer) {
                iconBuffer = await this.resizeImage(sourceImgBuffer, size);
            } else {
                iconBuffer = await this.createMouseIcon(size);
            }
            
            fs.writeFileSync(filepath, iconBuffer);
            this.generatedFiles.push(filepath);
            console.log(`  ✅ ${filename}`);
        }
        
        // Platform-specific additional files
        await this.createPlatformSpecificFiles(platform, platformDir);
    }

    async createPlatformSpecificFiles(platform, platformDir) {
        switch (platform) {
            case 'macos':
                await this.createMacOSFiles(platformDir);
                break;
            case 'windows':
                await this.createWindowsFiles(platformDir);
                break;
            case 'linux':
                await this.createLinuxFiles(platformDir);
                break;
            case 'chromeos':
                await this.createChromeOSFiles(platformDir);
                break;
        }
    }

    async createMacOSFiles(platformDir) {
        // Create .iconset directory for Xcode
        const iconsetDir = path.join(platformDir, 'ThreeBlindMice.iconset');
        if (!fs.existsSync(iconsetDir)) {
            fs.mkdirSync(iconsetDir);
        }
        
        const iconMappings = {
            'icon_16x16.png': 'icon_16x16.png',
            'icon_32x32.png': 'icon_16x16@2x.png',
            'icon_32x32.png': 'icon_32x32.png',
            'icon_64x64.png': 'icon_32x32@2x.png',
            'icon_128x128.png': 'icon_128x128.png',
            'icon_256x256.png': 'icon_128x128@2x.png',
            'icon_256x256.png': 'icon_256x256.png',
            'icon_512x512.png': 'icon_256x256@2x.png',
            'icon_512x512.png': 'icon_512x512.png',
            'icon_1024x1024.png': 'icon_512x512@2x.png'
        };
        
        for (const [source, target] of Object.entries(iconMappings)) {
            const sourcePath = path.join(platformDir, source);
            const targetPath = path.join(iconsetDir, target);
            
            if (fs.existsSync(sourcePath)) {
                fs.copyFileSync(sourcePath, targetPath);
            }
        }
        
        console.log('  ✅ Created .iconset directory for Xcode');
    }

    async createWindowsFiles(platformDir) {
        // Create Windows resource file
        const rcContent = `// Windows resource file for 3 Blind Mice icons
#include <windows.h>

// Application icon
IDI_APP_ICON ICON "icon_256x256.ico"

// Small icons for different contexts
IDI_APP_ICON_SMALL ICON "icon_16x16.ico"
IDI_APP_ICON_MEDIUM ICON "icon_32x32.ico"
IDI_APP_ICON_LARGE ICON "icon_128x128.ico"
`;
        
        const rcFile = path.join(platformDir, 'app_icons.rc');
        fs.writeFileSync(rcFile, rcContent);
        
        console.log('  ✅ Created Windows resource file');
    }

    async createLinuxFiles(platformDir) {
        // Create Linux desktop file
        const desktopContent = `[Desktop Entry]
Version=1.0
Type=Application
Name=3 Blind Mice
Comment=Multi-Mouse Triangulation Tool
Exec=threeblindmice
Icon=threeblindmice
Terminal=false
Categories=Utility;Accessibility;
Keywords=mouse;multi;accessibility;triangulation;
`;
        
        const desktopFile = path.join(platformDir, 'threeblindmice.desktop');
        fs.writeFileSync(desktopFile, desktopContent);
        
        console.log('  ✅ Created Linux desktop file');
    }

    async createChromeOSFiles(platformDir) {
        // Create ChromeOS manifest snippet
        const manifestContent = `{
  "icons": {
    "16": "icon_16x16.png",
    "32": "icon_32x32.png",
    "48": "icon_48x48.png",
    "128": "icon_128x128.png"
  }
}`;
        
        const manifestFile = path.join(platformDir, 'icon_manifest.json');
        fs.writeFileSync(manifestFile, manifestContent);
        
        console.log('  ✅ Created ChromeOS manifest snippet');
    }

    async generateAllIcons() {
        console.log('🐭 3 Blind Mice - Cross-Platform Icon Generator');
        console.log('================================================');
        
        if (!(await this.checkDependencies())) {
            return false;
        }
        
        await this.createDirectories();
        
        // Load source image if provided
        let sourceImgBuffer = null;
        if (this.sourceImage) {
            try {
                sourceImgBuffer = fs.readFileSync(this.sourceImage);
                console.log(`📷 Loaded source image: ${this.sourceImage}`);
            } catch (error) {
                console.log(`❌ Error loading source image: ${error.message}`);
                return false;
            }
        }
        
        // Generate icons for all platforms
        for (const platform of CONFIG.platforms) {
            await this.generateIconsForPlatform(platform, sourceImgBuffer);
        }
        
        console.log(`\n✅ Generated ${this.generatedFiles.length} icon files`);
        console.log(`📁 Output directory: ${this.outputDir}`);
        
        return true;
    }
}

// Main execution
async function main() {
    const args = process.argv.slice(2);
    const sourceImage = args[0] || null;
    const outputDir = args[1] || 'assets/icons';
    
    const generator = new IconGenerator(sourceImage, outputDir);
    
    const success = await generator.generateAllIcons();
    
    if (success) {
        console.log('\n🎉 Icon generation complete!');
        console.log('💡 Next steps:');
        console.log('  • Copy icons to your platform-specific directories');
        console.log('  • Update Xcode project with macOS icons');
        console.log('  • Include Windows icons in your build');
        console.log('  • Install Linux desktop file');
        console.log('  • Update Chrome Extension manifest');
    } else {
        console.log('\n❌ Icon generation failed');
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = IconGenerator;
