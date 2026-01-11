# Building Custom Extensions

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers creating custom native extensions for BrightSign players. Extensions are persistent software packages that extend player capabilities with compiled languages like C++, Go, or Node.js/TypeScript, enabling custom services, protocols, and hardware integrations beyond standard BrightScript capabilities.

### What You'll Learn

- Understanding BrightSign extension architecture
- Choosing the right extension type for your needs
- Building TypeScript/Node.js extensions (no SDK required)
- Building Go extensions with static compilation
- Building C/C++ extensions with the BrightSign SDK
- Creating extension init scripts for lifecycle management
- Packaging and deploying extensions
- Production signing for secure players

### Extension Use Cases

| Use Case | Language | SDK Required |
|----------|----------|--------------|
| **Custom HTTP API** | TypeScript/Node.js | No |
| **Background Services** | Go, C++ | Go: No, C++: Yes |
| **Hardware Protocols** | C++ | Yes |
| **Database Services** | Any | Depends |
| **Custom Analytics** | TypeScript/Node.js | No |
| **Industrial IoT** | C++, Go | C++: Yes, Go: No |

---

## Prerequisites

- Linux development host with x86 CPU (required for all extensions)
- Docker installed (recommended for C++ SDK)
- BrightSign player running OS v9.x or later
- Serial cable and/or SSH access to player
- Understanding of compiled languages (C++, Go, or TypeScript)
- `squashfs-tools` package: `sudo apt-get install squashfs-tools`

**Optional for C++ SDK development:**
- ~50GB disk space for SDK build
- Several hours for initial SDK compilation

---

## Extension Architecture

### What is a BrightSign Extension?

An extension is a **SquashFS filesystem** that:
- Installs persistently to internal flash storage
- Survives reboots and firmware updates
- Auto-mounts at `/var/volatile/bsext/{extension_name}/`
- Runs automatically on boot via SysV init scripts
- Can be uninstalled to free storage

**Key Characteristics:**
- Read-only filesystem at runtime
- Self-starting with init scripts
- Isolated from player firmware
- Removable without affecting player operation

### Extension Types

**Standalone Extensions:**
- Work across BrightSign OS versions
- No dynamic linking to system libraries
- Examples: Go (static), Node.js (built-in runtime)

**Versioned Extensions:**
- Require specific BOS version
- Dynamically link to system libraries
- Examples: C/C++ with shared libraries
- Need BrightSign SDK for development

---

## Part 1: TypeScript/Node.js Extensions (No SDK)

The easiest way to build extensions using the player's built-in Node.js runtime.

### Project Structure

```
hello_world-ts-extension/
├── src/
│   └── index.ts              # Main application code
├── scripts/
│   ├── bsext_init            # Init script (lifecycle)
│   └── make-extension-lvm    # Packaging script
├── package.json
├── tsconfig.json
└── webpack.config.js
```

### Step 1: Initialize Project

```bash
mkdir my-extension && cd my-extension
npm init -y

# Install dependencies
npm install --save-dev typescript webpack webpack-cli ts-loader

# Install BrightSign types (if available)
npm install --save-dev @brightsign/bscore
```

### Step 2: Create TypeScript Application

**src/index.ts:**

```typescript
// Simple HTTP API extension
import * as http from 'http';
import * as fs from 'fs';

const PORT = 8080;
const LOG_FILE = '/storage/sd/extension.log';

function log(message: string): void {
    const timestamp = new Date().toISOString();
    const logMessage = `[${timestamp}] ${message}\n`;

    // Log to file
    fs.appendFileSync(LOG_FILE, logMessage);

    // Log to console (captured by syslog)
    console.log(message);
}

// Create HTTP server
const server = http.createServer((req, res) => {
    log(`Request: ${req.method} ${req.url}`);

    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'ok',
            uptime: process.uptime(),
            memory: process.memoryUsage()
        }));
    } else if (req.url === '/reboot') {
        log('Reboot requested');
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('Rebooting...');

        // Trigger reboot via script
        setTimeout(() => {
            require('child_process').exec('reboot');
        }, 1000);
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(PORT, () => {
    log(`Extension HTTP API listening on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    log('Received SIGTERM, shutting down gracefully');
    server.close(() => {
        log('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    log('Received SIGINT, shutting down gracefully');
    server.close(() => {
        log('Server closed');
        process.exit(0);
    });
});
```

### Step 3: Configure Build Tools

**tsconfig.json:**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

**webpack.config.js:**

```javascript
const path = require('path');

module.exports = {
  entry: './src/index.ts',
  target: 'node',
  mode: 'production',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/
      }
    ]
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js']
  },
  output: {
    filename: 'index.js',
    path: path.resolve(__dirname, 'dist')
  }
};
```

**package.json scripts:**

```json
{
  "scripts": {
    "build": "webpack",
    "package-lvm": "bash scripts/make-extension-lvm",
    "clean": "rm -rf dist *.sqsh"
  }
}
```

### Step 4: Create Init Script

**scripts/bsext_init:**

```bash
#!/bin/sh
# Extension lifecycle script

EXTENSION_NAME="my-extension"
EXTENSION_PATH="/var/volatile/bsext/${EXTENSION_NAME}"
NODE_BIN="/usr/bin/node"
APP_SCRIPT="${EXTENSION_PATH}/dist/index.js"
PID_FILE="/var/run/${EXTENSION_NAME}.pid"

start() {
    echo "Starting ${EXTENSION_NAME}..."

    if [ -f "$PID_FILE" ]; then
        echo "Extension already running (PID: $(cat $PID_FILE))"
        return 1
    fi

    # Start Node.js application in background
    $NODE_BIN $APP_SCRIPT &
    echo $! > $PID_FILE

    echo "Extension started (PID: $(cat $PID_FILE))"
}

stop() {
    echo "Stopping ${EXTENSION_NAME}..."

    if [ ! -f "$PID_FILE" ]; then
        echo "Extension not running"
        return 1
    fi

    PID=$(cat $PID_FILE)
    kill $PID
    rm -f $PID_FILE

    echo "Extension stopped"
}

run() {
    # Optional: Run in foreground for debugging
    echo "Running ${EXTENSION_NAME} in foreground..."
    $NODE_BIN $APP_SCRIPT
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    run)
        run
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|run}"
        exit 1
esac
```

**Make executable:**

```bash
chmod +x scripts/bsext_init
```

### Step 5: Create Packaging Script

**scripts/make-extension-lvm:**

```bash
#!/bin/bash
# Package extension as SquashFS

EXTENSION_NAME="my-extension"
OUTPUT_FILE="${EXTENSION_NAME}.sqsh"
STAGING_DIR="./extension-staging"

echo "Packaging ${EXTENSION_NAME}..."

# Clean previous builds
rm -rf $STAGING_DIR $OUTPUT_FILE

# Create staging directory
mkdir -p $STAGING_DIR

# Copy application files
cp -r dist $STAGING_DIR/
cp scripts/bsext_init $STAGING_DIR/

# Create SquashFS image
mksquashfs $STAGING_DIR $OUTPUT_FILE \
    -comp xz \
    -b 1M \
    -noappend

# Cleanup
rm -rf $STAGING_DIR

echo "Extension packaged: $OUTPUT_FILE"
ls -lh $OUTPUT_FILE
```

### Step 6: Build and Package

```bash
# Build TypeScript
npm run build

# Package extension
npm run package-lvm

# Result: my-extension.sqsh
```

---

## Part 2: Go Extensions (No SDK)

Go extensions benefit from static compilation and minimal dependencies.

### Go Extension Example

**main.go:**

```go
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
)

type StatusResponse struct {
    Status  string    `json:"status"`
    Uptime  float64   `json:"uptime"`
    Time    time.Time `json:"time"`
}

var startTime time.Time

func main() {
    startTime = time.Now()

    log.Println("Extension starting...")

    // Setup HTTP handlers
    http.HandleFunc("/health", healthHandler)
    http.HandleFunc("/status", statusHandler)

    // Start server in goroutine
    server := &http.Server{Addr: ":8080"}

    go func() {
        log.Println("HTTP server listening on :8080")
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Server error: %v", err)
        }
    }()

    // Wait for interrupt signal
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

    sig := <-sigChan
    log.Printf("Received signal: %v, shutting down...", sig)

    // Graceful shutdown
    if err := server.Close(); err != nil {
        log.Printf("Error closing server: %v", err)
    }

    log.Println("Extension stopped")
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(StatusResponse{
        Status: "ok",
        Uptime: time.Since(startTime).Seconds(),
        Time:   time.Now(),
    })
}

func statusHandler(w http.ResponseWriter, r *http.Request) {
    log.Printf("Status request from %s", r.RemoteAddr)

    w.Header().Set("Content-Type", "text/plain")
    fmt.Fprintf(w, "Extension running for %.2f seconds\n", time.Since(startTime).Seconds())
}
```

### Cross-Compile for BrightSign

```bash
# Build for ARM64 (BrightSign architecture)
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o extension-binary main.go

# Verify static linking
file extension-binary
# Should show: statically linked
```

### Package Go Extension

Use the same init script and packaging approach as TypeScript, but deploy the compiled binary instead of Node.js code.

---

## Part 3: C++ Extensions (SDK Required)

For hardware access and maximum performance.

### Prerequisites

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Clone extension template
git clone https://github.com/brightsign/extension-template.git
cd extension-template/examples/time_publisher-cpp-extension
```

### C++ Extension Structure

```
time_publisher-cpp-extension/
├── src/
│   ├── main.cpp              # Application logic
│   └── CMakeLists.txt        # Build configuration
├── scripts/
│   ├── bsext_init            # Init script
│   ├── build-sdk.sh          # SDK build script
│   └── make-extension-lvm    # Packaging script
└── Makefile
```

### Example: UDP Time Publisher

**src/main.cpp:**

```cpp
#include <iostream>
#include <cstring>
#include <ctime>
#include <csignal>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <syslog.h>

volatile sig_atomic_t running = 1;

void signalHandler(int signal) {
    syslog(LOG_INFO, "Received signal %d, shutting down", signal);
    running = 0;
}

int main() {
    // Initialize syslog
    openlog("time-publisher", LOG_PID | LOG_CONS, LOG_USER);
    syslog(LOG_INFO, "Time Publisher Extension starting");

    // Setup signal handlers
    signal(SIGTERM, signalHandler);
    signal(SIGINT, signalHandler);

    // Create UDP socket
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        syslog(LOG_ERR, "Failed to create socket");
        return 1;
    }

    // Enable broadcast
    int broadcast = 1;
    if (setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST,
                   &broadcast, sizeof(broadcast)) < 0) {
        syslog(LOG_ERR, "Failed to enable broadcast");
        close(sockfd);
        return 1;
    }

    // Setup broadcast address
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(5000);
    addr.sin_addr.s_addr = inet_addr("255.255.255.255");

    syslog(LOG_INFO, "Broadcasting time on port 5000");

    // Main loop
    while (running) {
        // Get current time
        time_t now = time(nullptr);
        char timeStr[64];
        strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S",
                 localtime(&now));

        // Broadcast time
        if (sendto(sockfd, timeStr, strlen(timeStr), 0,
                   (struct sockaddr*)&addr, sizeof(addr)) < 0) {
            syslog(LOG_ERR, "Failed to send broadcast");
        } else {
            syslog(LOG_DEBUG, "Broadcasted: %s", timeStr);
        }

        // Wait 1 second
        sleep(1);
    }

    close(sockfd);
    syslog(LOG_INFO, "Time Publisher Extension stopped");
    closelog();

    return 0;
}
```

### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.10)
project(time_publisher)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Source files
add_executable(time_publisher
    main.cpp
)

# Link libraries (if needed)
# target_link_libraries(time_publisher pthread)

# Install target
install(TARGETS time_publisher
    RUNTIME DESTINATION bin
)
```

### Building with SDK

```bash
# Build SDK (first time only, takes hours)
./scripts/build-sdk.sh

# Build extension using Docker
docker run --rm -v $(pwd):/workspace brightsign-sdk:latest \
    bash -c "cd /workspace && mkdir -p build && cd build && \
    cmake .. && make"

# Package extension
./scripts/make-extension-lvm
```

---

## Part 4: Extension Deployment

### Testing on Unsecured Player

**Via SSH:**

```bash
# Copy extension to player
scp my-extension.sqsh root@192.168.1.100:/storage/sd/

# SSH to player
ssh root@192.168.1.100

# Install extension
install-extension /storage/sd/my-extension.sqsh

# Check installation
ls /var/volatile/bsext/

# View logs
tail -f /var/log/messages | grep my-extension

# Manually start extension (for testing)
/var/volatile/bsext/my-extension/bsext_init start

# Check if running
ps | grep extension
```

### Registry-Based Auto-Start

Extensions auto-start on boot, but you can control this via registry:

```brightscript
' Disable auto-start
reg = CreateObject("roRegistrySection", "bsext")
reg.Write("my-extension-autostart", "0")
reg.Flush()

' Enable auto-start
reg.Write("my-extension-autostart", "1")
reg.Flush()
```

---

## Part 5: Production Signing

For deployment to secure players.

### Submission Process

1. **Prepare extension** with globally unique name
2. **Contact Partner Engineer** at BrightSign
3. **Submit .sqsh file** for signing
4. **Receive .bsfw file** (signed extension)

### Deploying Signed Extensions

```bash
# Copy .bsfw to SD card root
cp my-extension.bsfw /media/sd-card/

# Insert SD card into player
# Player automatically installs on boot

# Verify installation via DWS
curl http://192.168.1.100/GetExtensions

# Or via SSH
ssh root@192.168.1.100 "ls /var/volatile/bsext/"
```

---

## Complete Example: Custom Analytics Extension

A production-ready extension that collects player metrics and sends to remote API.

### analytics-extension/src/index.ts

```typescript
import * as http from 'http';
import * as https from 'https';
import * as os from 'os';
import * as fs from 'fs';

interface Metrics {
    playerId: string;
    timestamp: string;
    uptime: number;
    memory: NodeJS.MemoryUsage;
    cpuUsage: NodeJS.CpuUsage;
    freeMemory: number;
    totalMemory: number;
}

class AnalyticsCollector {
    private apiEndpoint: string;
    private playerId: string;
    private interval: NodeJS.Timeout | null = null;

    constructor(apiEndpoint: string, playerId: string) {
        this.apiEndpoint = apiEndpoint;
        this.playerId = playerId;
    }

    start(intervalMs: number = 60000): void {
        console.log(`Starting analytics collector (interval: ${intervalMs}ms)`);

        // Immediate first collection
        this.collect();

        // Schedule periodic collection
        this.interval = setInterval(() => {
            this.collect();
        }, intervalMs);
    }

    stop(): void {
        if (this.interval) {
            clearInterval(this.interval);
            this.interval = null;
            console.log('Analytics collector stopped');
        }
    }

    private collect(): void {
        const metrics: Metrics = {
            playerId: this.playerId,
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            cpuUsage: process.cpuUsage(),
            freeMemory: os.freemem(),
            totalMemory: os.totalmem()
        };

        this.sendMetrics(metrics);
    }

    private sendMetrics(metrics: Metrics): void {
        const data = JSON.stringify(metrics);

        const options = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': data.length
            }
        };

        const req = https.request(this.apiEndpoint, options, (res) => {
            console.log(`Metrics sent, status: ${res.statusCode}`);
        });

        req.on('error', (error) => {
            console.error('Failed to send metrics:', error.message);
        });

        req.write(data);
        req.end();
    }
}

// Main application
const API_ENDPOINT = process.env.ANALYTICS_API || 'https://api.example.com/metrics';
const PLAYER_ID = getPlayerId();
const INTERVAL = parseInt(process.env.COLLECTION_INTERVAL || '60000', 10);

const collector = new AnalyticsCollector(API_ENDPOINT, PLAYER_ID);
collector.start(INTERVAL);

// Graceful shutdown
process.on('SIGTERM', () => {
    collector.stop();
    process.exit(0);
});

function getPlayerId(): string {
    // Try to read from file system
    try {
        const deviceId = fs.readFileSync('/sys/class/net/eth0/address', 'utf-8').trim();
        return deviceId.replace(/:/g, '');
    } catch {
        return 'unknown';
    }
}
```

---

## Best Practices

### Do

- **Choose appropriate language** - TypeScript/Go for simplicity, C++ for hardware
- **Implement graceful shutdown** - Handle SIGTERM/SIGINT signals
- **Use syslog for logging** - Logs captured by system
- **Test on unsecured player** before production signing
- **Use unique extension names** - Globally unique across all BrightSign partners
- **Minimize dependencies** - Reduces size and compatibility issues
- **Write data to writable locations** - `/storage/sd/`, `/tmp/`, not extension path
- **Implement health checks** - HTTP endpoint for monitoring
- **Version your extensions** - Include version in manifest

### Don't

- **Don't write to extension directory** - It's read-only
- **Don't assume OS version** - Test across BOS versions
- **Don't use hardcoded paths** - Use environment variables
- **Don't skip error handling** - Extensions should be resilient
- **Don't block the init script** - Use background processes
- **Don't ignore resource limits** - Memory and CPU constraints
- **Don't skip signing** - Required for secure players

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Extension won't install | Invalid SquashFS | Rebuild with correct mksquashfs options |
| Extension won't start | Init script errors | Check `chmod +x bsext_init` |
| Process terminates | Signal not handled | Implement SIGTERM handler |
| Can't write files | Writing to extension dir | Write to `/storage/sd/` instead |
| Missing dependencies | Dynamic linking | Use static compilation (Go, C++ static) |
| Extension not auto-starting | Registry disabled | Check bsext registry section |

### Debugging Extensions

```bash
# SSH to player
ssh root@192.168.1.100

# Manual start for testing
/var/volatile/bsext/my-extension/bsext_init run

# Check logs
tail -f /var/log/messages

# Check process
ps | grep my-extension

# Kill process
kill $(pidof my-extension-binary)

# Uninstall extension
rm -rf /var/volatile/bsext/my-extension
```

---

## Exercises

1. **HTTP API Extension**: Build a TypeScript extension that provides a REST API for player control

2. **Data Logger**: Create a Go extension that logs system metrics to SD card

3. **Hardware Monitor**: Build a C++ extension that monitors GPIO states and sends alerts

4. **Background Sync**: Create an extension that syncs content from cloud storage

5. **Custom Protocol**: Implement a custom network protocol handler in C++

---

## Next Steps

- [Debugging Production Issues](17-debugging-production-issues.md) - Troubleshoot deployed extensions
- [Performance Optimization](18-performance-optimization.md) - Optimize extension performance
- [Secure Deployment Practices](19-secure-deployment-practices.md) - Secure your extensions

---

## Additional Resources

- [GitHub: BrightSign extension-template](https://github.com/brightsign/extension-template)
- [BrightSign Extensions Documentation](https://docs.brightsign.biz/developers/brightsign-extensions)
- SquashFS documentation: kernel.org/doc/Documentation/filesystems/squashfs.txt

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
