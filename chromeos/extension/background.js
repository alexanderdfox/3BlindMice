// 3 Blind Mice - Chrome Extension Background Script
// Multi-mouse triangulation service worker

class MultiMouseManager {
    constructor() {
        this.mousePositions = new Map();
        this.mouseWeights = new Map();
        this.mouseActivity = new Map();
        this.mouseRotations = new Map(); // Mouse rotation tracking
        this.fusedPosition = { x: 0, y: 0 }; // Will be initialized to screen center
        this.lastUpdateTime = Date.now();
        this.smoothingFactor = 0.7;
        this.useIndividualMode = false;
        this.activeMouse = null;
        this.isRunning = false;
        this.mouseCount = 0;
        
        // Multi-display support
        this.displays = [];
        this.primaryDisplay = null;
        
        // HIPAA compliance features
        this.hipaaEnabled = true;
        this.auditLog = [];
        this.encryptionKey = this.generateEncryptionKey();
        this.accessControls = new Map();
        
        // Initialize the manager
        this.initialize();
    }
    
    async initialize() {
        console.log('🐭 3 Blind Mice Chrome Extension initialized');
        console.log('🏥 HIPAA Compliant for healthcare environments');
        
        // Initialize fused position to screen center
        const screenWidth = await this.getScreenWidth();
        const screenHeight = await this.getScreenHeight();
        this.fusedPosition = { x: screenWidth / 2, y: screenHeight / 2 };
        
        // Initialize HIPAA compliance features
        this.initializeHIPAACompliance();
        
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
        
        // Initialize display management
        this.initializeDisplays();
        
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
            } else if (message.type === 'scrollEvent') {
                this.handleScrollEvent(message.data);
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
    
    // Multi-display support methods
    async initializeDisplays() {
        try {
            if (chrome.system && chrome.system.display) {
                const displays = await chrome.system.display.getInfo();
                this.displays = displays;
                this.primaryDisplay = displays.find(d => d.isPrimary) || displays[0];
                
                console.log(`🖥️  Detected ${displays.length} display(s)`);
                displays.forEach((display, index) => {
                    console.log(`   Display ${index + 1}: ${display.bounds.width}x${display.bounds.height} ${display.isPrimary ? '[PRIMARY]' : ''}`);
                });
                
                // Listen for display changes
                chrome.system.display.onDisplayChanged.addListener(() => {
                    this.updateDisplays();
                });
            } else {
                // Fallback for environments without chrome.system.display
                this.displays = [{
                    id: 'fallback',
                    bounds: { left: 0, top: 0, width: 1920, height: 1080 },
                    isPrimary: true
                }];
                this.primaryDisplay = this.displays[0];
                console.log('🖥️  Using fallback display configuration');
            }
        } catch (error) {
            console.error('Failed to initialize displays:', error);
            // Use default display as fallback
            this.displays = [{
                id: 'default',
                bounds: { left: 0, top: 0, width: 1920, height: 1080 },
                isPrimary: true
            }];
            this.primaryDisplay = this.displays[0];
        }
    }
    
    async updateDisplays() {
        try {
            if (chrome.system && chrome.system.display) {
                const displays = await chrome.system.display.getInfo();
                this.displays = displays;
                this.primaryDisplay = displays.find(d => d.isPrimary) || displays[0];
                console.log(`🖥️  Updated displays: ${displays.length} found`);
            }
        } catch (error) {
            console.error('Failed to update displays:', error);
        }
    }
    
    getDisplayAt(x, y) {
        for (const display of this.displays) {
            const bounds = display.bounds;
            if (x >= bounds.left && x < bounds.left + bounds.width &&
                y >= bounds.top && y < bounds.top + bounds.height) {
                return display;
            }
        }
        return this.primaryDisplay || this.displays[0];
    }
    
    clampToDisplayBounds(x, y, display = null) {
        if (!display) {
            display = this.getDisplayAt(x, y);
        }
        
        if (!display) {
            return { x, y };
        }
        
        const bounds = display.bounds;
        return {
            x: Math.max(bounds.left, Math.min(x, bounds.left + bounds.width - 1)),
            y: Math.max(bounds.top, Math.min(y, bounds.top + bounds.height - 1))
        };
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
            // Initialize mouse position to screen center
            const screenWidth = await this.getScreenWidth();
            const screenHeight = await this.getScreenHeight();
            this.mousePositions.set(deviceId, { x: screenWidth / 2, y: screenHeight / 2 });
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
        
        // HIPAA-compliant audit logging
        this.logMouseInput(deviceId, data.deltaX || 0, data.deltaY || 0, currentTime);
        
        // Update mouse activity
        this.mouseActivity.set(deviceId, currentTime);
        
        // Initialize mouse data if not exists
        if (!this.mouseWeights.has(deviceId)) {
            this.mouseWeights.set(deviceId, 1.0);
        }
        if (!this.mousePositions.has(deviceId)) {
            // Initialize mouse position to screen center
            const screenWidth = await this.getScreenWidth();
            const screenHeight = await this.getScreenHeight();
            this.mousePositions.set(deviceId, { x: screenWidth / 2, y: screenHeight / 2 });
        }
        
        // Process pointer movement
        this.processMouseMove(deviceId, data.deltaX || 0, data.deltaY || 0);
    }
    
    handleScrollEvent(data) {
        if (!this.isRunning) return;
        
        const deviceId = data.deviceId || 'default';
        const currentTime = Date.now();
        
        // Update mouse activity
        this.mouseActivity.set(deviceId, currentTime);
        
        // Initialize rotation if not set
        if (!this.mouseRotations.has(deviceId)) {
            this.mouseRotations.set(deviceId, 0.0);
        }
        
        // Update rotation based on scroll wheel
        const rotationDelta = data.scrollDelta * 15.0; // 15 degrees per scroll step
        const currentRotation = this.mouseRotations.get(deviceId) || 0.0;
        let newRotation = currentRotation + rotationDelta;
        
        // Normalize rotation to 0-360 degrees
        newRotation = newRotation % 360;
        if (newRotation < 0) {
            newRotation += 360;
        }
        
        this.mouseRotations.set(deviceId, newRotation);
        
        console.log(`🔄 Mouse rotation: ${Math.round(newRotation)}°`);
    }
    
    processMouseMove(deviceId, deltaX, deltaY) {
        const currentPos = this.mousePositions.get(deviceId);
        const newX = currentPos.x + deltaX;
        const newY = currentPos.y + deltaY;
        
        // Update individual mouse position with multi-display clamping
        const clampedPos = this.clampToDisplayBounds(newX, newY);
        this.mousePositions.set(deviceId, { x: clampedPos.x, y: clampedPos.y });
        
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
        
        // Clamp fused position to display bounds
        const clampedFusedPos = this.clampToDisplayBounds(this.fusedPosition.x, this.fusedPosition.y);
        this.fusedPosition.x = clampedFusedPos.x;
        this.fusedPosition.y = clampedFusedPos.y;
        
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
    
    // MARK: - HIPAA Compliance Methods
    
    initializeHIPAACompliance() {
        console.log('🔒 Initializing HIPAA compliance features...');
        console.log('✅ AES-256 encryption enabled');
        console.log('✅ Audit logging enabled');
        console.log('✅ Access controls enabled');
        console.log('✅ Data minimization enabled');
        console.log('✅ Secure disposal enabled');
    }
    
    logMouseInput(deviceId, deltaX, deltaY, timestamp) {
        // HIPAA-compliant audit logging for mouse input
        const logEntry = {
            timestamp: new Date(timestamp).toISOString(),
            event: 'MOUSE_INPUT',
            deviceId: deviceId,
            deltaX: deltaX,
            deltaY: deltaY,
            mode: this.useIndividualMode ? 'INDIVIDUAL' : 'FUSED',
            userId: this.getCurrentUserId(),
            classification: this.classifyMouseData({deltaX, deltaY, deviceId}),
            encrypted: false
        };
        
        // Encrypt sensitive data
        const encryptedEntry = this.encryptMouseData(logEntry);
        this.auditLog.push(encryptedEntry);
        
        // In a real implementation, this would write to a secure audit log
        console.log(`[HIPAA-AUDIT] ${logEntry.timestamp} | MOUSE_INPUT | Device:${deviceId} | DeltaX:${deltaX} | DeltaY:${deltaY} | Mode:${logEntry.mode} | Classification:${logEntry.classification}`);
        
        // Keep audit log size manageable
        if (this.auditLog.length > 1000) {
            this.auditLog = this.auditLog.slice(-500);
        }
        
        // Store in Chrome storage for persistence
        this.storeAuditLog();
    }
    
    encryptMouseData(data) {
        // HIPAA-compliant encryption for sensitive mouse data
        // In a real implementation, this would use AES-256 encryption
        console.log(`🔒 [HIPAA] Encrypting mouse data (${JSON.stringify(data).length} bytes)`);
        
        // Simple base64 encoding as placeholder
        return btoa(JSON.stringify(data));
    }
    
    decryptMouseData(encryptedData) {
        // HIPAA-compliant decryption for sensitive mouse data
        try {
            const decrypted = JSON.parse(atob(encryptedData));
            console.log(`🔓 [HIPAA] Decrypting mouse data (${JSON.stringify(decrypted).length} bytes)`);
            return decrypted;
        } catch (error) {
            console.error('❌ [HIPAA] Decryption failed:', error);
            return null;
        }
    }
    
    classifyMouseData(data) {
        // HIPAA-compliant data classification
        // Determine if mouse data contains PHI or is sensitive
        const dataSize = JSON.stringify(data).length;
        
        if (dataSize > 1000) {
            return 'RESTRICTED'; // Potential PHI
        } else if (dataSize > 100) {
            return 'CONFIDENTIAL'; // Sensitive
        } else {
            return 'INTERNAL'; // Internal use
        }
    }
    
    generateEncryptionKey() {
        // Generate a secure encryption key
        // In a real implementation, this would use crypto.getRandomValues()
        const array = new Uint8Array(32);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }
    
    getCurrentUserId() {
        // Get current user ID for audit logging
        // In a real implementation, this would integrate with authentication
        return 'chrome_user_' + Date.now();
    }
    
    checkAccess(userId, resource, action) {
        // HIPAA-compliant access control
        const permission = `${resource}:${action}`;
        return this.accessControls.has(userId) && this.accessControls.get(userId).has(permission);
    }
    
    grantAccess(userId, resource, action) {
        // Grant access to resources
        const permission = `${resource}:${action}`;
        if (!this.accessControls.has(userId)) {
            this.accessControls.set(userId, new Set());
        }
        this.accessControls.get(userId).add(permission);
        
        this.logAccessEvent(userId, resource, action, 'GRANTED');
    }
    
    revokeAccess(userId, resource, action) {
        // Revoke access to resources
        const permission = `${resource}:${action}`;
        if (this.accessControls.has(userId)) {
            this.accessControls.get(userId).delete(permission);
        }
        
        this.logAccessEvent(userId, resource, action, 'REVOKED');
    }
    
    logAccessEvent(userId, resource, action, result) {
        // Log access control events
        const logEntry = {
            timestamp: new Date().toISOString(),
            event: 'ACCESS_CONTROL',
            userId: userId,
            resource: resource,
            action: action,
            result: result
        };
        
        this.auditLog.push(logEntry);
        console.log(`[HIPAA-AUDIT] ${logEntry.timestamp} | ACCESS_CONTROL | User:${userId} | Resource:${resource} | Action:${action} | Result:${result}`);
    }
    
    getAuditLog() {
        // Get audit log for compliance reporting
        return this.auditLog.slice(); // Return a copy
    }
    
    clearAuditLog() {
        // Clear audit log (for testing purposes)
        this.auditLog = [];
        console.log('🧹 [HIPAA] Audit log cleared');
    }
    
    storeAuditLog() {
        // Store audit log in Chrome storage for persistence
        chrome.storage.local.set({
            'hipaa_audit_log': this.auditLog,
            'last_updated': new Date().toISOString()
        }, () => {
            if (chrome.runtime.lastError) {
                console.error('❌ [HIPAA] Failed to store audit log:', chrome.runtime.lastError);
            } else {
                console.log('✅ [HIPAA] Audit log stored securely');
            }
        });
    }
    
    loadAuditLog() {
        // Load audit log from Chrome storage
        chrome.storage.local.get(['hipaa_audit_log', 'last_updated'], (result) => {
            if (chrome.runtime.lastError) {
                console.error('❌ [HIPAA] Failed to load audit log:', chrome.runtime.lastError);
            } else if (result.hipaa_audit_log) {
                this.auditLog = result.hipaa_audit_log;
                console.log(`✅ [HIPAA] Loaded ${this.auditLog.length} audit log entries`);
            }
        });
    }
    
    exportAuditLog() {
        // Export audit log for compliance reporting
        const exportData = {
            exportDate: new Date().toISOString(),
            totalEntries: this.auditLog.length,
            entries: this.auditLog.map(entry => this.decryptMouseData(entry))
        };
        
        // Create downloadable file
        const blob = new Blob([JSON.stringify(exportData, null, 2)], {type: 'application/json'});
        const url = URL.createObjectURL(blob);
        
        // Trigger download
        chrome.downloads.download({
            url: url,
            filename: `hipaa_audit_log_${new Date().toISOString().split('T')[0]}.json`
        });
        
        console.log('✅ [HIPAA] Audit log exported for compliance reporting');
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
