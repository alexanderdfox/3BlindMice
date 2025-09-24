const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Import robotjs for cursor control (only works on host computer)
let robot;
try {
    robot = require('robotjs');
} catch (error) {
    console.warn('⚠️  robotjs not available - cursor control disabled');
    console.warn('   Install robotjs for host computer cursor control');
}

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

        // Store connected clients and their mouse data
        const clients = new Map();
        const mouseData = new Map();
        const mouseWeights = new Map();
        const mouseActivity = new Map();
        const mousePositions = new Map();
        const mouseRotations = new Map(); // Mouse rotation tracking

// Configuration
const config = {
    port: process.env.PORT || 3000,
    maxClients: 10,
    activityTimeout: 2000, // 2 seconds
    smoothingFactor: 0.7,
    enableHostCursorControl: !!robot
};

// Host computer cursor position
let hostCursorPosition = { x: 960, y: 540 }; // Start at screen center
let useIndividualMode = false;
let activeMouseId = null;

console.log('🐭 3 Blind Mice Web Server Starting...');
console.log(`📡 Port: ${config.port}`);
console.log(`🎮 Host cursor control: ${config.enableHostCursorControl ? 'ENABLED' : 'DISABLED'}`);

// Serve main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Get server status
app.get('/api/status', (req, res) => {
    res.json({
        connectedClients: clients.size,
        activeMice: mouseData.size,
        mode: useIndividualMode ? 'individual' : 'fused',
        hostCursorControl: config.enableHostCursorControl,
        serverTime: new Date().toISOString()
    });
});

// Get mouse positions
app.get('/api/mice', (req, res) => {
    const mice = Array.from(mouseData.entries()).map(([id, data]) => ({
        id,
        position: mousePositions.get(id) || { x: 0, y: 0 },
        weight: mouseWeights.get(id) || 1.0,
        lastActivity: mouseActivity.get(id) || null,
        isActive: id === activeMouseId
    }));
    
    res.json({
        mice,
        hostPosition: hostCursorPosition,
        mode: useIndividualMode ? 'individual' : 'fused',
        activeMouse: activeMouseId
    });
});

// Socket.IO connection handling
io.on('connection', (socket) => {
    const clientId = uuidv4();
    const clientInfo = {
        id: clientId,
        socket: socket,
        connectedAt: new Date(),
        lastActivity: new Date(),
        isHost: false
    };
    
    console.log(`🔌 Client connected: ${clientId}`);
    
    // Check if this is the first client (host)
    if (clients.size === 0) {
        clientInfo.isHost = true;
        console.log(`👑 Client ${clientId} designated as host`);
    }
    
    clients.set(clientId, clientInfo);
    
    // Send initial configuration
    socket.emit('config', {
        clientId,
        isHost: clientInfo.isHost,
        mode: useIndividualMode ? 'individual' : 'fused',
        hostCursorControl: config.enableHostCursorControl,
        maxClients: config.maxClients
    });
    
    // Send current mouse data
    socket.emit('mouseData', {
        mice: Array.from(mouseData.entries()).map(([id, data]) => ({
            id,
            position: mousePositions.get(id) || { x: 0, y: 0 },
            weight: mouseWeights.get(id) || 1.0,
            lastActivity: mouseActivity.get(id) || null,
            isActive: id === activeMouseId
        })),
        hostPosition: hostCursorPosition,
        mode: useIndividualMode ? 'individual' : 'fused',
        activeMouse: activeMouseId
    });
    
    // Handle mouse movement
    socket.on('mouseMove', (data) => {
        const { deltaX, deltaY, timestamp } = data;
        const currentTime = new Date();
        
        // Update client activity
        clientInfo.lastActivity = currentTime;
        
        // Update mouse data
        mouseData.set(clientId, {
            deltaX: (mouseData.get(clientId)?.deltaX || 0) + deltaX,
            deltaY: (mouseData.get(clientId)?.deltaY || 0) + deltaY,
            timestamp
        });
        
        // Update mouse activity and weight
        mouseActivity.set(clientId, currentTime);
        updateMouseWeights();
        
        // Update individual mouse position
        updateIndividualMousePosition(clientId, deltaX, deltaY);
        
        // Handle cursor movement based on mode
        if (useIndividualMode) {
            handleIndividualMode(clientId);
        } else {
            fuseAndMoveCursor();
        }
        
        // Broadcast updated data to all clients
        broadcastMouseUpdate();
    });
    
    // Handle mode toggle (only host can toggle)
    socket.on('toggleMode', () => {
        if (clientInfo.isHost) {
            useIndividualMode = !useIndividualMode;
            activeMouseId = useIndividualMode ? null : activeMouseId;
            
            console.log(`🔄 Mode switched to: ${useIndividualMode ? 'Individual' : 'Fused'}`);
            
            // Broadcast mode change
            io.emit('modeChanged', {
                mode: useIndividualMode ? 'individual' : 'fused',
                activeMouse: activeMouseId
            });
        }
    });
    
    // Handle host cursor control
    socket.on('hostCursorMove', (data) => {
        if (clientInfo.isHost && config.enableHostCursorControl && robot) {
            const { x, y } = data;
            hostCursorPosition = { x, y };
            
            try {
                robot.moveMouse(x, y);
                console.log(`🎯 Host cursor moved to: (${x}, ${y})`);
            } catch (error) {
                console.error('❌ Error moving host cursor:', error);
            }
        }
    });
    
    // Handle scroll wheel input for cursor rotation
    socket.on('scrollInput', (data) => {
        const { scrollDelta, rotation, timestamp } = data;
        const currentTime = new Date();
        
        // Update client activity
        clientInfo.lastActivity = currentTime;
        
        // Update mouse rotation
        mouseRotations.set(clientId, rotation || 0);
        
        console.log(`🔄 Mouse rotation: ${Math.round(rotation)}°`);
        
        // Broadcast updated data to all clients
        broadcastMouseUpdate();
    });
    
    // Handle mouse click events
    socket.on('mouseClick', (data) => {
        if (clientInfo.isHost && config.enableHostCursorControl && robot) {
            const { button, doubleClick } = data;
            
            try {
                if (doubleClick) {
                    robot.mouseClick(button, true);
                } else {
                    robot.mouseClick(button);
                }
                console.log(`🖱️  Host mouse ${button} click`);
            } catch (error) {
                console.error('❌ Error with mouse click:', error);
            }
        }
    });
    
    // Handle disconnect
    socket.on('disconnect', () => {
        console.log(`🔌 Client disconnected: ${clientId}`);
        
        // Remove client data
        clients.delete(clientId);
        mouseData.delete(clientId);
        mouseWeights.delete(clientId);
        mouseActivity.delete(clientId);
        mousePositions.delete(clientId);
        
        // If this was the active mouse, clear it
        if (activeMouseId === clientId) {
            activeMouseId = null;
        }
        
        // If this was the host, promote another client
        if (clientInfo.isHost && clients.size > 0) {
            const newHost = Array.from(clients.values())[0];
            newHost.isHost = true;
            console.log(`👑 New host: ${newHost.id}`);
            
            // Notify new host
            newHost.socket.emit('promotedToHost');
        }
        
        // Broadcast updated data
        broadcastMouseUpdate();
    });
});

// Mouse weight calculation (similar to Swift version)
function updateMouseWeights() {
    const currentTime = new Date();
    
    for (const [clientId, lastActivity] of mouseActivity.entries()) {
        const timeSinceActivity = currentTime - lastActivity;
        
        // Reduce weight for inactive mice
        if (timeSinceActivity > config.activityTimeout) {
            mouseWeights.set(clientId, Math.max(0.1, (mouseWeights.get(clientId) || 1.0) * 0.9));
        } else {
            // Increase weight for active mice
            mouseWeights.set(clientId, Math.min(2.0, (mouseWeights.get(clientId) || 1.0) * 1.1));
        }
    }
}

// Update individual mouse position
function updateIndividualMousePosition(clientId, deltaX, deltaY) {
    const currentPos = mousePositions.get(clientId) || { x: 960, y: 540 }; // Start at screen center
    const newX = currentPos.x + deltaX;
    const newY = currentPos.y + deltaY;
    
    // Clamp to screen bounds (assuming 1920x1080 for now)
    mousePositions.set(clientId, {
        x: Math.max(0, Math.min(newX, 1920 - 1)),
        y: Math.max(0, Math.min(newY, 1080 - 1))
    });
}

// Handle individual mode
function handleIndividualMode(clientId) {
    activeMouseId = clientId;
    
    if (config.enableHostCursorControl && robot) {
        const position = mousePositions.get(clientId);
        if (position) {
            hostCursorPosition = position;
            try {
                robot.moveMouse(position.x, position.y);
            } catch (error) {
                console.error('❌ Error moving cursor in individual mode:', error);
            }
        }
    }
    
    // Clear deltas after processing
    const mouse = mouseData.get(clientId);
    if (mouse) {
        mouse.deltaX = 0;
        mouse.deltaY = 0;
    }
}

// Fuse mouse movements (similar to Swift triangulation)
function fuseAndMoveCursor() {
    if (mouseData.size === 0) return;
    
    // Calculate weighted average of mouse movements
    let weightedTotalX = 0;
    let weightedTotalY = 0;
    let totalWeight = 0;
    
    for (const [clientId, mouse] of mouseData.entries()) {
        const weight = mouseWeights.get(clientId) || 1.0;
        weightedTotalX += mouse.deltaX * weight;
        weightedTotalY += mouse.deltaY * weight;
        totalWeight += weight;
    }
    
    if (totalWeight === 0) return;
    
    const avgX = weightedTotalX / totalWeight;
    const avgY = weightedTotalY / totalWeight;
    
    // Update host cursor position with smoothing
    const smoothing = config.smoothingFactor;
    hostCursorPosition.x = hostCursorPosition.x * (1 - smoothing) + (hostCursorPosition.x + avgX) * smoothing;
    hostCursorPosition.y = hostCursorPosition.y * (1 - smoothing) + (hostCursorPosition.y + avgY) * smoothing;
    
    // Clamp to screen bounds
    hostCursorPosition.x = Math.max(0, Math.min(hostCursorPosition.x, 1920 - 1));
    hostCursorPosition.y = Math.max(0, Math.min(hostCursorPosition.y, 1080 - 1));
    
    // Move host cursor if enabled
    if (config.enableHostCursorControl && robot) {
        try {
            robot.moveMouse(Math.round(hostCursorPosition.x), Math.round(hostCursorPosition.y));
        } catch (error) {
            console.error('❌ Error moving cursor in fused mode:', error);
        }
    }
    
    // Clear deltas after processing
    for (const mouse of mouseData.values()) {
        mouse.deltaX = 0;
        mouse.deltaY = 0;
    }
}

// Broadcast mouse data to all clients
function broadcastMouseUpdate() {
    const mice = Array.from(mouseData.entries()).map(([id, data]) => ({
        id,
        position: mousePositions.get(id) || { x: 0, y: 0 },
        weight: mouseWeights.get(id) || 1.0,
        lastActivity: mouseActivity.get(id) || null,
        rotation: mouseRotations.get(id) || 0.0,
        isActive: id === activeMouseId
    }));
    
    io.emit('mouseUpdate', {
        mice,
        hostPosition: hostCursorPosition,
        mode: useIndividualMode ? 'individual' : 'fused',
        activeMouse: activeMouseId
    });
}

// Start server
server.listen(config.port, () => {
    console.log(`🚀 3 Blind Mice Web Server running on port ${config.port}`);
    console.log(`🌐 Open http://localhost:${config.port} to connect clients`);
    console.log(`📊 API available at http://localhost:${config.port}/api/status`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down server...');
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});
