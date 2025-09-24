# 3 Blind Mice - Web Version

A web-based multi-computer mouse triangulation system that allows multiple computers to control a single cursor through intelligent triangulation algorithms.

## 🎯 Features

- **Multi-Computer Support**: Connect multiple computers/devices to control one shared cursor
- **Real-time Coordination**: WebSocket-based real-time mouse movement synchronization
- **Dual Control Modes**: 
  - **Fused Mode**: All mouse movements are averaged together (triangulation)
  - **Individual Mode**: Each computer controls the cursor independently
- **Host Computer Control**: One computer acts as the host and controls the actual system cursor
- **Weighted Averaging**: Active computers have more influence on cursor movement
- **Activity Tracking**: Monitors computer usage patterns and adjusts weights accordingly
- **Responsive Web Interface**: Works on desktop, tablet, and mobile devices
- **Touch Support**: Full touch gesture support for mobile devices
- **Visual Feedback**: Real-time visualization of all connected mice and cursor positions

## 🚀 Quick Start

### Prerequisites

- Node.js 16+ and npm
- Modern web browser with WebSocket support
- For host computer cursor control: Install `robotjs` (see installation notes below)

### Installation

1. **Clone and navigate to the web directory**:
   ```bash
   cd web/
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start the server**:
   ```bash
   npm start
   ```

4. **Open in browser**:
   - Navigate to `http://localhost:3000`
   - Open the same URL on multiple computers/devices
   - One computer will be designated as the "host"

## 🖱️ How It Works

### Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Computer 1 │    │  Computer 2 │    │  Computer 3 │
│   (Client)  │    │   (Host)    │    │   (Client)  │
└──────┬──────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                  │
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
                    ┌─────▼─────┐
                    │ WebSocket │
                    │  Server   │
                    │  (Node.js)│
                    └─────┬─────┘
                          │
                    ┌─────▼─────┐
                    │ Host Cursor│
                    │  Control   │
                    │ (robotjs)  │
                    └───────────┘
```

### Triangulation Algorithm

The web version implements the same intelligent triangulation algorithm as the native versions:

1. **Weighted Averaging**: Each connected computer has a weight based on activity level
2. **Activity Tracking**: Computers that are actively moving their mouse receive higher weights
3. **Smoothing**: Movement is smoothed to prevent jitter and provide fluid motion
4. **Boundary Clamping**: Cursor movement is constrained to screen boundaries
5. **Mode Switching**: Toggle between individual and fused control modes

### Mouse Data Flow

```
Client Mouse Move → WebSocket → Server Processing → Triangulation → Host Cursor Move
```

## 🎮 Usage

### Basic Usage

1. **Start the server** on one computer (this becomes the host)
2. **Open the web page** on multiple computers/devices
3. **Move your mouse** in the tracking area to control the shared cursor
4. **Use keyboard shortcuts**:
   - `M` - Toggle between Individual and Fused modes (host only)
   - `C` - Clear all mouse data
   - `H` - Toggle instructions visibility

### Control Modes

#### Fused Mode (Default)
- All mouse movements are averaged together
- Provides smooth, collaborative cursor control
- Best for precision work and collaborative tasks

#### Individual Mode
- Each computer controls the cursor independently
- The most recently active computer takes control
- Best for switching between different users

### Host Computer Setup

The host computer is responsible for actually moving the system cursor. To enable this feature:

#### macOS
```bash
npm install robotjs
# Grant accessibility permissions when prompted
```

#### Windows
```bash
npm install robotjs
# Run as administrator for full cursor control
```

#### Linux
```bash
npm install robotjs
# Install X11 development libraries:
sudo apt-get install libx11-dev libxtst-dev libpng++-dev
```

**Note**: If `robotjs` is not installed, the server will still work but without host cursor control.

## 🔧 Configuration

### Server Configuration

Edit `server.js` to modify server settings:

```javascript
const config = {
    port: process.env.PORT || 3000,
    maxClients: 10,
    activityTimeout: 2000, // 2 seconds
    smoothingFactor: 0.7,
    enableHostCursorControl: !!robot
};
```

### Client Configuration

Modify `mouse-tracker.js` for client-side settings:

```javascript
this.config = {
    smoothing: 0.7,
    maxDelta: 50, // Maximum delta per frame
    trackingSensitivity: 1.0
};
```

## 🌐 API Endpoints

### REST API

- `GET /` - Serve the main web interface
- `GET /api/status` - Get server status and statistics
- `GET /api/mice` - Get current mouse data and positions

### WebSocket Events

#### Client to Server
- `mouseMove` - Send mouse movement data
- `mouseClick` - Send mouse click events
- `toggleMode` - Toggle control mode (host only)
- `hostCursorMove` - Move host cursor (host only)

#### Server to Client
- `config` - Initial configuration data
- `mouseData` - Initial mouse data
- `mouseUpdate` - Real-time mouse position updates
- `modeChanged` - Mode change notifications
- `promotedToHost` - Host promotion notification

## 📱 Mobile Support

The web version includes full mobile device support:

- **Touch Tracking**: Use your finger to control the mouse cursor
- **Responsive Design**: Adapts to different screen sizes
- **Touch Gestures**: Support for touch-based mouse clicks
- **Mobile Optimized**: Optimized interface for mobile devices

## 🔒 Security Considerations

### Current Security Features

- **Input Validation**: All mouse data is validated before processing
- **Rate Limiting**: Built-in protection against excessive mouse events
- **Connection Limits**: Maximum number of connected clients
- **Data Sanitization**: Mouse coordinates are clamped to valid ranges

### Recommended Security Enhancements

For production use, consider adding:

- **Authentication**: User login and session management
- **HTTPS**: SSL/TLS encryption for all communications
- **CORS Configuration**: Restrict cross-origin requests
- **Rate Limiting**: Prevent abuse with request rate limiting
- **Input Validation**: Enhanced validation and sanitization

## 🐛 Troubleshooting

### Common Issues

#### Connection Problems
- Ensure the server is running on the correct port
- Check firewall settings for port 3000
- Verify WebSocket support in your browser

#### Host Cursor Control Not Working
- Install `robotjs` on the host computer
- Grant necessary permissions (accessibility on macOS)
- Run as administrator on Windows

#### Mobile Device Issues
- Ensure touch events are enabled
- Check browser compatibility
- Try refreshing the page

### Debug Mode

Enable debug logging by opening browser developer tools and checking the console for detailed logs.

## 🚀 Deployment

### Local Network
```bash
# Start server
npm start

# Access from other devices on the same network
# Replace localhost with your computer's IP address
http://192.168.1.100:3000
```

### Production Deployment

For production deployment, consider:

1. **Use a reverse proxy** (nginx, Apache)
2. **Enable HTTPS** with SSL certificates
3. **Set up process management** (PM2, systemd)
4. **Configure firewall** rules
5. **Add monitoring** and logging

Example with PM2:
```bash
npm install -g pm2
pm2 start server.js --name "3blindmice-web"
pm2 startup
pm2 save
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly across different devices
5. Submit a pull request

## 📄 License

This project is licensed under the BSD License - see the main project LICENSE file for details.

## 🔗 Related Projects

- [3 Blind Mice - macOS Version](../macos/)
- [3 Blind Mice - Windows Version](../windows/)
- [3 Blind Mice - Linux Version](../linux/)
- [3 Blind Mice - ChromeOS Version](../chromeos/)

---

**3 Blind Mice Web** - Multi-computer mouse control for the modern web! 🐭🌐

# 3 Blind Mice - Web (Cloudflare Pages Deployment)

## Deploy the Static UI to Cloudflare Pages

You will still need a running Socket.IO server (server.js), locally or hosted (e.g., with Cloudflare Tunnel, Render, Fly.io, etc.).

### Option A: Dashboard Upload
1. In Cloudflare Dashboard → Pages → Create a project
2. Choose "Upload Assets" and upload the folder: `web/public`
3. Deploy and (optionally) add a custom domain in Pages → Custom domains

### Option B: Wrangler CLI
```bash
npm i -g wrangler
wrangler pages project create threeblindmice-web
wrangler pages deploy /Users/alexanderfox/Projects/3BlindMice/web/public --project-name threeblindmice-web
```
Then add a custom domain in the Pages UI.

## Point the UI to Your Socket.IO Server
The UI reads the Socket.IO endpoint from `web/public/config.js` at runtime.

Priority (highest to lowest):
1. URL param: `?socketServer=https://your-socket-server.example.com`
2. `localStorage.setItem('SOCKET_IO_URL', 'https://your-socket-server.example.com')`
3. Hardcoded value in `config.js`
4. Fallback to `window.location.origin`

Example (temporary, via URL param):
```
https://threeblindmice-web.pages.dev/?socketServer=https://your-socket-server.example.com
```

## Host the Socket.IO Server
If you run the Node server locally:
- Use Cloudflare Tunnel:
```bash
cloudflared tunnel create threeblindmice-web
# set ingress to http://localhost:3000 in ~/.cloudflared/config.yml
cloudflared tunnel run threeblindmice-web
```

If you deploy the Node server elsewhere, ensure:
- HTTPS is enabled
- WebSockets (WSS) are allowed
- CORS is allowed for your Pages domain (current server uses CORS "*")

## Notes
- Pages serves the static UI globally.
- The app uses Socket.IO over WebSockets.
- No rebuild needed to change the server endpoint (use config.js or URL param).

## Socket.IO Server Setup

### Local (development)
```bash
cd web
npm install
npm start   # runs on http://localhost:3000
```

### Docker (production)
```bash
cd web
docker build -t threeblindmice-socket-server .
docker run -p 3000:3000 --name tbm-socket threeblindmice-socket-server
```

### Cloudflare Tunnel (expose your local server securely)
```bash
# Install cloudflared (macOS: brew install cloudflare/cloudflare/cloudflared)
cloudflared login
cloudflared tunnel create threeblindmice-web

# Create ~/.cloudflared/config.yml
# ---
# tunnel: threeblindmice-web
# credentials-file: /Users/youruser/.cloudflared/<tunnel-id>.json
# ingress:
#   - hostname: app.yourdomain.com
#     service: http://localhost:3000
#   - service: http_status:404

cloudflared tunnel run threeblindmice-web
```
Now point your Pages UI to `https://app.yourdomain.com` using `?socketServer=` param or `localStorage`.
