// 3 Blind Mice - Chrome Extension Popup Script
// Handles popup interface and user interactions

class PopupManager {
    constructor() {
        this.isRunning = false;
        this.useIndividualMode = false;
        this.mouseCount = 0;
        this.activeMouse = null;
        
        this.initialize();
    }
    
    initialize() {
        console.log('🐭 3 Blind Mice popup initialized');
        
        // Set up event listeners
        this.setupEventListeners();
        
        // Load initial status
        this.loadStatus();
        
        // Set up periodic status updates
        this.setupStatusUpdates();
    }
    
    setupEventListeners() {
        // Toggle triangulation button
        document.getElementById('toggleTriangulation').addEventListener('click', () => {
            this.toggleTriangulation();
        });
        
        // Toggle mode button
        document.getElementById('toggleMode').addEventListener('click', () => {
            this.toggleMode();
        });
        
        // Refresh status button
        document.getElementById('refreshStatus').addEventListener('click', () => {
            this.loadStatus();
        });
        
        // Listen for messages from background script
        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            this.handleMessage(message, sender, sendResponse);
        });
    }
    
    setupStatusUpdates() {
        // Update status every 2 seconds
        setInterval(() => {
            this.loadStatus();
        }, 2000);
    }
    
    async loadStatus() {
        try {
            // Send message to background script to get status
            const response = await this.sendMessageToBackground({ type: 'getStatus' });
            
            if (response) {
                this.updateStatus(response);
            }
        } catch (error) {
            console.error('Failed to load status:', error);
            this.showError('Failed to load status');
        }
    }
    
    updateStatus(status) {
        this.isRunning = status.isRunning;
        this.useIndividualMode = status.useIndividualMode;
        this.mouseCount = status.mouseCount;
        this.activeMouse = status.activeMouse;
        
        // Update UI elements
        this.updateStatusDisplay();
        this.updateButtons();
    }
    
    updateStatusDisplay() {
        // Update status text
        document.getElementById('status').textContent = this.isRunning ? 'Running' : 'Stopped';
        document.getElementById('mode').textContent = this.useIndividualMode ? 'Individual' : 'Fused';
        document.getElementById('mouseCount').textContent = this.mouseCount.toString();
        document.getElementById('activeMouse').textContent = this.activeMouse || 'None';
        
        // Update status color
        const statusElement = document.getElementById('status');
        if (this.isRunning) {
            statusElement.style.color = '#4CAF50';
        } else {
            statusElement.style.color = '#F44336';
        }
    }
    
    updateButtons() {
        const toggleButton = document.getElementById('toggleTriangulation');
        const modeButton = document.getElementById('toggleMode');
        
        // Update toggle button
        if (this.isRunning) {
            toggleButton.textContent = 'Stop Triangulation';
            toggleButton.className = 'button danger';
        } else {
            toggleButton.textContent = 'Start Triangulation';
            toggleButton.className = 'button primary';
        }
        
        // Update mode button
        if (this.useIndividualMode) {
            modeButton.textContent = 'Switch to Fused Mode';
        } else {
            modeButton.textContent = 'Switch to Individual Mode';
        }
        
        // Enable/disable buttons based on state
        modeButton.disabled = !this.isRunning;
    }
    
    async toggleTriangulation() {
        this.showLoading(true);
        
        try {
            const response = await this.sendMessageToBackground({ type: 'toggleTriangulation' });
            
            if (response && response.success) {
                // Status will be updated by the message handler
                console.log('Triangulation toggled successfully');
            } else {
                this.showError('Failed to toggle triangulation');
            }
        } catch (error) {
            console.error('Failed to toggle triangulation:', error);
            this.showError('Failed to toggle triangulation');
        } finally {
            this.showLoading(false);
        }
    }
    
    async toggleMode() {
        this.showLoading(true);
        
        try {
            const response = await this.sendMessageToBackground({ type: 'toggleMode' });
            
            if (response && response.success) {
                // Status will be updated by the message handler
                console.log('Mode toggled successfully');
            } else {
                this.showError('Failed to toggle mode');
            }
        } catch (error) {
            console.error('Failed to toggle mode:', error);
            this.showError('Failed to toggle mode');
        } finally {
            this.showLoading(false);
        }
    }
    
    handleMessage(message, sender, sendResponse) {
        switch (message.type) {
            case 'triangulationStateChanged':
                this.isRunning = message.isRunning;
                this.updateStatusDisplay();
                this.updateButtons();
                break;
                
            case 'modeChanged':
                this.useIndividualMode = message.useIndividualMode;
                this.updateStatusDisplay();
                this.updateButtons();
                break;
        }
    }
    
    async sendMessageToBackground(message) {
        return new Promise((resolve, reject) => {
            chrome.runtime.sendMessage(message, (response) => {
                if (chrome.runtime.lastError) {
                    reject(chrome.runtime.lastError);
                } else {
                    resolve(response);
                }
            });
        });
    }
    
    showLoading(show) {
        const loadingElement = document.getElementById('loading');
        loadingElement.style.display = show ? 'block' : 'none';
    }
    
    showError(message) {
        // Simple error display - could be enhanced with a proper error UI
        console.error('Popup error:', message);
        
        // Show error in status
        const statusElement = document.getElementById('status');
        const originalText = statusElement.textContent;
        statusElement.textContent = 'Error';
        statusElement.style.color = '#F44336';
        
        // Reset after 3 seconds
        setTimeout(() => {
            statusElement.textContent = originalText;
            statusElement.style.color = '';
        }, 3000);
    }
}

// Initialize popup manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new PopupManager();
});

// Handle popup close
window.addEventListener('beforeunload', () => {
    // Clean up any resources if needed
});
