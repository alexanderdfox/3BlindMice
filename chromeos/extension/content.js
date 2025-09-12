// 3 Blind Mice - Chrome Extension Content Script
// Handles page interaction and cursor control

class ContentScriptManager {
    constructor() {
        this.isActive = false;
        this.mouseEvents = new Map();
        this.lastCursorPosition = { x: 0, y: 0 };
        
        this.initialize();
    }
    
    initialize() {
        console.log('🐭 3 Blind Mice content script initialized');
        
        // Listen for messages from background script
        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            this.handleMessage(message, sender, sendResponse);
        });
        
        // Set up pointer event monitoring
        this.setupPointerEventMonitoring();
    }
    
    setupPointerEventMonitoring() {
        // Monitor pointer events to detect multiple mice
        document.addEventListener('pointermove', (event) => {
            this.handlePointerEvent(event);
        }, true);
        
        document.addEventListener('mousemove', (event) => {
            this.handleMouseEvent(event);
        }, true);
        
        // Monitor pointer down/up to track device IDs
        document.addEventListener('pointerdown', (event) => {
            this.trackDevice(event);
        }, true);
        
        document.addEventListener('pointerup', (event) => {
            this.trackDevice(event);
        }, true);
    }
    
    handlePointerEvent(event) {
        if (!this.isActive) return;
        
        // Extract device information
        const deviceId = event.pointerId || 'default';
        const deltaX = event.movementX || 0;
        const deltaY = event.movementY || 0;
        
        // Send to background script
        chrome.runtime.sendMessage({
            type: 'pointerEvent',
            data: {
                deviceId: deviceId,
                deltaX: deltaX,
                deltaY: deltaY,
                timestamp: Date.now()
            }
        });
    }
    
    handleMouseEvent(event) {
        if (!this.isActive) return;
        
        // Extract mouse information
        const deviceId = 'mouse_' + event.button;
        const deltaX = event.movementX || 0;
        const deltaY = event.movementY || 0;
        
        // Send to background script
        chrome.runtime.sendMessage({
            type: 'pointerEvent',
            data: {
                deviceId: deviceId,
                deltaX: deltaX,
                deltaY: deltaY,
                timestamp: Date.now()
            }
        });
    }
    
    trackDevice(event) {
        const deviceId = event.pointerId || 'default';
        this.mouseEvents.set(deviceId, {
            lastSeen: Date.now(),
            type: event.type
        });
        
        // Clean up old entries
        const now = Date.now();
        for (const [id, data] of this.mouseEvents) {
            if (now - data.lastSeen > 5000) { // 5 seconds timeout
                this.mouseEvents.delete(id);
            }
        }
    }
    
    handleMessage(message, sender, sendResponse) {
        switch (message.type) {
            case 'setCursorPosition':
                this.setCursorPosition(message.x, message.y);
                break;
            case 'activate':
                this.isActive = true;
                console.log('✅ Content script activated');
                break;
            case 'deactivate':
                this.isActive = false;
                console.log('❌ Content script deactivated');
                break;
            case 'getDeviceCount':
                sendResponse({ count: this.mouseEvents.size });
                break;
        }
    }
    
    setCursorPosition(x, y) {
        // Update cursor position using CSS cursor positioning
        // Note: This is a simplified approach - actual cursor control
        // would require more sophisticated methods
        
        const cursor = document.createElement('div');
        cursor.style.position = 'fixed';
        cursor.style.left = x + 'px';
        cursor.style.top = y + 'px';
        cursor.style.width = '1px';
        cursor.style.height = '1px';
        cursor.style.backgroundColor = 'red';
        cursor.style.pointerEvents = 'none';
        cursor.style.zIndex = '999999';
        cursor.style.borderRadius = '50%';
        
        document.body.appendChild(cursor);
        
        // Remove after a short time
        setTimeout(() => {
            if (cursor.parentNode) {
                cursor.parentNode.removeChild(cursor);
            }
        }, 100);
        
        this.lastCursorPosition = { x, y };
    }
    
    getDeviceCount() {
        return this.mouseEvents.size;
    }
}

// Initialize content script manager
const contentScriptManager = new ContentScriptManager();

// Notify background script that content script is ready
chrome.runtime.sendMessage({
    type: 'contentScriptReady'
});

// Handle page visibility changes
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        chrome.runtime.sendMessage({
            type: 'pageHidden'
        });
    } else {
        chrome.runtime.sendMessage({
            type: 'pageVisible'
        });
    }
});

// Handle page unload
window.addEventListener('beforeunload', () => {
    chrome.runtime.sendMessage({
        type: 'pageUnload'
    });
});
