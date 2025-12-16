# Chapter 7: JavaScript Node Programs

[← Back to Part 3: JavaScript Development](README.md) | [↑ Main](../README.md)

---

## Overview

BrightSign players support the Node.js runtime environment, which runs on the same V8 JavaScript engine used by Chromium. The Node.js and Chromium instances share a single JavaScript execution context, allowing JavaScript applications to access both Node.js modules and DOM objects simultaneously. BrightSign firmware pushes Node.js events to the Chromium event loop, ensuring that JavaScript applications receive Node.js and DOM events seamlessly.

The BrightSign Node.js implementation is based on the NW.js and Electron projects and shares many characteristics with them. Unlike Electron, which uses a JavaScript file as the entry point, BrightSign uses an HTML file as the entry point. On a BrightSign player, BrightScript creates a Node.js-enabled `roHtmlWidget` instance; the initial URL passed when `roHtmlWidget` is initialized acts as the entry point for Node.js applications.

## Node.js Runtime

### BrightSign Node.js Implementation

BrightSign provides two Node.js versions:
- **Embedded Node.js**: Integrated into Chromium, associated with `roHtmlWidget`
- **Standalone Node.js**: Used by `roNodeJs` and similar objects

**Version Support by OS:**

| BrightSignOS Version | Chromium Version | Embedded Node.js | Standalone Node.js |
|---------------------|------------------|------------------|-------------------|
| OS 8.0.x | Chromium 65 | 10.0.0 | 8.9.4 |
| OS 8.1.x - 8.3.x | Chromium 69 | 10.11.0 | 10.15.3 |
| OS 8.5.x, OS 9.0.x | Chromium 87 | **14.17.6** | **14.17.6** |

The integrated Node.js implementation in current OS versions is based on Node v14.17.6. For complete documentation, consult the [Node.js 14.x API documentation](https://nodejs.org/dist/v14.17.6/docs/api/).

### Enabling Node.js

Node.js is enabled for individual `roHtmlWidget` instances by including the `nodejs_enabled:true` entry in the configuration:

```brightscript
r = CreateObject("roRectangle", 0, 0, 1920, 1080)
config = {
    nodejs_enabled: true
    inspector_server: { port: 3000 }
    brightsign_js_objects_enabled: true
    url: "file:///sd:/app.html"
}
h = CreateObject("roHtmlWidget", r, config)
h.Show()
```

**Important:** Do not load arbitrary websites with Node.js enabled. Some JavaScript libraries assume server-side capabilities and will attempt to load dependencies, causing playback to fail.

### Supported Modules

BrightSign supports JavaScript-only Node.js modules. Built-in modules include:
- `http`, `https` - HTTP server and client
- `fs` - File system operations
- `os` - Operating system utilities
- `path` - Path operations
- `process` - Process information and control
- `net` - TCP/UDP networking
- `events` - Event emitter
- `stream` - Streaming interfaces
- `util` - Utility functions

### Limitations

**Binary Module Restriction:** The BrightSign Node.js implementation is limited to JavaScript code only. Modules containing binary components compiled for other platforms (usually Intel x64) will not run on BrightSign players. This affects modules like:
- `sqlite3` - Native SQLite bindings
- `node-sass` - Native SASS compiler
- `bcrypt` - Native cryptography

**Workarounds:**
- Use pure JavaScript alternatives (e.g., `sql.js` instead of `sqlite3`)
- Use BrightScript native objects (e.g., `roSqliteDatabase` for SQLite)
- Bundle with webpack to reduce dependencies

### Security and Permissions

BrightSign does not use sandboxing. Instead, it launches the render process with a Node.js user and storage group, which has:
- Write permissions for local storage
- Read permissions for the entire file system
- Access to networking interfaces
- Ability to use privileged ports

**Cross-Domain Security:**
By default, Chromium prevents cross-site scripting. If the URL for `roHtmlWidget` is a remote domain, JavaScript cannot make HTTP requests to other domains. To allow cross-domain requests:

```brightscript
config = {
    nodejs_enabled: true
    url: "http://www.example.com"
    security_params: { websecurity: false }
}
```

## File System Operations

### Device Storage Paths

BrightSign devices have specific storage paths:

```javascript
// microSD card
const SD_PATH = "/storage/sd/";

// SSD storage
const SSD_PATH = "/storage/ssd/";

// USB storage
const USB_PATH = "/storage/usb1/";
```

### Setting Working Directory

Recommended approach using `process.chdir()`:

```javascript
var process = require("process");
process.chdir("/storage/sd");

// Now relative paths work from /storage/sd
var fs = require("fs");
fs.readFileSync("config.json"); // Reads /storage/sd/config.json
```

### Multiple Storage Paths

To access modules from multiple storage locations:

```javascript
module.paths.push("/storage/sd/");
module.paths.push("/storage/ssd/");
module.paths.push("/storage/usb1/");
```

### Reading Files

```javascript
const fs = require("fs");

// Synchronous read
const data = fs.readFileSync("/storage/sd/data.txt", "utf8");
console.log(data);

// Asynchronous read
fs.readFile("/storage/sd/data.txt", "utf8", (err, data) => {
    if (err) {
        console.error("Error reading file:", err);
        return;
    }
    console.log(data);
});

// Promise-based read (Node.js 14+)
const fsPromises = require("fs").promises;
fsPromises.readFile("/storage/sd/data.txt", "utf8")
    .then(data => console.log(data))
    .catch(err => console.error(err));
```

### Writing Files

```javascript
const fs = require("fs");

// Synchronous write
fs.writeFileSync("/storage/sd/output.txt", "Hello BrightSign");

// Asynchronous write
fs.writeFile("/storage/sd/output.txt", "Hello BrightSign", (err) => {
    if (err) {
        console.error("Error writing file:", err);
        return;
    }
    console.log("File written successfully");
});

// Append to file
fs.appendFileSync("/storage/sd/log.txt", "Log entry\n");
```

### Directory Management

```javascript
const fs = require("fs");

// Create directory
if (!fs.existsSync("/storage/sd/data")) {
    fs.mkdirSync("/storage/sd/data");
}

// Read directory contents
const files = fs.readdirSync("/storage/sd/");
files.forEach(file => {
    console.log(file);
});

// Get file stats
const stats = fs.statSync("/storage/sd/data.txt");
console.log("File size:", stats.size);
console.log("Is directory:", stats.isDirectory());
console.log("Modified:", stats.mtime);
```

### File Watching

```javascript
const fs = require("fs");

// Watch for file changes
const watcher = fs.watch("/storage/sd/config.json", (eventType, filename) => {
    console.log(`Event: ${eventType}, File: ${filename}`);

    if (eventType === "change") {
        // Reload configuration
        const config = JSON.parse(fs.readFileSync("/storage/sd/config.json", "utf8"));
        console.log("Config reloaded:", config);
    }
});

// Stop watching
// watcher.close();
```

### Large File Downloads

For large file downloads (>100MB), use the Fetch API instead of XMLHttpRequest to avoid memory issues:

```javascript
async function downloadLargeFile(url, destination) {
    const fs = require("fs");
    const response = await fetch(url);
    const fileStream = fs.createWriteStream(destination);

    const reader = response.body.getReader();

    while (true) {
        const { done, value } = await reader.read();

        if (done) {
            fileStream.end();
            console.log("Download complete");
            break;
        }

        fileStream.write(Buffer.from(value));
    }
}

// Usage
downloadLargeFile("http://example.com/large-video.mp4", "/storage/sd/video.mp4");
```

## Network Programming

### HTTP Server

Create a basic HTTP server:

```javascript
const http = require("http");
const os = require("os");

function startServer() {
    const server = http.createServer((request, response) => {
        response.writeHead(200, { "Content-Type": "text/plain" });
        response.end("Hello from BrightSign\n");
    });

    server.listen(8000);

    // Get server IP address
    const interfaces = os.networkInterfaces();
    const addresses = [];
    for (let k in interfaces) {
        for (let k2 in interfaces[k]) {
            const address = interfaces[k][k2];
            if (address.family === "IPv4" && !address.internal) {
                addresses.push(address.address);
            }
        }
    }

    console.log(`Server running at http://${addresses[0]}:8000`);
}

startServer();
```

### Serving Static Files

```javascript
const http = require("http");
const fs = require("fs");
const path = require("path");

const server = http.createServer((req, res) => {
    const filePath = path.join("/storage/sd/www", req.url);

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end("File not found");
            return;
        }

        // Determine content type
        const ext = path.extname(filePath);
        const contentTypes = {
            ".html": "text/html",
            ".js": "text/javascript",
            ".css": "text/css",
            ".json": "application/json",
            ".png": "image/png",
            ".jpg": "image/jpeg"
        };

        res.writeHead(200, { "Content-Type": contentTypes[ext] || "text/plain" });
        res.end(data);
    });
});

server.listen(8080);
```

### WebSocket Connections

Using the `ws` module (JavaScript-only):

```javascript
const WebSocket = require("ws");

const wss = new WebSocket.Server({ port: 8080 });

wss.on("connection", (ws) => {
    console.log("Client connected");

    ws.on("message", (message) => {
        console.log("Received:", message);

        // Echo back to client
        ws.send(`Echo: ${message}`);
    });

    ws.on("close", () => {
        console.log("Client disconnected");
    });

    // Send periodic updates
    const interval = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
                timestamp: Date.now(),
                status: "active"
            }));
        }
    }, 5000);

    ws.on("close", () => clearInterval(interval));
});
```

### TCP/UDP Sockets

**TCP Server:**

```javascript
const net = require("net");

const server = net.createServer((socket) => {
    console.log("Client connected");

    socket.on("data", (data) => {
        console.log("Received:", data.toString());
        socket.write("ACK\n");
    });

    socket.on("end", () => {
        console.log("Client disconnected");
    });
});

server.listen(3000, () => {
    console.log("TCP server listening on port 3000");
});
```

**UDP Server:**

```javascript
const dgram = require("dgram");

const server = dgram.createSocket("udp4");

server.on("message", (msg, rinfo) => {
    console.log(`Received ${msg} from ${rinfo.address}:${rinfo.port}`);

    // Send response
    server.send("ACK", rinfo.port, rinfo.address);
});

server.on("listening", () => {
    const address = server.address();
    console.log(`UDP server listening ${address.address}:${address.port}`);
});

server.bind(41234);
```

## System Integration

### OS Interaction

```javascript
const os = require("os");

// System information
console.log("Platform:", os.platform());
console.log("CPU Architecture:", os.arch());
console.log("Total Memory:", os.totalmem());
console.log("Free Memory:", os.freemem());
console.log("Uptime:", os.uptime());

// Network interfaces
const interfaces = os.networkInterfaces();
console.log("Network interfaces:", JSON.stringify(interfaces, null, 2));
```

### Process Management

Using `roNodeJs` for standalone Node.js processes:

```brightscript
' BrightScript code
msgPort = CreateObject("roMessagePort")
node = CreateObject("roNodeJs", "app.js", {
    message_port: msgPort,
    arguments: ["arg1", "arg2"],
    node_arguments: ["--inspect=0.0.0.0:2999"]
})
```

```javascript
// app.js - Access command line arguments
console.log("Arguments:", process.argv);

// Environment variables
console.log("NODE_ENV:", process.env.NODE_ENV);

// Change directory
process.chdir(__dirname);

// Exit handling
process.on("SIGINT", () => {
    console.log("Shutting down...");
    process.exit(0);
});

// Keep process alive
setInterval(() => {
    console.log("Process alive");
}, 10000);
```

### System Calls via BrightSign APIs

```javascript
const DeviceInfoClass = require("@brightsign/deviceinfo");
const SystemClass = require("@brightsign/system");

const deviceInfo = new DeviceInfoClass();
const system = new SystemClass();

console.log("Model:", deviceInfo.model);
console.log("Serial:", deviceInfo.deviceUniqueId);
console.log("Boot version:", deviceInfo.bootVersion);

// Reboot device
// system.reboot();
```

## Hardware Access

### GPIO Control

```javascript
const ControlPortClass = require("@brightsign/legacy/controlport");

// Access onboard GPIO
const gpio = new ControlPortClass("BrightSign");

// Configure pin as output
gpio.ConfigureAsOutput(0);
gpio.SetPinValue(0, 1); // Set high

// Configure pin as input
gpio.ConfigureAsInput(1);
const value = gpio.GetPinValue(1);
console.log("Pin 1 value:", value);

// Listen for button events
gpio.addEventListener("controldown", (event) => {
    console.log("Button pressed:", event.button);
});

gpio.addEventListener("controlup", (event) => {
    console.log("Button released:", event.button);
});
```

### Serial Communication

Using the `@brightsign/serialport` binding:

```javascript
const SerialPort = require("@serialport/stream");
const BrightSignBinding = require("@brightsign/serialport");
SerialPort.Binding = BrightSignBinding;

const port = new SerialPort("/dev/ttyUSB0", {
    baudRate: 9600,
    dataBits: 8,
    parity: "none",
    stopBits: 1
});

port.on("open", () => {
    console.log("Serial port opened");
    port.write("Hello Serial\n");
});

port.on("data", (data) => {
    console.log("Received:", data.toString());
});

port.on("error", (err) => {
    console.error("Serial port error:", err);
});
```

### I2C/SPI Interfaces

Access via BrightScript `roControlPort` or native system calls. Example using BrightScript interop:

```javascript
// Use messageport to communicate with BrightScript for I2C/SPI
const MessagePort = require("@brightsign/messageport");
const bsMessage = new MessagePort();

// Send command to BrightScript to access I2C
bsMessage.PostBSMessage({
    action: "i2c_read",
    address: 0x48,
    register: 0x00
});

// Receive response from BrightScript
bsMessage.addEventListener("bsmessage", (msg) => {
    console.log("I2C data:", msg.data);
});
```

## Database Integration

### SQLite via BrightScript

Since native `sqlite3` module is not supported, use BrightScript `roSqliteDatabase`:

**BrightScript side:**

```brightscript
db = CreateObject("roSqliteDatabase", "sd:/app.db")
db.RunQuery("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)")

' Expose database operations via message port
```

**JavaScript side - communicate via messageport:**

```javascript
const MessagePort = require("@brightsign/messageport");
const bsMessage = new MessagePort();

// Insert data
bsMessage.PostBSMessage({
    action: "db_insert",
    table: "users",
    data: { name: "John Doe" }
});

// Query data
bsMessage.PostBSMessage({
    action: "db_query",
    sql: "SELECT * FROM users"
});

bsMessage.addEventListener("bsmessage", (msg) => {
    if (msg.action === "db_result") {
        console.log("Query results:", msg.data);
    }
});
```

### File-Based Databases

Use pure JavaScript solutions like `lowdb`:

```javascript
const low = require("lowdb");
const FileSync = require("lowdb/adapters/FileSync");

const adapter = new FileSync("/storage/sd/db.json");
const db = low(adapter);

// Set defaults
db.defaults({ users: [], posts: [] }).write();

// Add user
db.get("users")
    .push({ id: 1, name: "John Doe" })
    .write();

// Query
const user = db.get("users")
    .find({ id: 1 })
    .value();

console.log(user);
```

### Data Persistence

```javascript
const fs = require("fs");

class DataStore {
    constructor(filePath) {
        this.filePath = filePath;
        this.data = this.load();
    }

    load() {
        try {
            const data = fs.readFileSync(this.filePath, "utf8");
            return JSON.parse(data);
        } catch (err) {
            return {};
        }
    }

    save() {
        fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2));
    }

    get(key) {
        return this.data[key];
    }

    set(key, value) {
        this.data[key] = value;
        this.save();
    }
}

// Usage
const store = new DataStore("/storage/sd/appdata.json");
store.set("lastUpdate", Date.now());
console.log("Last update:", store.get("lastUpdate"));
```

## API Development

### RESTful Services

```javascript
const http = require("http");
const url = require("url");

class Router {
    constructor() {
        this.routes = { GET: {}, POST: {}, PUT: {}, DELETE: {} };
    }

    get(path, handler) {
        this.routes.GET[path] = handler;
    }

    post(path, handler) {
        this.routes.POST[path] = handler;
    }

    handle(req, res) {
        const parsedUrl = url.parse(req.url, true);
        const handler = this.routes[req.method]?.[parsedUrl.pathname];

        if (handler) {
            handler(req, res, parsedUrl.query);
        } else {
            res.writeHead(404);
            res.end(JSON.stringify({ error: "Not found" }));
        }
    }
}

// Create API
const router = new Router();

router.get("/api/status", (req, res) => {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "online", timestamp: Date.now() }));
});

router.get("/api/device", (req, res) => {
    const DeviceInfoClass = require("@brightsign/deviceinfo");
    const deviceInfo = new DeviceInfoClass();

    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({
        model: deviceInfo.model,
        serial: deviceInfo.deviceUniqueId
    }));
});

const server = http.createServer((req, res) => router.handle(req, res));
server.listen(3000);
```

### Middleware

```javascript
function logger(req, res, next) {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
}

function cors(req, res, next) {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
    next();
}

function authenticate(req, res, next) {
    const auth = req.headers.authorization;

    if (!auth || auth !== "Bearer SECRET_TOKEN") {
        res.writeHead(401, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Unauthorized" }));
        return;
    }

    next();
}

// Apply middleware
const middleware = [logger, cors, authenticate];

const server = http.createServer((req, res) => {
    let index = 0;

    function next() {
        if (index < middleware.length) {
            middleware[index++](req, res, next);
        } else {
            router.handle(req, res);
        }
    }

    next();
});
```

### Authentication

```javascript
const crypto = require("crypto");

class AuthManager {
    constructor() {
        this.sessions = new Map();
    }

    generateToken() {
        return crypto.randomBytes(32).toString("hex");
    }

    createSession(userId) {
        const token = this.generateToken();
        this.sessions.set(token, {
            userId,
            createdAt: Date.now()
        });
        return token;
    }

    validateToken(token) {
        return this.sessions.has(token);
    }

    getSession(token) {
        return this.sessions.get(token);
    }

    destroySession(token) {
        this.sessions.delete(token);
    }
}

// Usage
const auth = new AuthManager();

router.post("/api/login", (req, res) => {
    let body = "";

    req.on("data", chunk => body += chunk);
    req.on("end", () => {
        const { username, password } = JSON.parse(body);

        // Validate credentials (simplified)
        if (username === "admin" && password === "password") {
            const token = auth.createSession(username);
            res.writeHead(200, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ token }));
        } else {
            res.writeHead(401, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ error: "Invalid credentials" }));
        }
    });
});
```

### Routing

```javascript
class Router {
    constructor() {
        this.routes = [];
    }

    addRoute(method, pattern, handler) {
        this.routes.push({ method, pattern: new RegExp(pattern), handler });
    }

    get(pattern, handler) {
        this.addRoute("GET", pattern, handler);
    }

    post(pattern, handler) {
        this.addRoute("POST", pattern, handler);
    }

    match(method, path) {
        for (const route of this.routes) {
            if (route.method === method) {
                const match = path.match(route.pattern);
                if (match) {
                    return { handler: route.handler, params: match.groups || {} };
                }
            }
        }
        return null;
    }
}

// Usage with parameters
const router = new Router();

router.get("^/api/users/(?<id>\\d+)$", (req, res, params) => {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ userId: params.id }));
});
```

## Real-time Communication

### WebSockets

```javascript
const WebSocket = require("ws");

const wss = new WebSocket.Server({ port: 8080 });

// Broadcast to all clients
function broadcast(data) {
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

wss.on("connection", (ws) => {
    console.log("Client connected");

    ws.on("message", (message) => {
        const data = JSON.parse(message);

        // Handle different message types
        switch (data.type) {
            case "subscribe":
                ws.channel = data.channel;
                break;
            case "message":
                broadcast({
                    type: "message",
                    channel: ws.channel,
                    data: data.payload
                });
                break;
        }
    });

    // Send heartbeat
    const heartbeat = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: "ping" }));
        }
    }, 30000);

    ws.on("close", () => {
        clearInterval(heartbeat);
        console.log("Client disconnected");
    });
});
```

### Server-Sent Events

```javascript
const http = require("http");

const server = http.createServer((req, res) => {
    if (req.url === "/events") {
        res.writeHead(200, {
            "Content-Type": "text/event-stream",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        });

        // Send event every 5 seconds
        const interval = setInterval(() => {
            res.write(`data: ${JSON.stringify({
                timestamp: Date.now(),
                status: "active"
            })}\n\n`);
        }, 5000);

        req.on("close", () => {
            clearInterval(interval);
        });
    }
});

server.listen(3000);
```

### Real-time Data Streaming

```javascript
// BrightSign device status monitor
const DeviceInfoClass = require("@brightsign/deviceinfo");
const NetworkConfigClass = require("@brightsign/networkconfiguration");

class DeviceMonitor {
    constructor(ws) {
        this.ws = ws;
        this.deviceInfo = new DeviceInfoClass();
        this.interval = null;
    }

    start() {
        this.interval = setInterval(() => {
            this.sendStatus();
        }, 1000);
    }

    stop() {
        if (this.interval) {
            clearInterval(this.interval);
        }
    }

    sendStatus() {
        const status = {
            timestamp: Date.now(),
            model: this.deviceInfo.model,
            temperature: this.deviceInfo.temperature,
            uptime: process.uptime()
        };

        this.ws.send(JSON.stringify(status));
    }
}

// Usage with WebSocket
wss.on("connection", (ws) => {
    const monitor = new DeviceMonitor(ws);
    monitor.start();

    ws.on("close", () => {
        monitor.stop();
    });
});
```

## Package Management

### NPM Modules

**Installation workflow:**

1. Develop on your computer
2. Run `npm install` to create `node_modules` directory
3. Copy `node_modules` to BrightSign SD card along with application files
4. BrightSign loads modules from `node_modules` relative to HTML file

**Example package.json:**

```json
{
  "name": "brightsign-app",
  "version": "1.0.0",
  "description": "BrightSign Node.js Application",
  "main": "index.js",
  "dependencies": {
    "moment": "^2.29.4",
    "lowdb": "^1.0.0",
    "ws": "^8.13.0"
  }
}
```

### Dependency Management

**Best practices:**

```javascript
// Check for module availability
function requireSafe(moduleName) {
    try {
        return require(moduleName);
    } catch (err) {
        console.error(`Module ${moduleName} not found:`, err);
        return null;
    }
}

const moment = requireSafe("moment");
if (moment) {
    console.log("Current time:", moment().format());
}
```

**Version pinning:**

```json
{
  "dependencies": {
    "moment": "2.29.4",
    "lowdb": "1.0.0"
  }
}
```

### Bundling with Webpack

**webpack.config.js:**

```javascript
const path = require("path");

module.exports = {
    target: "node",
    entry: "./index.js",
    output: {
        path: path.resolve(__dirname, "dist"),
        filename: "bundle.js"
    },
    mode: "production",
    node: {
        __dirname: false,
        __filename: false
    }
};
```

**Build process:**

```bash
npm install -D webpack webpack-cli
npx webpack --mode production
```

**HTML entry point:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>BrightSign App</title>
</head>
<body>
    <script src="./bundle.js"></script>
    <script>
        window.addEventListener("load", () => {
            if (typeof window.main === "function") {
                window.main();
            }
        });
    </script>
</body>
</html>
```

**index.js with window attachment:**

```javascript
const moment = require("moment");
const DataStore = require("./datastore");

function main() {
    console.log("App started:", moment().format());
    const store = new DataStore("/storage/sd/data.json");
    // Application logic
}

// Attach to window for HTML to access
window.main = main;
```

## Performance & Memory

### Event Loop Optimization

```javascript
// Bad: Blocking operation
function processLargeArray(arr) {
    for (let i = 0; i < arr.length; i++) {
        heavyOperation(arr[i]);
    }
}

// Good: Non-blocking with setImmediate
function processLargeArrayAsync(arr, callback) {
    let index = 0;

    function processNext() {
        if (index >= arr.length) {
            callback();
            return;
        }

        heavyOperation(arr[index]);
        index++;

        setImmediate(processNext);
    }

    processNext();
}
```

### Memory Management

```javascript
// Monitor memory usage
function logMemory() {
    const used = process.memoryUsage();
    console.log("Memory usage:");
    console.log(`  RSS: ${Math.round(used.rss / 1024 / 1024)}MB`);
    console.log(`  Heap Total: ${Math.round(used.heapTotal / 1024 / 1024)}MB`);
    console.log(`  Heap Used: ${Math.round(used.heapUsed / 1024 / 1024)}MB`);
    console.log(`  External: ${Math.round(used.external / 1024 / 1024)}MB`);
}

setInterval(logMemory, 60000); // Log every minute
```

**Memory cleanup:**

```javascript
// Large buffer operations
function processLargeFile(filePath) {
    const fs = require("fs");
    const stream = fs.createReadStream(filePath, { highWaterMark: 64 * 1024 });

    stream.on("data", (chunk) => {
        // Process chunk
        processChunk(chunk);

        // chunk is automatically garbage collected after this
    });

    stream.on("end", () => {
        console.log("Processing complete");

        // Force garbage collection if exposed (not available by default)
        if (global.gc) {
            global.gc();
        }
    });
}
```

### Profiling

**Enable Node.js inspector:**

```brightscript
config = {
    nodejs_enabled: true
    inspector_server: { port: 2999 }
    node_arguments: ["--inspect=0.0.0.0:2999"]
}
```

**Performance timing:**

```javascript
class PerformanceMonitor {
    constructor() {
        this.marks = new Map();
    }

    mark(name) {
        this.marks.set(name, process.hrtime.bigint());
    }

    measure(startMark, endMark) {
        const start = this.marks.get(startMark);
        const end = this.marks.get(endMark);

        if (!start || !end) {
            console.error("Invalid marks");
            return;
        }

        const duration = Number(end - start) / 1e6; // Convert to milliseconds
        console.log(`${startMark} -> ${endMark}: ${duration.toFixed(2)}ms`);
        return duration;
    }
}

// Usage
const perf = new PerformanceMonitor();

perf.mark("start");
processData();
perf.mark("end");

perf.measure("start", "end");
```

**CPU profiling:**

```javascript
// Manual CPU sampling
class CPUProfiler {
    constructor(sampleRate = 100) {
        this.sampleRate = sampleRate;
        this.samples = [];
        this.interval = null;
    }

    start() {
        this.interval = setInterval(() => {
            const cpuUsage = process.cpuUsage();
            this.samples.push({
                timestamp: Date.now(),
                user: cpuUsage.user,
                system: cpuUsage.system
            });
        }, this.sampleRate);
    }

    stop() {
        clearInterval(this.interval);
        return this.samples;
    }
}
```

## Communication Between BrightScript and Node.js

### Using MessagePort

**JavaScript sending to BrightScript:**

```javascript
const MessagePort = require("@brightsign/messageport");
const bsMessage = new MessagePort();

// Send message to BrightScript
bsMessage.PostBSMessage({
    action: "play_video",
    url: "http://example.com/video.mp4"
});
```

**BrightScript receiving:**

```brightscript
while true
    ev = msgPort.WaitMessage(0)
    if type(ev) = "roNodeJsEvent" then
        data = ev.GetData()
        if data.reason = "message" then
            msg = data.message
            if msg.action = "play_video" then
                videoPlayer.PlayFile(msg.url)
            endif
        endif
    endif
end while
```

**BrightScript sending to JavaScript:**

```brightscript
nodejs.PostJSMessage({
    event: "playback_complete",
    timestamp: CreateObject("roDateTime").ToISOString()
})
```

**JavaScript receiving:**

```javascript
const MessagePort = require("@brightsign/messageport");
const bsMessage = new MessagePort();

bsMessage.addEventListener("bsmessage", (msg) => {
    console.log("Received from BrightScript:", msg);

    if (msg.event === "playback_complete") {
        console.log("Video finished at:", msg.timestamp);
    }
});
```

## Debugging Node.js Applications

### Remote Inspector

Enable the Chromium remote inspector to debug Node.js modules:

```brightscript
config = {
    nodejs_enabled: true
    inspector_server: { port: 3000 }
}
```

Access debugger at: `http://<player-ip>:3000`

### Console Logging

```javascript
// Console output goes to both stderr and remote inspector
console.log("Info message");
console.warn("Warning message");
console.error("Error message");
console.dir({ nested: { object: true } });

// Structured logging
function log(level, message, data = {}) {
    const entry = {
        timestamp: new Date().toISOString(),
        level,
        message,
        ...data
    };
    console.log(JSON.stringify(entry));
}

log("INFO", "Application started", { version: "1.0.0" });
log("ERROR", "Failed to load config", { error: "File not found" });
```

### Error Handling

```javascript
// Global error handlers
process.on("uncaughtException", (err) => {
    console.error("Uncaught exception:", err);
    // Log to file
    const fs = require("fs");
    fs.appendFileSync("/storage/sd/errors.log",
        `${new Date().toISOString()} - ${err.stack}\n`);
});

process.on("unhandledRejection", (reason, promise) => {
    console.error("Unhandled rejection:", reason);
});

// Try-catch for synchronous code
try {
    const data = JSON.parse(invalidJSON);
} catch (err) {
    console.error("Parse error:", err.message);
}

// Promise error handling
asyncOperation()
    .then(result => console.log(result))
    .catch(err => console.error("Async error:", err));

// Async/await error handling
async function safeOperation() {
    try {
        const result = await riskyOperation();
        return result;
    } catch (err) {
        console.error("Operation failed:", err);
        return null;
    }
}
```

## Complete Example: Data Logger Application

```javascript
// datalogger.js - Complete BrightSign Node.js application
const http = require("http");
const fs = require("fs");
const MessagePort = require("@brightsign/messageport");
const DeviceInfoClass = require("@brightsign/deviceinfo");

class DataLogger {
    constructor() {
        this.deviceInfo = new DeviceInfoClass();
        this.logFile = "/storage/sd/logs.json";
        this.port = 8080;
        this.messagePort = new MessagePort();
        this.logs = this.loadLogs();

        this.setupMessagePort();
        this.startHttpServer();
        this.startPeriodicLogging();
    }

    loadLogs() {
        try {
            const data = fs.readFileSync(this.logFile, "utf8");
            return JSON.parse(data);
        } catch (err) {
            return [];
        }
    }

    saveLogs() {
        fs.writeFileSync(this.logFile, JSON.stringify(this.logs, null, 2));
    }

    addLog(type, data) {
        const entry = {
            timestamp: new Date().toISOString(),
            type,
            device: this.deviceInfo.model,
            serial: this.deviceInfo.deviceUniqueId,
            data
        };

        this.logs.push(entry);
        this.saveLogs();

        console.log("Log added:", entry);
        return entry;
    }

    setupMessagePort() {
        this.messagePort.addEventListener("bsmessage", (msg) => {
            console.log("Message from BrightScript:", msg);
            this.addLog("brightscript", msg);
        });
    }

    startHttpServer() {
        const server = http.createServer((req, res) => {
            if (req.url === "/api/logs") {
                res.writeHead(200, { "Content-Type": "application/json" });
                res.end(JSON.stringify(this.logs));
            } else if (req.url === "/api/status") {
                res.writeHead(200, { "Content-Type": "application/json" });
                res.end(JSON.stringify({
                    status: "online",
                    model: this.deviceInfo.model,
                    uptime: process.uptime(),
                    logCount: this.logs.length
                }));
            } else {
                res.writeHead(404);
                res.end("Not found");
            }
        });

        server.listen(this.port, () => {
            console.log(`HTTP server listening on port ${this.port}`);
        });
    }

    startPeriodicLogging() {
        setInterval(() => {
            const memUsage = process.memoryUsage();
            this.addLog("system", {
                memory: {
                    rss: memUsage.rss,
                    heapUsed: memUsage.heapUsed
                },
                uptime: process.uptime()
            });
        }, 60000); // Every minute
    }
}

// Initialize application
const app = new DataLogger();

// Notify BrightScript that app is ready
app.messagePort.PostBSMessage({
    event: "app_ready",
    timestamp: new Date().toISOString()
});

console.log("Data Logger application started");
```

**HTML entry point (index.html):**

```html
<!DOCTYPE html>
<html>
<head>
    <title>BrightSign Data Logger</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        .status { background: #4CAF50; color: white; padding: 10px; }
        .log-entry { border: 1px solid #ddd; margin: 5px 0; padding: 10px; }
    </style>
</head>
<body>
    <div class="status" id="status">Initializing...</div>
    <h1>Data Logger</h1>
    <div id="logs"></div>

    <script src="./datalogger.js"></script>
    <script>
        // Update UI with latest logs
        async function updateLogs() {
            try {
                const response = await fetch("http://localhost:8080/api/logs");
                const logs = await response.json();

                const logsDiv = document.getElementById("logs");
                logsDiv.innerHTML = logs.slice(-10).reverse().map(log =>
                    `<div class="log-entry">
                        <strong>${log.timestamp}</strong> - ${log.type}<br>
                        <pre>${JSON.stringify(log.data, null, 2)}</pre>
                    </div>`
                ).join("");

                document.getElementById("status").textContent =
                    `Online - ${logs.length} logs`;
            } catch (err) {
                console.error("Failed to update logs:", err);
            }
        }

        // Update every 5 seconds
        setInterval(updateLogs, 5000);
        updateLogs();
    </script>
</body>
</html>
```

## Summary

BrightSign's Node.js implementation provides powerful server-side capabilities for digital signage applications:

- **Runtime**: Node.js 14.17.6 on OS 8.5+, integrated with Chromium V8 engine
- **Modules**: JavaScript-only modules supported; binary modules not compatible
- **File System**: Full access to device storage (SD, SSD, USB) via standard `fs` module
- **Networking**: HTTP servers, WebSockets, TCP/UDP sockets for local and remote communication
- **Hardware**: GPIO, serial port, and system integration via BrightSign APIs
- **Databases**: File-based solutions recommended; SQLite via BrightScript interop
- **APIs**: Build RESTful services with routing, middleware, and authentication
- **Real-time**: WebSocket and SSE support for live data streaming
- **Performance**: Event loop optimization and memory management critical for embedded systems
- **Debugging**: Remote inspector and console logging available

Best practices:
1. Use webpack to bundle and minimize dependencies
2. Implement proper error handling and logging
3. Monitor memory usage on embedded hardware
4. Use messageport for BrightScript/JavaScript communication
5. Test with actual BrightSign hardware, not just simulators
6. Pin dependency versions for stability
7. Implement graceful shutdown handling
8. Use pure JavaScript modules when possible

Node.js on BrightSign enables building sophisticated applications that combine web technologies with hardware control, making it ideal for interactive kiosks, data collection systems, and advanced digital signage solutions.


---

[← Previous](01-javascript-playback.md) | [↑ Part 3: JavaScript Development](README.md) | [Next →](03-debugging-javascript.md)
