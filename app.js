/**
 * Main Application - Coordinates all components
 */
class App {
    constructor() {
        this.socket = null;
        this.mouseTracker = null;
        this.uiManager = null;
        
        this.config = {
            serverUrl: (window.APP_CONFIG && window.APP_CONFIG.serverUrl) || window.location.origin,
            reconnectAttempts: 5,
            reconnectDelay: 1000,
            localMode: (window.APP_CONFIG && window.APP_CONFIG.localMode) || false
        };
        
        this.state = {
            connected: false,
            clientId: null,
            isHost: false,
            mode: 'fused',
            activeMouse: null
        };
        
        this.init();
    }
    
    async init() {
        console.log('🐭 3 Blind Mice Web App Starting...');
        console.log('⚙️ Server URL:', this.config.serverUrl);
        console.log('⚙️ Local mode:', this.config.localMode);
        
        // Initialize UI Manager
        this.uiManager = new UIManager();
        
        // Setup keyboard shortcuts
        this.uiManager.setupKeyboardShortcuts();
        
        // Initialize mouse tracker (will be connected to socket later)
        const canvas = document.getElementById('mouseCanvas');
        this.mouseTracker = new MouseTracker(canvas, null);
        
        if (this.config.localMode) {
            console.log('🌐 Local-only mode enabled (no server required).');
            // Fake a single "mouse" entry using local position
            setInterval(() => {
                const fakeId = 'local-mouse';
                const positions = new Map([[fakeId, this.mouseTracker.currentPosition]]);
                const weights = new Map([[fakeId, 1.0]]);
                const activity = new Map([[fakeId, new Date()]]);
                const rotations = new Map([[fakeId, this.mouseTracker.cursorRotation || 0]]);
                // Update internal maps for rendering
                this.mouseTracker.mousePositions = positions;
                this.mouseTracker.mouseWeights = weights;
                this.mouseTracker.mouseActivity = activity;
                this.mouseTracker.mouseRotations = rotations;
                // Update UI list
                this.uiManager.updateMice([{ id: fakeId, position: this.mouseTracker.currentPosition, weight: 1.0, lastActivity: new Date(), rotation: this.mouseTracker.cursorRotation || 0, isActive: true }]);
                this.uiManager.updateMode('individual', fakeId);
                this.uiManager.updateConnectionStatus(true, 'local', true);
            }, 100);
            return;
        }
        
        // Ensure Socket.IO client is available
        if (window.__ensureSocketIoClient) {
            try { await window.__ensureSocketIoClient(); } catch(e) {}
        }
        
        // Connect to server
        await this.connectToServer();
        
        // Make app globally available
        window.app = this;
    }
    
    async connectToServer() {
        try {
            if (typeof io === 'undefined') {
                throw new Error('Socket.IO client not loaded');
            }
            const url = this.config.serverUrl;
            console.log('🔌 Connecting to', url);
            // Explicit path and transport fallbacks
            this.socket = io(url, {
                path: '/socket.io',
                transports: ['websocket', 'polling'],
                withCredentials: false,
                reconnectionAttempts: this.config.reconnectAttempts,
                reconnectionDelay: this.config.reconnectDelay
            });
            
            this.mouseTracker.socket = this.socket;
            this.setupSocketListeners();
        } catch (error) {
            console.error('❌ Failed to connect to server:', error);
            this.uiManager.showNotification('Failed to connect. Check server URL and CORS.', 'error');
            this.uiManager.updateConnectionStatus(false);
        }
    }
    
    setupSocketListeners() {
        // Connection events
        this.socket.on('connect', () => {
            console.log('✅ Connected to server');
            this.state.connected = true;
            this.uiManager.showNotification('Connected to server', 'success');
        });
        
        this.socket.on('disconnect', (reason) => {
            console.log('🔌 Disconnected from server:', reason);
            this.state.connected = false;
            this.uiManager.updateConnectionStatus(false);
            
            if (reason === 'io server disconnect') {
                this.uiManager.showNotification('Disconnected by server', 'warning');
            } else {
                this.uiManager.showNotification('Connection lost', 'error');
            }
        });
        
        this.socket.on('connect_error', (error) => {
            console.error('❌ Connection error:', error);
            this.uiManager.showNotification('Connection error', 'error');
            this.uiManager.updateConnectionStatus(false);
        });
        
        // Configuration
        this.socket.on('config', (config) => {
            console.log('⚙️ Received config:', config);
            this.state.clientId = config.clientId;
            this.state.isHost = config.isHost;
            if (this.mouseTracker) this.mouseTracker.physicsEnabled = !!config.physicsEnabled;
            
            this.uiManager.updateConnectionStatus(true, config.clientId, config.isHost);
            
            if (config.isHost) {
                this.uiManager.showNotification('You are the host computer', 'success');
            }
        });
        
        // Mouse data updates
        this.socket.on('mouseData', (data) => {
            console.log('🖱️ Received initial mouse data:', data);
            this.updateMouseData(data);
        });
        
        this.socket.on('mouseUpdate', (data) => {
            this.updateMouseData(data);
        });
        
        // Mode changes
        this.socket.on('modeChanged', (data) => {
            console.log('🔄 Mode changed:', data);
            this.state.mode = data.mode;
            this.state.activeMouse = data.activeMouse;
            
            this.uiManager.updateMode(data.mode, data.activeMouse);
        });
        
        // Host promotion
        this.socket.on('promotedToHost', () => {
            console.log('👑 Promoted to host');
            this.state.isHost = true;
            this.uiManager.updateConnectionStatus(true, this.state.clientId, true);
            this.uiManager.showNotification('You are now the host computer', 'success');
        });
        // Physics changed
        this.socket.on('physicsChanged', (data) => {
            if (this.mouseTracker) this.mouseTracker.physicsEnabled = !!data.physicsEnabled;
        });
        
        // Error handling
        this.socket.on('error', (error) => {
            console.error('❌ Socket error:', error);
            this.uiManager.showNotification(`Error: ${error.message}`, 'error');
        });
    }
    
    updateMouseData(data) {
        // Update mouse tracker
        this.mouseTracker.updateMouseData(data);
        
        // Update UI
        this.uiManager.updateMice(data.mice);
        
        // Update state
        this.state.mode = data.mode;
        this.state.activeMouse = data.activeMouse;
        this.uiManager.updateMode(data.mode, data.activeMouse);
    }
    
    // Server communication methods
    async fetchServerStatus() {
        try {
            const response = await fetch('/api/status');
            const data = await response.json();
            
            this.uiManager.updateServerInfo(data);
            return data;
        } catch (error) {
            console.error('❌ Failed to fetch server status:', error);
            return null;
        }
    }
    
    async fetchMouseData() {
        try {
            const response = await fetch('/api/mice');
            const data = await response.json();
            
            this.updateMouseData(data);
            return data;
        } catch (error) {
            console.error('❌ Failed to fetch mouse data:', error);
            return null;
        }
    }
    
    // Public methods for UI callbacks
    toggleMode() {
        if (this.state.isHost && this.state.connected) {
            this.socket.emit('toggleMode');
            this.uiManager.showNotification('Mode toggle requested', 'info');
        }
    }
    
    clearData() {
        this.uiManager.onClearData();
        this.mouseTracker.clearCanvas();
    }
    
    // Mouse tracking control
    startMouseTracking() {
        if (this.mouseTracker) {
            this.mouseTracker.startTracking();
            this.uiManager.updateMouseTrackingStatus(true);
        }
    }
    
    stopMouseTracking() {
        if (this.mouseTracker) {
            this.mouseTracker.stopTracking();
            this.uiManager.updateMouseTrackingStatus(false);
        }
    }
    
    // Configuration methods
    setTrackingSensitivity(sensitivity) {
        if (this.mouseTracker) {
            this.mouseTracker.setConfig({ trackingSensitivity: sensitivity });
        }
    }
    
    setVisualSettings(settings) {
        if (this.mouseTracker) {
            this.mouseTracker.setVisualSettings(settings);
        }
    }
    
    // Utility methods
    getState() {
        return { ...this.state };
    }
    
    getConfig() {
        return { ...this.config };
    }
    
    // Cleanup
    destroy() {
        if (this.socket) {
            this.socket.disconnect();
        }
        
        if (this.mouseTracker) {
            this.mouseTracker.stopTracking();
        }
        
        console.log('🛑 App destroyed');
    }
}

// Initialize app when DOM is ready (handles late script injection)
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        console.log('🚀 Initializing 3 Blind Mice Web App...');
        window.app = new App();
    });
} else {
    console.log('🚀 Initializing 3 Blind Mice Web App...');
    window.app = new App();
}

// Handle page unload
window.addEventListener('beforeunload', () => {
    if (window.app) {
        window.app.destroy();
    }
});

// Handle visibility change (pause/resume tracking)
document.addEventListener('visibilitychange', () => {
    if (window.app) {
        if (document.hidden) {
            window.app.stopMouseTracking();
        } else {
            window.app.startMouseTracking();
        }
    }
});

// Handle online/offline events
window.addEventListener('online', () => {
    console.log('🌐 Back online');
    if (window.app && !window.app.state.connected) {
        window.app.connectToServer();
    }
});

window.addEventListener('offline', () => {
    console.log('📴 Gone offline');
    if (window.app) {
        window.app.stopMouseTracking();
    }
});

// Periodic server status updates
setInterval(() => {
    if (window.app && window.app.state.connected) {
        window.app.fetchServerStatus();
    }
}, 5000); // Update every 5 seconds
