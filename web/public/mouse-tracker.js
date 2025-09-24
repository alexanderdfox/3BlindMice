/**
 * Mouse Tracker - Handles client-side mouse movement tracking
 * Similar to the Swift MultiMouseManager but for web browsers
 */
class MouseTracker {
    constructor(canvas, socket) {
        this.canvas = canvas;
        this.socket = socket;
        this.ctx = canvas.getContext('2d');
        
        // Mouse tracking state
        this.isTracking = false;
        this.lastPosition = { x: 0, y: 0 };
        this.currentPosition = { x: 0, y: 0 };
        this.mouseDelta = { x: 0, y: 0 };
        
        // Configuration
        this.config = {
            smoothing: 0.7,
            maxDelta: 50, // Maximum delta per frame to prevent jumps
            trackingSensitivity: 1.0
        };
        
        // Mouse data for visualization
        this.mousePositions = new Map();
        this.mouseWeights = new Map();
        this.mouseActivity = new Map();
        this.mouseRotations = new Map(); // Mouse rotation tracking
        this.mouseEmojis = new Map(); // Per-mouse emoji assignment
        this.hostPosition = { x: 400, y: 300 }; // Default center
        this.cursorRotation = 0.0; // Current cursor rotation in degrees
        
        // Visual settings
        this.visualSettings = {
            showTrails: true,
            trailLength: 20,
            showWeights: true,
            showActivity: true,
            cursorSize: 8,
            trailOpacity: 0.6
        };
        
        this.setupCanvas();
        this.setupEventListeners();
        this.startRenderLoop();
    }
    
    // Assign a deterministic emoji per mouseId
    getMouseEmoji(mouseId) {
        if (this.mouseEmojis.has(mouseId)) return this.mouseEmojis.get(mouseId);
        const emojis = ['🐭','🐹','🐰','🐱','🐶','🐸','🐼','🐨','🐯','🦊','🐵','🦝','🦉','🐻','🦁','🐮','🐷','🐔','🐙','🦄'];
        let hash = 0;
        for (let i = 0; i < mouseId.length; i++) hash = (hash * 31 + mouseId.charCodeAt(i)) >>> 0;
        const emoji = emojis[hash % emojis.length];
        this.mouseEmojis.set(mouseId, emoji);
        return emoji;
    }
    
    setupCanvas() {
        // Set canvas size
        const rect = this.canvas.getBoundingClientRect();
        this.canvas.width = rect.width;
        this.canvas.height = rect.height;
        
        // Set initial mouse position to center
        this.lastPosition = {
            x: this.canvas.width / 2,
            y: this.canvas.height / 2
        };
        this.currentPosition = { ...this.lastPosition };
        
        // Setup canvas styling
        this.ctx.lineCap = 'round';
        this.ctx.lineJoin = 'round';
    }
    
    setupEventListeners() {
        // Mouse movement tracking
        this.canvas.addEventListener('mousemove', (e) => {
            if (!this.isTracking) return;
            
            const rect = this.canvas.getBoundingClientRect();
            const newPosition = {
                x: e.clientX - rect.left,
                y: e.clientY - rect.top
            };
            
            this.updateMousePosition(newPosition);
        });
        
        // Mouse enter/leave
        this.canvas.addEventListener('mouseenter', () => {
            this.isTracking = true;
        });
        
        this.canvas.addEventListener('mouseleave', () => {
            this.isTracking = false;
        });
        
        // Mouse click events
        this.canvas.addEventListener('mousedown', (e) => {
            if (!this.isTracking) return;
            
            const button = this.getMouseButton(e.button);
            this.socket?.emit('mouseClick', {
                button: button,
                doubleClick: false,
                timestamp: Date.now()
            });
        });
        
        this.canvas.addEventListener('dblclick', (e) => {
            if (!this.isTracking) return;
            
            const button = this.getMouseButton(e.button);
            this.socket?.emit('mouseClick', {
                button: button,
                doubleClick: true,
                timestamp: Date.now()
            });
        });
        
        // Touch support for mobile devices
        this.canvas.addEventListener('touchmove', (e) => {
            if (!this.isTracking) return;
            
            e.preventDefault();
            const touch = e.touches[0];
            const rect = this.canvas.getBoundingClientRect();
            const newPosition = {
                x: touch.clientX - rect.left,
                y: touch.clientY - rect.top
            };
            
            this.updateMousePosition(newPosition);
        });
        
        this.canvas.addEventListener('touchstart', (e) => {
            this.isTracking = true;
        });
        
        this.canvas.addEventListener('touchend', (e) => {
            this.isTracking = false;
        });
        
        // Handle scroll wheel for cursor rotation
        this.canvas.addEventListener('wheel', (e) => {
            if (!this.isTracking) return;
            
            e.preventDefault();
            
            const scrollDelta = e.deltaY;
            this.handleScrollInput(scrollDelta);
        }, { passive: false });
    }
    
    updateMousePosition(newPosition) {
        // Calculate delta
        const deltaX = (newPosition.x - this.lastPosition.x) * this.config.trackingSensitivity;
        const deltaY = (newPosition.y - this.lastPosition.y) * this.config.trackingSensitivity;
        
        // Clamp delta to prevent large jumps
        const clampedDeltaX = Math.max(-this.config.maxDelta, Math.min(this.config.maxDelta, deltaX));
        const clampedDeltaY = Math.max(-this.config.maxDelta, Math.min(this.config.maxDelta, deltaY));
        
        // Update positions
        this.currentPosition = newPosition;
        this.mouseDelta = { x: clampedDeltaX, y: clampedDeltaY };
        
        // Send to server
        this.socket?.emit('mouseMove', {
            deltaX: clampedDeltaX,
            deltaY: clampedDeltaY,
            timestamp: Date.now()
        });
        
        // Update last position
        this.lastPosition = { ...newPosition };
    }
    
    getMouseButton(buttonIndex) {
        switch (buttonIndex) {
            case 0: return 'left';
            case 1: return 'middle';
            case 2: return 'right';
            default: return 'left';
        }
    }
    
    handleScrollInput(scrollDelta) {
        // Update cursor rotation based on scroll wheel
        const rotationDelta = scrollDelta * 15.0; // 15 degrees per scroll step
        this.cursorRotation += rotationDelta;
        
        // Normalize rotation to 0-360 degrees
        this.cursorRotation = this.cursorRotation % 360;
        if (this.cursorRotation < 0) {
            this.cursorRotation += 360;
        }
        
        // Send rotation update to server
        this.socket?.emit('scrollInput', {
            scrollDelta: scrollDelta,
            rotation: this.cursorRotation,
            timestamp: Date.now()
        });
        
        // console.log(`🔄 Cursor rotation: ${Math.round(this.cursorRotation)}°`);
    }
    
    // Update mouse data from server
    updateMouseData(mouseData) {
        this.mousePositions.clear();
        this.mouseWeights.clear();
        this.mouseActivity.clear();
        this.mouseRotations.clear();
        
        if (mouseData.mice) {
            mouseData.mice.forEach(mouse => {
                this.mousePositions.set(mouse.id, mouse.position);
                this.mouseWeights.set(mouse.id, mouse.weight);
                this.mouseActivity.set(mouse.id, mouse.lastActivity);
                this.mouseRotations.set(mouse.id, mouse.rotation || 0.0);
                // Ensure emoji is assigned
                this.getMouseEmoji(mouse.id);
            });
        }
        
        if (mouseData.hostPosition) {
            this.hostPosition = mouseData.hostPosition;
        }
    }
    
    // Rendering loop
    startRenderLoop() {
        const render = () => {
            this.clearCanvas();
            this.drawBackground();
            this.drawMouseTrails();
            this.drawMouseCursors();
            this.drawHostCursor();
            this.drawInfo();
            requestAnimationFrame(render);
        };
        render();
    }
    
    clearCanvas() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
    
    drawBackground() {
        // Draw grid
        this.ctx.strokeStyle = 'rgba(102, 126, 234, 0.1)';
        this.ctx.lineWidth = 1;
        
        const gridSize = 50;
        
        // Vertical lines
        for (let x = 0; x <= this.canvas.width; x += gridSize) {
            this.ctx.beginPath();
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, this.canvas.height);
            this.ctx.stroke();
        }
        
        // Horizontal lines
        for (let y = 0; y <= this.canvas.height; y += gridSize) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, y);
            this.ctx.lineTo(this.canvas.width, y);
            this.ctx.stroke();
        }
        
        // Center cross
        this.ctx.strokeStyle = 'rgba(102, 126, 234, 0.3)';
        this.ctx.lineWidth = 2;
        this.ctx.beginPath();
        this.ctx.moveTo(this.canvas.width / 2, 0);
        this.ctx.lineTo(this.canvas.width / 2, this.canvas.height);
        this.ctx.moveTo(0, this.canvas.height / 2);
        this.ctx.lineTo(this.canvas.width, this.canvas.height / 2);
        this.ctx.stroke();
    }
    
    drawMouseTrails() {
        if (!this.visualSettings.showTrails) return;
        
        // This would require storing trail data for each mouse
        // For now, just draw a simple trail for the current mouse
        if (this.isTracking) {
            this.ctx.strokeStyle = `rgba(76, 175, 80, ${this.visualSettings.trailOpacity})`;
            this.ctx.lineWidth = 3;
            this.ctx.beginPath();
            this.ctx.moveTo(this.lastPosition.x, this.lastPosition.y);
            this.ctx.lineTo(this.currentPosition.x, this.currentPosition.y);
            this.ctx.stroke();
        }
    }
    
    drawMouseCursors() {
        // Draw all connected mice
        for (const [mouseId, position] of this.mousePositions.entries()) {
            const weight = this.mouseWeights.get(mouseId) || 1.0;
            const activity = this.mouseActivity.get(mouseId);
            const isActive = false; // active status not tracked client-side
            
            // Convert server coordinates to canvas coordinates
            const canvasX = (position.x / 1920) * this.canvas.width;
            const canvasY = (position.y / 1080) * this.canvas.height;
            
            // Draw mouse cursor
            this.drawMouseCursor(canvasX, canvasY, mouseId, weight, activity, isActive);
        }
    }
    
    drawMouseCursor(x, y, mouseId, weight, activity, isActive) {
        const size = this.visualSettings.cursorSize * (0.5 + weight * 0.5);
        const alpha = activity && (Date.now() - new Date(activity)) < 2000 ? 1.0 : 0.5;
        const rotation = this.mouseRotations.get(mouseId) || 0.0;
        const emoji = this.getMouseEmoji(mouseId);
        
        // Save context state
        this.ctx.save();
        
        // Apply rotation transformation
        this.ctx.translate(x, y);
        this.ctx.rotate((rotation * Math.PI) / 180);
        
        // Draw emoji as the cursor
        const fontSize = Math.max(18, size * 4);
        this.ctx.font = `${fontSize}px system-ui, Apple Color Emoji, Segoe UI Emoji, Noto Color Emoji`;
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';
        this.ctx.globalAlpha = alpha;
        this.ctx.fillText(emoji, 0, 0);
        
        // Restore context state
        this.ctx.restore();
        this.ctx.globalAlpha = 1.0;
        
        // Mouse ID label (not rotated)
        this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
        this.ctx.font = '12px Arial';
        this.ctx.textAlign = 'center';
        this.ctx.fillText(mouseId.substring(0, 4), x, y - (size * 2 + 10));
        
        // Weight and rotation indicators
        if (this.visualSettings.showWeights) {
            this.ctx.fillStyle = 'rgba(255, 152, 0, 0.9)';
            this.ctx.font = '10px Arial';
            this.ctx.fillText(weight.toFixed(1), x, y + (size * 2) + 12);
        }
        
        // Rotation indicator
        this.ctx.fillStyle = 'rgba(156, 39, 176, 0.9)';
        this.ctx.font = '10px Arial';
        this.ctx.fillText(`${Math.round(rotation)}°`, x, y + (size * 2) + 26);
    }
    
    drawHostCursor() {
        // Draw host cursor position
        const canvasX = (this.hostPosition.x / 1920) * this.canvas.width;
        const canvasY = (this.hostPosition.y / 1080) * this.canvas.height;
        
        // Host cursor (larger, different color)
        this.ctx.fillStyle = 'rgba(255, 87, 34, 0.8)';
        this.ctx.beginPath();
        this.ctx.arc(canvasX, canvasY, 12, 0, Math.PI * 2);
        this.ctx.fill();
        
        // Host cursor border
        this.ctx.strokeStyle = 'rgba(255, 87, 34, 1)';
        this.ctx.lineWidth = 3;
        this.ctx.stroke();
        
        // Host label
        this.ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
        this.ctx.font = 'bold 12px Arial';
        this.ctx.textAlign = 'center';
        this.ctx.fillText('HOST', canvasX, canvasY - 20);
    }
    
    drawInfo() {
        // Draw current mouse position info
        if (this.isTracking) {
            this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
            this.ctx.font = '12px Arial';
            this.ctx.textAlign = 'left';
            this.ctx.fillText(
                `Mouse: (${Math.round(this.currentPosition.x)}, ${Math.round(this.currentPosition.y)})`,
                10, 25
            );
            
            if (this.mouseDelta.x !== 0 || this.mouseDelta.y !== 0) {
                this.ctx.fillText(
                    `Delta: (${Math.round(this.mouseDelta.x)}, ${Math.round(this.mouseDelta.y)})`,
                    10, 45
                );
            }
        }
        
        // Draw host cursor position
        this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
        this.ctx.font = '12px Arial';
        this.ctx.textAlign = 'left';
        this.ctx.fillText(
            `Host: (${Math.round(this.hostPosition.x)}, ${Math.round(this.hostPosition.y)})`,
            10, this.canvas.height - 20
        );
    }
    
    getActiveMouseId() {
        // This would be set by the server data
        // For now, return null
        return null;
    }
    
    // Public methods
    startTracking() {
        this.isTracking = true;
    }
    
    stopTracking() {
        this.isTracking = false;
    }
    
    setConfig(newConfig) {
        this.config = { ...this.config, ...newConfig };
    }
    
    setVisualSettings(newSettings) {
        this.visualSettings = { ...this.visualSettings, ...newSettings };
    }
    
    // Resize canvas
    resizeCanvas() {
        const container = document.querySelector('.mouse-canvas-container') || this.canvas.parentElement;
        if (!container) return;
        const rect = container.getBoundingClientRect();
        this.canvas.width = Math.max(1, Math.floor(rect.width));
        this.canvas.height = Math.max(1, Math.floor(rect.height));
    }
}
