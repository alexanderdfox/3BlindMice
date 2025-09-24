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
    },
    path: '/socket.io'
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
    maxClients: 50,
    activityTimeout: 2000, // 2 seconds
    smoothingFactor: 0.7,
    enableHostCursorControl: !!robot
};

// Host computer cursor position
let hostCursorPosition = { x: 960, y: 540 }; // Start at screen center
let hostVelocity = { x: 0, y: 0 }; // For physics mode
let useIndividualMode = false;
let activeMouseId = null;
let currentHostId = null;
let usePhysics = false; // 3-body style fusion toggle

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
        serverTime: new Date().toISOString(),
        hostId: currentHostId
    });
});

// Get mouse positions
app.get('/api/mice', (req, res) => {
    const mice = Array.from(mouseData.entries()).map(([id, data]) => ({
        id,
        position: mousePositions.get(id) || { x: 0, y: 0 },
        weight: mouseWeights.get(id) || 1.0,
        lastActivity: mouseActivity.get(id) || null,
        rotation: mouseRotations.get(id) || 0.0,
        isActive: id === activeMouseId
    }));
    
    res.json({
        mice,
        hostPosition: hostCursorPosition,
        mode: useIndividualMode ? 'individual' : 'fused',
        activeMouse: activeMouseId,
        hostId: currentHostId
    });
});

function broadcastClientList() {
    const list = Array.from(clients.values()).map(c => ({ id: c.id, isHost: c.isHost, connectedAt: c.connectedAt }));
    io.emit('clients', { clients: list, hostId: currentHostId });
}

// Socket.IO connection handling
io.on('connection', (socket) => {
    const clientId = uuidv4();
    const remote = socket.handshake.address || (socket.request && socket.request.socket && socket.request.socket.remoteAddress) || 'unknown';
    const clientInfo = {
        id: clientId,
        socket: socket,
        connectedAt: new Date(),
        lastActivity: new Date(),
        isHost: false,
        remote
    };
    
    console.log(`🔌 Client connected: ${clientId} from ${remote}`);
    
    // Designate a host if none exists
    if (!currentHostId) {
        clientInfo.isHost = true;
        currentHostId = clientId;
        console.log(`👑 Client ${clientId} designated as host`);
    }
    
    clients.set(clientId, clientInfo);
    broadcastClientList();
    
    // Send initial configuration
    socket.emit('config', {
        clientId,
        isHost: clientInfo.isHost,
        mode: useIndividualMode ? 'individual' : 'fused',
        hostCursorControl: config.enableHostCursorControl,
        maxClients: config.maxClients,
        hostId: currentHostId,
        physicsEnabled: usePhysics
    });
    
    // Send current mouse data
    socket.emit('mouseData', {
        mice: Array.from(mouseData.entries()).map(([id, data]) => ({
            id,
            position: mousePositions.get(id) || { x: 0, y: 0 },
            weight: mouseWeights.get(id) || 1.0,
            lastActivity: mouseActivity.get(id) || null,
            rotation: mouseRotations.get(id) || 0.0,
            isActive: id === activeMouseId
        })),
        hostPosition: hostCursorPosition,
        mode: useIndividualMode ? 'individual' : 'fused',
        activeMouse: activeMouseId,
        hostId: currentHostId
    });
    
    // Client requests to become host
    socket.on('requestHost', () => {
        const info = clients.get(clientId);
        if (!info) return;
        // Revoke previous host
        if (currentHostId && clients.has(currentHostId)) {
            clients.get(currentHostId).isHost = false;
        }
        info.isHost = true;
        currentHostId = clientId;
        console.log(`👑 New host selected: ${clientId}`);
        io.emit('hostChanged', { hostId: currentHostId });
        broadcastClientList();
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
        if (clientId === currentHostId) {
            useIndividualMode = !useIndividualMode;
            activeMouseId = useIndividualMode ? null : activeMouseId;
            console.log(`🔄 Mode switched to: ${useIndividualMode ? 'Individual' : 'Fused'}`);
            io.emit('modeChanged', {
                mode: useIndividualMode ? 'individual' : 'fused',
                activeMouse: activeMouseId
            });
        }
    });

    // Toggle 3-body physics (host only)
    socket.on('togglePhysics', () => {
        if (clientId === currentHostId) {
            usePhysics = !usePhysics;
            hostVelocity = { x: 0, y: 0 };
            console.log(`🪐 Physics ${usePhysics ? 'ENABLED' : 'DISABLED'}`);
            io.emit('physicsChanged', { physicsEnabled: usePhysics });
        }
    });
    
    // Handle host cursor control
    socket.on('hostCursorMove', (data) => {
        if (clientId === currentHostId && config.enableHostCursorControl && robot) {
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
        const { rotation } = data;
        const currentTime = new Date();
        clientInfo.lastActivity = currentTime;
        mouseRotations.set(clientId, rotation || 0);
        broadcastMouseUpdate();
    });
    
    // Handle mouse click events
    socket.on('mouseClick', (data) => {
        if (clientId === currentHostId && config.enableHostCursorControl && robot) {
            const { button, doubleClick } = data;
            try {
                robot.mouseClick(button, !!doubleClick);
                console.log(`🖱️  Host mouse ${button} ${doubleClick ? 'double ' : ''}click`);
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
        mouseRotations.delete(clientId);
        
        // Reassign host if needed
        if (currentHostId === clientId) {
            currentHostId = null;
            const next = Array.from(clients.values())[0];
            if (next) {
                next.isHost = true;
                currentHostId = next.id;
                console.log(`👑 New host: ${currentHostId}`);
                io.emit('hostChanged', { hostId: currentHostId });
            }
        }
        
        // If this was the active mouse, clear it
        if (activeMouseId === clientId) {
            activeMouseId = null;
        }
        
        broadcastClientList();
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
    // Toroidal wrap-around within 1920x1080 logical space
    const width = 1920;
    const height = 1080;
    const wrappedX = ((newX % width) + width) % width;
    const wrappedY = ((newY % height) + height) % height;
    mousePositions.set(clientId, { x: wrappedX, y: wrappedY });
}

// Handle individual mode
function handleIndividualMode(clientId) {
    activeMouseId = clientId;
    if (config.enableHostCursorControl && robot) {
        const position = mousePositions.get(clientId);
        if (position) {
            hostCursorPosition = position;
            try { robot.moveMouse(Math.round(position.x), Math.round(position.y)); } catch (e) {}
        }
    }
    // Clear deltas after processing
    const mouse = mouseData.get(clientId);
    if (mouse) {
        mouse.deltaX = 0; mouse.deltaY = 0;
    }
}

// Fuse mouse movements (similar to Swift triangulation)
function fuseAndMoveCursor() {
    if (mouseData.size === 0) return;
    let weightedTotalX = 0, weightedTotalY = 0, totalWeight = 0;
    for (const [cid, mouse] of mouseData.entries()) {
        const weight = mouseWeights.get(cid) || 1.0;
        weightedTotalX += mouse.deltaX * weight;
        weightedTotalY += mouse.deltaY * weight;
        totalWeight += weight;
    }
    if (totalWeight === 0) return;
    const avgX = weightedTotalX / totalWeight;
    const avgY = weightedTotalY / totalWeight;

    if (usePhysics) {
        // Simple damped integration (3-body inspired) without explicit dt
        const damping = 0.12;
        const gain = 1.0;
        // Update velocity with damping and force from average deltas
        hostVelocity.x = (1 - damping) * hostVelocity.x + gain * avgX;
        hostVelocity.y = (1 - damping) * hostVelocity.y + gain * avgY;
        // Cap speed
        const speed = Math.hypot(hostVelocity.x, hostVelocity.y);
        const maxSpeed = 50; // pixels per tick cap
        if (speed > maxSpeed) {
            hostVelocity.x *= maxSpeed / speed;
            hostVelocity.y *= maxSpeed / speed;
        }
        hostCursorPosition.x += hostVelocity.x;
        hostCursorPosition.y += hostVelocity.y;
    } else {
        const smoothing = config.smoothingFactor;
        hostCursorPosition.x = hostCursorPosition.x * (1 - smoothing) + (hostCursorPosition.x + avgX) * smoothing;
        hostCursorPosition.y = hostCursorPosition.y * (1 - smoothing) + (hostCursorPosition.y + avgY) * smoothing;
    }
    // Toroidal wrap-around for host cursor position
    const width = 1920;
    const height = 1080;
    hostCursorPosition.x = ((hostCursorPosition.x % width) + width) % width;
    hostCursorPosition.y = ((hostCursorPosition.y % height) + height) % height;
    if (config.enableHostCursorControl && robot) {
        try { robot.moveMouse(Math.round(hostCursorPosition.x), Math.round(hostCursorPosition.y)); } catch (e) {}
    }
    for (const mouse of mouseData.values()) { mouse.deltaX = 0; mouse.deltaY = 0; }
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
        activeMouse: activeMouseId,
        hostId: currentHostId
    });
}

// Start server
server.listen(config.port, '0.0.0.0', () => {
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
