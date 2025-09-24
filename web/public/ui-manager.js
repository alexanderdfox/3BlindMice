/**
 * UI Manager - Handles all UI updates and interactions
 */
class UIManager {
    constructor() {
        this.elements = {
            connectionIndicator: document.getElementById('connectionIndicator'),
            clientId: document.getElementById('clientId'),
            clientRole: document.getElementById('clientRole'),
            connectedMice: document.getElementById('connectedMice'),
            currentMode: document.getElementById('currentMode'),
            toggleMode: document.getElementById('toggleMode'),
            clearData: document.getElementById('clearData'),
            toggleFullscreen: document.getElementById('toggleFullscreen'),
            toggleCameras: document.getElementById('toggleCameras'),
            mouseList: document.getElementById('mouseList'),
            modeInfo: document.getElementById('modeInfo'),
            serverTime: document.getElementById('serverTime'),
            hostCursorControl: document.getElementById('hostCursorControl'),
            totalClients: document.getElementById('totalClients'),
            loadingOverlay: document.getElementById('loadingOverlay'),
            mouseArea: document.getElementById('mouseArea'),
            mouseCanvas: document.getElementById('mouseCanvas'),
            canvasOverlay: document.querySelector('.canvas-overlay'),
            cameraGrid: document.getElementById('cameraGrid'),
            serverUrlDisplay: document.getElementById('serverUrlDisplay')
        };
        
        this.state = {
            connected: false,
            clientId: null,
            isHost: false,
            mode: 'fused',
            mice: new Map(),
            serverInfo: null,
            isFullscreen: false,
            camerasVisible: false,
            cameraStreams: []
        };
        
        this.setupEventListeners();
        this.setupFullscreenListeners();
        this.updateServerUrlDisplay();
    }
    
    setupEventListeners() {
        // Toggle mode button
        this.elements.toggleMode.addEventListener('click', () => {
            this.onToggleMode();
        });
        
        // Clear data button
        this.elements.clearData.addEventListener('click', () => {
            this.onClearData();
        });
        
        // Fullscreen button
        this.elements.toggleFullscreen.addEventListener('click', () => {
            this.onToggleFullscreen();
        });
        
        // Hide center overlay on click within mouse area
        this.elements.mouseArea.addEventListener('click', () => {
            if (this.elements.canvasOverlay) {
                this.elements.canvasOverlay.classList.add('hidden');
            }
        });
        
        // Window resize
        window.addEventListener('resize', () => {
            this.onWindowResize();
        });
        
        // Cameras toggle
        if (this.elements.toggleCameras) {
            this.elements.toggleCameras.addEventListener('click', async () => {
                this.state.camerasVisible = !this.state.camerasVisible;
                if (this.state.camerasVisible) {
                    await this.showCameras();
                    this.elements.toggleCameras.innerHTML = '<span class="btn-icon">🛑</span> Hide Cameras';
                } else {
                    await this.hideCameras();
                    this.elements.toggleCameras.innerHTML = '<span class="btn-icon">📷</span> Cameras';
                }
            });
        }
    }
    
    setupFullscreenListeners() {
        const handler = () => {
            this.state.isFullscreen = !!document.fullscreenElement;
            if (window.app && window.app.mouseTracker) {
                // Resize canvas to container
                window.app.mouseTracker.resizeCanvas();
            }
            // Update button text
            if (this.elements.toggleFullscreen) {
                this.elements.toggleFullscreen.innerHTML = this.state.isFullscreen
                    ? '<span class="btn-icon">🗗</span> Exit Full Screen'
                    : '<span class="btn-icon">⛶</span> Full Screen';
            }
        };
        document.addEventListener('fullscreenchange', handler);
        document.addEventListener('webkitfullscreenchange', handler);
        document.addEventListener('mozfullscreenchange', handler);
        document.addEventListener('MSFullscreenChange', handler);
    }
    
    onToggleFullscreen() {
        const container = this.elements.mouseArea;
        if (!container) return;
        
        if (!document.fullscreenElement) {
            if (container.requestFullscreen) container.requestFullscreen();
            else if (container.webkitRequestFullscreen) container.webkitRequestFullscreen();
            else if (container.mozRequestFullScreen) container.mozRequestFullScreen();
            else if (container.msRequestFullscreen) container.msRequestFullscreen();
        } else {
            if (document.exitFullscreen) document.exitFullscreen();
            else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
            else if (document.mozCancelFullScreen) document.mozCancelFullScreen();
            else if (document.msExitFullscreen) document.msExitFullscreen();
        }
    }
    
    // Connection status updates
    updateConnectionStatus(connected, clientId = null, isHost = false) {
        this.state.connected = connected;
        this.state.clientId = clientId;
        this.state.isHost = isHost;
        
        const statusDot = this.elements.connectionIndicator.querySelector('.status-dot');
        const statusText = this.elements.connectionIndicator.querySelector('.status-text');
        
        if (connected) {
            statusDot.className = 'status-dot connected';
            statusText.textContent = 'Connected';
            this.elements.clientId.textContent = clientId ? clientId.substring(0, 8) + '...' : '-';
            this.elements.clientRole.textContent = isHost ? 'Host' : 'Client';
            this.elements.toggleMode.disabled = !isHost;
            this.hideLoading();
        } else {
            statusDot.className = 'status-dot disconnected';
            statusText.textContent = 'Disconnected';
            this.elements.clientId.textContent = '-';
            this.elements.clientRole.textContent = '-';
            this.elements.toggleMode.disabled = true;
            this.showLoading();
        }
    }
    
    updateMode(mode, activeMouse = null) {
        this.state.mode = mode;
        this.elements.currentMode.textContent = mode.charAt(0).toUpperCase() + mode.slice(1);
        
        // Update mode info text
        if (mode === 'individual') {
            this.elements.modeInfo.textContent = 'Individual Mode: Each mouse controls cursor independently';
            if (activeMouse) {
                this.elements.modeInfo.textContent += ` (Active: ${activeMouse.substring(0, 8)}...)`;
            }
        } else {
            this.elements.modeInfo.textContent = 'Fused Mode: All mice contribute to single cursor position';
        }
    }
    
    updateMice(mice) {
        this.state.mice.clear();
        
        if (mice && mice.length > 0) {
            mice.forEach(mouse => {
                this.state.mice.set(mouse.id, mouse);
            });
        }
        
        this.elements.connectedMice.textContent = this.state.mice.size;
        this.renderMouseList();
    }
    
    renderMouseList() {
        if (this.state.mice.size === 0) {
            this.elements.mouseList.innerHTML = '<div class="no-mice">No mice connected</div>';
            return;
        }
        
        const mouseItems = Array.from(this.state.mice.values()).map(mouse => {
            const isActive = mouse.isActive;
            const lastActivity = mouse.lastActivity ? new Date(mouse.lastActivity) : null;
            const activityText = this.getActivityText(lastActivity);
            const weight = mouse.weight.toFixed(1);
            
            return `
                <div class="mouse-item ${isActive ? 'active' : ''}">
                    <div class="mouse-emoji">${this.getMouseEmoji(mouse.id)}</div>
                    <div class="mouse-info">
                        <div class="mouse-id">${mouse.id.substring(0, 8)}...</div>
                        <div class="mouse-position">(${Math.round(mouse.position.x)}, ${Math.round(mouse.position.y)})</div>
                    </div>
                    <div class="mouse-stats">
                        <div class="mouse-weight">W: ${weight}</div>
                        <div class="mouse-rotation">R: ${Math.round(mouse.rotation || 0)}°</div>
                        <div class="mouse-activity ${lastActivity && (Date.now() - lastActivity.getTime()) < 2000 ? '' : 'inactive'}">
                            ${activityText}
                        </div>
                    </div>
                </div>
            `;
        }).join('');
        
        this.elements.mouseList.innerHTML = mouseItems;
    }
    
    getMouseEmoji(mouseId) {
        // Simple emoji assignment based on mouse ID
        const emojis = ['🐭', '🐹', '🐰', '🐱', '🐶', '🐸', '🐵', '🐼', '🐨', '🐯'];
        const hash = mouseId.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
        return emojis[hash % emojis.length];
    }
    
    getActivityText(lastActivity) {
        if (!lastActivity) return 'Never';
        
        const timeDiff = Date.now() - lastActivity.getTime();
        
        if (timeDiff < 1000) return 'Now';
        if (timeDiff < 60000) return `${Math.floor(timeDiff / 1000)}s ago`;
        if (timeDiff < 3600000) return `${Math.floor(timeDiff / 60000)}m ago`;
        return `${Math.floor(timeDiff / 3600000)}h ago`;
    }
    
    updateServerInfo(serverInfo) {
        this.state.serverInfo = serverInfo;
        
        if (serverInfo) {
            this.elements.serverTime.textContent = new Date(serverInfo.serverTime).toLocaleTimeString();
            this.elements.hostCursorControl.textContent = serverInfo.hostCursorControl ? 'Enabled' : 'Disabled';
            this.elements.totalClients.textContent = serverInfo.connectedClients;
        }
    }
    
    // Loading overlay
    showLoading() {
        this.elements.loadingOverlay.classList.remove('hidden');
    }
    
    hideLoading() {
        this.elements.loadingOverlay.classList.add('hidden');
    }
    
    // Event handlers
    onToggleMode() {
        // This will be called by the main app when the socket is available
        if (this.state.isHost && this.state.connected) {
            // Emit through the main app's socket
            if (window.app && window.app.socket) {
                window.app.socket.emit('toggleMode');
            }
        }
    }
    
    onClearData() {
        // Clear all mouse data and reset UI
        this.state.mice.clear();
        this.updateMice([]);
        
        // Reset mode info
        this.elements.modeInfo.textContent = 'Move your mouse to start tracking';
        
        // Show confirmation
        this.showNotification('Data cleared', 'success');
    }
    
    onWindowResize() {
        // Handle window resize
        if (window.app && window.app.mouseTracker) {
            window.app.mouseTracker.resizeCanvas();
        }
    }
    
    // Notification system
    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        // Style the notification
        Object.assign(notification.style, {
            position: 'fixed',
            top: '20px',
            right: '20px',
            padding: '12px 20px',
            borderRadius: '8px',
            color: 'white',
            fontWeight: '600',
            zIndex: '1001',
            transform: 'translateX(100%)',
            transition: 'transform 0.3s ease'
        });
        
        // Set background color based on type
        switch (type) {
            case 'success':
                notification.style.background = '#4CAF50';
                break;
            case 'error':
                notification.style.background = '#f44336';
                break;
            case 'warning':
                notification.style.background = '#ff9800';
                break;
            default:
                notification.style.background = '#667eea';
        }
        
        // Add to page
        document.body.appendChild(notification);
        
        // Animate in
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 100);
        
        // Remove after delay
        setTimeout(() => {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 3000);
    }
    
    // Keyboard shortcuts
    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Only handle shortcuts when not in input fields
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                return;
            }
            
            switch (e.key.toLowerCase()) {
                case 'm':
                    if (this.state.isHost) {
                        this.onToggleMode();
                    }
                    break;
                case 'c':
                    this.onClearData();
                    break;
                case 'h':
                    this.toggleInstructions();
                    break;
            }
        });
    }
    
    toggleInstructions() {
        const instructionsCard = document.querySelector('.instructions-card');
        if (instructionsCard) {
            instructionsCard.style.display = instructionsCard.style.display === 'none' ? 'block' : 'none';
        }
    }
    
    // Update mouse tracking status
    updateMouseTrackingStatus(isTracking) {
        const canvas = document.getElementById('mouseCanvas');
        if (canvas) {
            canvas.style.cursor = isTracking ? 'crosshair' : 'default';
        }
        
        // Update mode info to show tracking status
        if (isTracking) {
            this.elements.modeInfo.textContent = 'Mouse tracking active - move to control cursor';
        } else {
            this.elements.modeInfo.textContent = 'Move mouse over the tracking area to start';
        }
    }
    
    // Public API
    getState() {
        return { ...this.state };
    }
    
    updateServerUrlDisplay() {
        if (this.elements.serverUrlDisplay) {
            const url = (window.APP_CONFIG && window.APP_CONFIG.serverUrl) || window.location.origin;
            this.elements.serverUrlDisplay.textContent = url;
        }
    }
    
    setState(newState) {
        this.state = { ...this.state, ...newState };
        if (newState.serverUrl) {
            if (!window.APP_CONFIG) window.APP_CONFIG = {};
            window.APP_CONFIG.serverUrl = newState.serverUrl;
            this.updateServerUrlDisplay();
        }
    }

    async showCameras() {
        const grid = this.elements.cameraGrid;
        if (!grid) return;
        grid.classList.remove('hidden');
        
        try {
            const devices = await navigator.mediaDevices.enumerateDevices();
            const cams = devices.filter(d => d.kind === 'videoinput');
            
            // If no permission yet, request once
            if (cams.length > 0 && !this.state.cameraStreams.length) {
                // Request with default to unlock labels and permissions
                await navigator.mediaDevices.getUserMedia({ video: true, audio: false }).then(s => s.getTracks().forEach(t => t.stop())).catch(() => {});
            }
            
            // Clear existing tiles
            grid.innerHTML = '';
            // Stop existing streams
            await this.hideCameras();
            grid.classList.remove('hidden');
            
            const refreshed = await navigator.mediaDevices.enumerateDevices();
            const videoInputs = refreshed.filter(d => d.kind === 'videoinput');
            
            for (let i = 0; i < videoInputs.length; i++) {
                const dev = videoInputs[i];
                const constraints = { video: { deviceId: { exact: dev.deviceId } }, audio: false };
                try {
                    const stream = await navigator.mediaDevices.getUserMedia(constraints);
                    this.state.cameraStreams.push(stream);
                    const tile = document.createElement('div');
                    tile.className = 'camera-tile';
                    const video = document.createElement('video');
                    video.autoplay = true;
                    video.muted = true;
                    video.playsInline = true;
                    video.srcObject = stream;
                    const label = document.createElement('div');
                    label.className = 'label';
                    label.textContent = dev.label || `Camera ${i+1}`;
                    tile.appendChild(video);
                    tile.appendChild(label);
                    grid.appendChild(tile);
                } catch (e) {
                    console.warn('Camera access failed for device', dev.label, e);
                }
            }
        } catch (err) {
            console.error('Unable to enumerate cameras:', err);
        }
    }
    
    async hideCameras() {
        const grid = this.elements.cameraGrid;
        if (grid) grid.classList.add('hidden');
        for (const s of this.state.cameraStreams) {
            try { s.getTracks().forEach(t => t.stop()); } catch {}
        }
        this.state.cameraStreams = [];
        if (grid) grid.innerHTML = '';
    }
}
