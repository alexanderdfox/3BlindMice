// 3 Blind Mice - Chrome Extension Background Script
// Multi-mouse triangulation service worker

class MultiMouseManager {
    constructor() {
        this.mousePositions = new Map();
        this.mouseWeights = new Map();
        this.mouseActivity = new Map();
        this.fusedPosition = { x: 500, y: 500 };
        this.lastUpdateTime = Date.now();
        this.smoothingFactor = 0.7;
        this.useIndividualMode = false;
        this.activeMouse = null;
        this.isRunning = false;
        this.mouseCount = 0;
        
        // Initialize the manager
        this.initialize();
    }
    
    async initialize() {
        console.log('🐭 3 Blind Mice Chrome Extension initialized');
        
        // Request input permissions
        try {
            const permissions = await chrome.permissions.request({
                permissions: ['input']
            });
            
            if (permissions) {
                console.log('✅ Input permissions granted');
                this.setupInputMonitoring();
            } else {
                console.log('❌ Input permissions denied');
            }
        } catch (error) {
            console.error('Permission request failed:', error);
        }
        
        // Set up keyboard shortcuts
        this.setupKeyboardShortcuts();
        
        // Load saved settings
        await this.loadSettings();
    }
    
    setupInputMonitoring() {
        // Monitor input events
        if (chrome.input && chrome.input.onInputEvent) {
            chrome.input.onInputEvent.addListener((event) => {
                this.handleInputEvent(event);
            });
        }
        
        // Monitor pointer events through content script
        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            if (message.type === 'pointerEvent') {
                this.handlePointerEvent(message.data);
            }
        });
    }
    
    setupKeyboardShortcuts() {
        // Handle keyboard shortcuts
        chrome.commands.onCommand.addListener((command) => {
            switch (command) {
                case 'toggle-triangulation':
                    this.toggleTriangulation();
                    break;
                case 'switch-mode':
                    this.toggleMode();
                    break;
            }
        });
    }
    
    handleInputEvent(event) {
        if (!this.isRunning) return;
        
        const currentTime = Date.now();
        const deviceId = event.deviceId || 'default';
        
        // Update mouse activity
        this.mouseActivity.set(deviceId, currentTime);
        
        // Initialize mouse data if not exists
        if (!this.mouseWeights.has(deviceId)) {
            this.mouseWeights.set(deviceId, 1.0);
        }
        if (!this.mousePositions.has(deviceId)) {
            this.mousePositions.set(deviceId, { x: 500, y: 500 });
        }
        
        // Process input based on event type
        if (event.type === 'mousemove') {
            this.processMouseMove(deviceId, event.deltaX || 0, event.deltaY || 0);
        }
    }
    
    handlePointerEvent(data) {
        if (!this.isRunning) return;
        
        const deviceId = data.deviceId || 'default';
        const currentTime = Date.now();
        
        // Update mouse activity
        this.mouseActivity.set(deviceId, currentTime);
        
        // Initialize mouse data if not exists
        if (!this.mouseWeights.has(deviceId)) {
            this.mouseWeights.set(deviceId, 1.0);
        }
        if (!this.mousePositions.has(deviceId)) {
            this.mousePositions.set(deviceId, { x: 500, y: 500 });
        }
        
        // Process pointer movement
        this.processMouseMove(deviceId, data.deltaX || 0, data.deltaY || 0);
    }
    
    processMouseMove(deviceId, deltaX, deltaY) {
        const currentPos = this.mousePositions.get(deviceId);
        const newX = currentPos.x + deltaX;
        const newY = currentPos.y + deltaY;
        
        // Update individual mouse position
        this.mousePositions.set(deviceId, { x: newX, y: newY });
        
        // Update mouse weights based on activity
        this.updateMouseWeights();
        
        // Handle cursor movement based on mode
        if (this.useIndividualMode) {
            this.handleIndividualMode(deviceId);
        } else {
            this.fuseAndMoveCursor();
        }
    }
    
    updateMouseWeights() {
        const currentTime = Date.now();
        const activityTimeout = 2000; // 2 seconds
        
        for (const [deviceId, lastActivity] of this.mouseActivity) {
            const timeSinceActivity = currentTime - lastActivity;
            
            // Reduce weight for inactive mice
            if (timeSinceActivity > activityTimeout) {
                const currentWeight = this.mouseWeights.get(deviceId) || 1.0;
                this.mouseWeights.set(deviceId, Math.max(0.1, currentWeight * 0.9));
            } else {
                // Increase weight for active mice
                const currentWeight = this.mouseWeights.get(deviceId) || 1.0;
                this.mouseWeights.set(deviceId, Math.min(2.0, currentWeight * 1.1));
            }
        }
    }
    
    handleIndividualMode(deviceId) {
        this.activeMouse = deviceId;
        
        const position = this.mousePositions.get(deviceId);
        if (position) {
            this.setCursorPosition(position.x, position.y);
        }
    }
    
    fuseAndMoveCursor() {
        if (this.mousePositions.size === 0) return;
        
        const currentTime = Date.now();
        
        // Calculate weighted average
        let weightedTotalX = 0;
        let weightedTotalY = 0;
        let totalWeight = 0;
        
        for (const [deviceId, position] of this.mousePositions) {
            const weight = this.mouseWeights.get(deviceId) || 1.0;
            weightedTotalX += position.x * weight;
            weightedTotalY += position.y * weight;
            totalWeight += weight;
        }
        
        if (totalWeight === 0) return;
        
        const avgX = weightedTotalX / totalWeight;
        const avgY = weightedTotalY / totalWeight;
        
        // Apply smoothing
        const timeDelta = currentTime - this.lastUpdateTime;
        const smoothing = Math.min(1.0, timeDelta / 16.67); // 60 FPS
        
        const newX = this.fusedPosition.x + avgX;
        const newY = this.fusedPosition.y + avgY;
        
        this.fusedPosition.x = this.fusedPosition.x * (1 - smoothing) + newX * smoothing;
        this.fusedPosition.y = this.fusedPosition.y * (1 - smoothing) + newY * smoothing;
        
        // Move cursor to fused position
        this.setCursorPosition(this.fusedPosition.x, this.fusedPosition.y);
        
        this.lastUpdateTime = currentTime;
    }
    
    setCursorPosition(x, y) {
        // Send cursor position to content script
        chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
            if (tabs[0]) {
                chrome.tabs.sendMessage(tabs[0].id, {
                    type: 'setCursorPosition',
                    x: x,
                    y: y
                });
            }
        });
    }
    
    toggleTriangulation() {
        this.isRunning = !this.isRunning;
        console.log(`🔄 Triangulation ${this.isRunning ? 'started' : 'stopped'}`);
        
        // Notify popup of state change
        chrome.runtime.sendMessage({
            type: 'triangulationStateChanged',
            isRunning: this.isRunning
        });
    }
    
    toggleMode() {
        this.useIndividualMode = !this.useIndividualMode;
        console.log(`🔄 Mode switched to: ${this.useIndividualMode ? 'Individual' : 'Fused'}`);
        
        // Notify popup of mode change
        chrome.runtime.sendMessage({
            type: 'modeChanged',
            useIndividualMode: this.useIndividualMode
        });
    }
    
    async loadSettings() {
        try {
            const result = await chrome.storage.sync.get(['isRunning', 'useIndividualMode']);
            this.isRunning = result.isRunning || false;
            this.useIndividualMode = result.useIndividualMode || false;
        } catch (error) {
            console.error('Failed to load settings:', error);
        }
    }
    
    async saveSettings() {
        try {
            await chrome.storage.sync.set({
                isRunning: this.isRunning,
                useIndividualMode: this.useIndividualMode
            });
        } catch (error) {
            console.error('Failed to save settings:', error);
        }
    }
    
    getStatus() {
        return {
            isRunning: this.isRunning,
            useIndividualMode: this.useIndividualMode,
            mouseCount: this.mousePositions.size,
            activeMouse: this.activeMouse,
            mousePositions: Object.fromEntries(this.mousePositions)
        };
    }
}

// Initialize the multi-mouse manager
const multiMouseManager = new MultiMouseManager();

// Handle extension installation
chrome.runtime.onInstalled.addListener((details) => {
    console.log('3 Blind Mice extension installed:', details.reason);
});

// Handle messages from popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    switch (message.type) {
        case 'getStatus':
            sendResponse(multiMouseManager.getStatus());
            break;
        case 'toggleTriangulation':
            multiMouseManager.toggleTriangulation();
            sendResponse({ success: true });
            break;
        case 'toggleMode':
            multiMouseManager.toggleMode();
            sendResponse({ success: true });
            break;
        case 'saveSettings':
            multiMouseManager.saveSettings();
            sendResponse({ success: true });
            break;
    }
});
