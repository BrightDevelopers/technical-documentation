# Debugging Production Issues

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers diagnosing and resolving issues on deployed BrightSign players. Production debugging requires different tools and techniques than development debugging, as you often have limited physical access to players and must work remotely through network connections.

### What You'll Learn

- Accessing deployed players remotely
- Using BrightScript debug console for troubleshooting
- Remote JavaScript debugging with Chrome DevTools
- Diagnostic Web Server (DWS) for player inspection
- Log collection and analysis
- Common production issues and solutions
- Building remote diagnostic tools

### When to Use This Guide

| Scenario | Tools Needed | Access Method |
|----------|--------------|---------------|
| **Player not responding** | DWS, SSH | Network |
| **Content not playing** | Debug console, logs | Serial/SSH |
| **Memory issues** | Chrome DevTools | Network |
| **Crash debugging** | Core dumps, GDB | SSH |
| **Performance problems** | Profiling, logs | Network/SSH |

---

## Prerequisites

- Deployed BrightSign player with network connectivity
- Understanding of BrightScript and/or JavaScript
- Network access to player (for remote debugging)
- Optional: Serial cable (for console access)
- Optional: SSH credentials or telnet access

---

## Part 1: Accessing Deployed Players

### Method 1: Serial Console (Most Reliable)

**Hardware Setup:**
```
BrightSign Serial Port (3.5mm or DB9)
    ↓
USB-to-Serial Adapter
    ↓
Development Computer
```

**Connect via terminal:**

```bash
# Linux/macOS
screen /dev/ttyUSB0 115200

# Or use minicom
minicom -D /dev/ttyUSB0 -b 115200

# Windows: Use PuTTY
# COM port, 115200 baud, 8N1
```

**Serial Console Features:**
- Boot messages and kernel logs
- BrightScript debug console access
- Emergency access when network fails
- Always available (no network required)

### Method 2: SSH Access

**Enable SSH (if disabled):**

Via registry in BrightScript:
```brightscript
reg = CreateObject("roRegistrySection", "networking")
reg.Write("ssh", "22")  ' Enable SSH on port 22
reg.Flush()

' Reboot to apply
device = CreateObject("roDeviceInfo")
device.Reboot()
```

**Connect via SSH:**

```bash
# brightsign is the only SSH user - there is no root SSH login on any build
ssh brightsign@192.168.1.100
# Password: the login password set with roNetworkConfiguration.SetLoginPassword()

# Or via mDNS
ssh brightsign@brightsign-SERIALNUMBER.local
```

The session attaches to whatever layer the player is currently running — usually the console of the running application, not a prompt. Descend with `Ctrl-C` + Enter (BrightScript Debugger), then `exit` (BrightSign Shell), then `exit` again (root Linux shell, insecured players only). One-shot commands (`ssh brightsign@<player> "<command>"`) do not work. See [Setting Up Your Development Environment](01-setting-up-development-environment.md#ssh-attaches-to-whatever-layer-is-currently-running).

### Method 3: Telnet Access

**Enable Telnet:**

```brightscript
reg = CreateObject("roRegistrySection", "networking")
reg.Write("telnet", "23")
reg.Flush()
```

**Connect:**

```bash
telnet 192.168.1.100
```

### Method 4: Local DWS (Diagnostic Web Server)

Access via web browser:

```
http://192.168.1.100/
http://BrightSign-SERIALNUMBER.local/
```

**DWS provides:**
- Player status and diagnostics
- Registry editor
- Log file viewer
- Network configuration
- System information
- Screenshot capture

---

## Part 2: BrightScript Debug Console

### Accessing the Console

**Via Serial:**
Press Ctrl-C during BrightScript execution to break into debugger.

**Via SSH/Telnet:**
```bash
# Stop current script
killall BrightSign

# Start interactive debugger
brightscript
```

### Debug Console Commands

```brightscript
BrightScript Debugger> help

Available commands:
  help              - Show this help
  cont (c)          - Continue execution
  step (s)          - Step to next statement
  out               - Step out of current function
  print <expr>      - Evaluate and print expression
  var               - Show local variables
  bt                - Show call stack (backtrace)
  exit              - Exit debugger
```

### Interactive Debugging

**Inspect Variables:**

```brightscript
BrightScript Debugger> print videoPlayer
<Component: roVideoPlayer>

BrightScript Debugger> print m
{
  videoPlayer: <Component: roVideoPlayer>
  msgPort: <Component: roMessagePort>
  currentState: "playing"
}

BrightScript Debugger> print m.currentState
"playing"
```

**Execute Code:**

```brightscript
BrightScript Debugger> deviceInfo = CreateObject("roDeviceInfo")
BrightScript Debugger> print deviceInfo.GetModel()
"XD1034"

BrightScript Debugger> print deviceInfo.GetVersion()
"9.1.105"
```

### Using STOP Breakpoints

Add breakpoints in code for remote debugging:

```brightscript
Sub Main()
    ' Your code...

    ' Conditional breakpoint
    if errorCondition then
        STOP  ' Breaks into debugger here
    end if

    ' Debug specific code path
    if testMode then
        STOP
        print "Debug info: "; debugVariable
    end if
End Sub
```

**When STOP is hit:**
- Player pauses execution
- Drops to debug console (serial/SSH)
- Can inspect state
- Can continue with `cont` command

---

## Part 3: JavaScript/Chrome DevTools Debugging

### Enable Remote Debugging

**In autorun.brs (HTML widget):**

```brightscript
config = {
    url: "file:///sd:/app/index.html",
    inspector_server: {
        port: 2999  ' Chrome DevTools port
    }
}

htmlWidget = CreateObject("roHtmlWidget", rect, config)
```

**Or via Node.js:**

```javascript
// Start Node.js with inspector
const inspector = require('inspector');
inspector.open(9229, '0.0.0.0');
```

### Connect Chrome DevTools

1. **Open Chrome** on your development computer
2. **Navigate to:** `chrome://inspect`
3. **Configure network targets:** Add `192.168.1.100:2999`
4. **Click "inspect"** when device appears

**DevTools Features:**
- Console for logging and execution
- Sources for breakpoints and debugging
- Network tab for request monitoring
- Memory profiler for leak detection
- Performance profiler

### Remote Console Logging

**Structured logging:**

```javascript
// Basic logging
console.log('Application started');

// Structured data
console.log('User action:', {
    type: 'button_press',
    buttonId: 1,
    timestamp: Date.now()
});

// Error logging
console.error('Failed to load content:', error);

// Table view (useful for arrays)
console.table([
    {name: 'Video 1', status: 'playing'},
    {name: 'Video 2', status: 'queued'}
]);

// Performance timing
console.time('loadContent');
// ... code ...
console.timeEnd('loadContent');
```

### Setting Breakpoints

```javascript
function processData(data) {
    // Programmatic breakpoint
    debugger;  // Pauses execution when DevTools attached

    // Process data...
    return result;
}
```

---

## Part 4: Diagnostic Web Server (DWS)

### Two DWS surfaces — know which one your player exposes

A player presents **one of two different DWS APIs**, and which one you get is decided by a single registry key.

**`networking.bbhf` is the switch:**

| `bbhf` | What the player exposes |
|--------|-------------------------|
| Set (`on`) | The modern `/api/v1/...` REST API — ~127 routes — **and** the legacy endpoints |
| Unset | Only the pre-BrightSign-Control "legacy" DWS and its endpoints |

**This is the usual explanation for "half the endpoints 404 on this player."** Before you start debugging your client, check the key:

```bash
curl --digest -u admin:<dws-password> \
  http://192.168.1.100/api/v1/registry/networking/bbhf
```

If the modern API is what you want and `bbhf` is unset, set it (`reg.Write("bbhf", "on")` in the `networking` section, then reboot) — see [Setting Up Your Development Environment](01-setting-up-development-environment.md).

**Prefer the modern API for anything new.** It is authenticated, versioned, self-describing (`GET /api/v1/` returns the live route list with a `securityLevel` on each route), and it is what the rest of this documentation set uses.

### Modern API: `/api/v1/...` (preferred)

Digest authentication is required — `curl -u` alone returns `401`. The username is always `admin`.

```bash
AUTH="--digest -u admin:<dws-password>"
BASE=http://192.168.1.100/api/v1

curl $AUTH $BASE/info                      # Player identity
curl $AUTH $BASE/health                    # Health
curl $AUTH $BASE/logs                      # Logs
curl $AUTH $BASE/registry                  # Full registry dump
curl $AUTH -X POST $BASE/snapshot          # Screenshot
curl $AUTH $BASE/legacy/storage_info       # Raw low-level dumps
```

| Route | Purpose |
|-------|---------|
| `GET /api/v1/` | Live route list, each with a `securityLevel` |
| `GET /api/v1/info`, `/health`, `/time` | Identity, health, clock |
| `GET /api/v1/logs`, `/download-log-package` | Logs and log bundles |
| `GET /api/v1/registry[/<section>[/<key>]]` | Registry read |
| `POST /api/v1/snapshot` | Screenshot |
| `GET/PUT/DELETE /api/v1/files/*` | File operations |
| `PUT /api/v1/control/reboot` | Reboot |
| `GET /api/v1/diagnostics[/ping/*|/dns-lookup/*]` | Network diagnostics |
| `GET /api/v1/legacy/<name>` | ~45 raw dumps (`processes`, `dmesg`, `registry_dump`, `secure_boot`, …) |

> The whole `/api/v1` surface is served by the **Supervisor**. If you have descended to the root Linux shell over SSH, the Supervisor is stopped and every one of these calls fails — see [Interactive Debugging](01-setting-up-development-environment.md#interactive-debugging-descending-through-the-shell-layers).

### Legacy endpoints (older players, `bbhf` unset)

These are the pre-BrightSign-Control endpoints. They are unauthenticated, which is exactly why they should not be reachable from an untrusted network. Use them only when the modern API is unavailable on the target.

```bash
# Player info
curl http://192.168.1.100/

# Logs
curl http://192.168.1.100/GetSystemLog

# Registry
curl http://192.168.1.100/GetRegistry

# Screenshot
wget http://192.168.1.100/GetScreenshot -O screenshot.jpg
```

| Legacy endpoint | Purpose | Output | Modern equivalent |
|----------|---------|--------|-------------------|
| `/` | Player dashboard | HTML | `/api/v1/info` |
| `/GetSystemLog` | System logs | Text | `/api/v1/logs` |
| `/GetPlaybackLog` | Playback events | Text | `/api/v1/logs` |
| `/GetRegistry` | Registry values | JSON | `/api/v1/registry` |
| `/GetStorageInfo` | Disk usage | JSON | `/api/v1/legacy/storage_info` |
| `/GetNetworkDiagnostics` | Network tests | JSON | `/api/v1/diagnostics` |
| `/GetScreenshot` | Current display | JPEG | `POST /api/v1/snapshot` |
| `/Reboot` | Reboot player | - | `PUT /api/v1/control/reboot` |

### Automated Log Collection

```bash
#!/bin/bash
# Collect diagnostics from player

PLAYER_IP=$1
OUTPUT_DIR="diagnostics_$(date +%Y%m%d_%H%M%S)"

mkdir -p $OUTPUT_DIR

echo "Collecting diagnostics from $PLAYER_IP..."

# System log
curl -s "http://$PLAYER_IP/GetSystemLog" > "$OUTPUT_DIR/system.log"

# Playback log
curl -s "http://$PLAYER_IP/GetPlaybackLog" > "$OUTPUT_DIR/playback.log"

# Registry
curl -s "http://$PLAYER_IP/GetRegistry" > "$OUTPUT_DIR/registry.json"

# Storage info
curl -s "http://$PLAYER_IP/GetStorageInfo" > "$OUTPUT_DIR/storage.json"

# Network diagnostics
curl -s "http://$PLAYER_IP/GetNetworkDiagnostics" > "$OUTPUT_DIR/network.json"

# Screenshot
curl -s "http://$PLAYER_IP/GetScreenshot" > "$OUTPUT_DIR/screenshot.jpg"

echo "Diagnostics saved to $OUTPUT_DIR/"
ls -lh $OUTPUT_DIR/
```

---

## Part 5: Log Analysis

### System Logs

**Critical log locations:**
```bash
/var/log/messages        # Main system log
/var/log/boot            # Boot messages
/var/log/player.log      # Player-specific logs
/storage/sd/logs/        # Application logs (if configured)
```

**View logs via SSH:**

```bash
# Recent messages
tail -n 100 /var/log/messages

# Follow logs in real-time
tail -f /var/log/messages

# Filter by application
grep "my-app" /var/log/messages

# Search for errors
grep -i error /var/log/messages
```

### Diagnostic Event Codes

Common event codes in logs:

| Code | Event | Meaning |
|------|-------|---------|
| `0` | Startup | Player booted |
| `1` | Content started | Playback began |
| `2` | Content ended | Playback finished |
| `8` | Network up | Network connected |
| `9` | Network down | Network lost |
| `100` | Error | General error |
| `101` | Memory error | Out of memory |

### First 5-10 Minutes Critical

**The most useful logs are from startup:**
```bash
# Extract first 10 minutes after boot
head -n 500 /var/log/messages > startup_log.txt

# Look for common issues:
# - "Out of memory"
# - "Failed to load"
# - "Connection refused"
# - "Timeout"
```

---

## Part 6: Common Production Issues

### Issue 1: Memory Leaks

**Symptoms:**
- Player reboots periodically
- Performance degrades over time
- "Out of memory" errors in logs

**Diagnosis:**

```javascript
// Monitor memory usage
setInterval(() => {
    const usage = process.memoryUsage();
    console.log('Memory:', {
        rss: Math.round(usage.rss / 1024 / 1024) + 'MB',
        heapUsed: Math.round(usage.heapUsed / 1024 / 1024) + 'MB',
        heapTotal: Math.round(usage.heapTotal / 1024 / 1024) + 'MB'
    });
}, 60000);
```

**Solution:**

```brightscript
' Clean up video elements properly
videoPlayer.Stop()
videoPlayer.SetUrl("")  ' CRITICAL: Reset source to free memory
videoPlayer = invalid
```

### Issue 2: Content Not Playing

**Check via DWS:**
```bash
curl http://192.168.1.100/GetPlaybackLog
```

**Common causes:**
- File not found (404)
- Codec not supported
- Insufficient memory
- Corrupt file

**Debug via BrightScript:**

```brightscript
Sub Main()
    videoPlayer = CreateObject("roVideoPlayer")
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    ' Enable detailed event logging
    videoPlayer.SetTimecodeReporting(true)

    result = videoPlayer.PlayFile("video.mp4")
    print "PlayFile result: "; result

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            eventCode = msg.GetInt()
            print "Video event: "; eventCode

            if eventCode = 15 then  ' Playback failure
                errorInfo = msg.GetData()
                print "ERROR: "; errorInfo
                STOP  ' Break to debugger
            end if
        end if
    end while
End Sub
```

### Issue 3: Network Connectivity

**Test connectivity:**

```bash
# Via SSH
ping -c 4 8.8.8.8

# DNS resolution
nslookup google.com

# Specific endpoint
curl -I https://api.example.com
```

**Via BrightScript:**

```brightscript
Function TestNetworkConnectivity() as Boolean
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl("http://services.brightsignnetwork.com/bs/networkdiagnostic.ashx")
    urlTransfer.SetTimeout(10000)

    response = urlTransfer.GetToString()

    if response = "BrightSign Network" then
        print "Network connectivity: OK"
        return true
    else
        print "Network connectivity: FAILED"
        print "Response code: "; urlTransfer.GetResponseCode()
        return false
    end if
End Function
```

### Issue 4: Performance Degradation

**Monitor via JavaScript:**

```javascript
// Performance monitoring
const metrics = {
    frameCount: 0,
    lastCheck: Date.now()
};

function monitorPerformance() {
    metrics.frameCount++;

    const now = Date.now();
    const elapsed = now - metrics.lastCheck;

    if (elapsed >= 1000) {
        const fps = Math.round(metrics.frameCount / (elapsed / 1000));
        console.log(`FPS: ${fps}`);

        if (fps < 20) {
            console.warn('Performance degraded!');
        }

        metrics.frameCount = 0;
        metrics.lastCheck = now;
    }

    requestAnimationFrame(monitorPerformance);
}

monitorPerformance();
```

---

## Part 7: Remote Diagnostic Dashboard

A complete example for monitoring multiple players:

### monitor-server.js

```javascript
const express = require('express');
const axios = require('axios');

const app = express();
const players = [
    { id: 'player1', ip: '192.168.1.100' },
    { id: 'player2', ip: '192.168.1.101' },
    { id: 'player3', ip: '192.168.1.102' }
];

app.get('/api/status', async (req, res) => {
    const status = await Promise.all(
        players.map(async (player) => {
            try {
                const response = await axios.get(`http://${player.ip}/`, {
                    timeout: 5000
                });

                return {
                    id: player.id,
                    ip: player.ip,
                    online: true,
                    uptime: extractUptime(response.data)
                };
            } catch (error) {
                return {
                    id: player.id,
                    ip: player.ip,
                    online: false,
                    error: error.message
                };
            }
        })
    );

    res.json(status);
});

app.get('/api/logs/:playerId', async (req, res) => {
    const player = players.find(p => p.id === req.params.playerId);

    if (!player) {
        return res.status(404).json({ error: 'Player not found' });
    }

    try {
        const response = await axios.get(`http://${player.ip}/GetSystemLog`);
        res.type('text/plain').send(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/screenshot/:playerId', async (req, res) => {
    const player = players.find(p => p.id === req.params.playerId);

    if (!player) {
        return res.status(404).send('Player not found');
    }

    try {
        const response = await axios.get(`http://${player.ip}/GetScreenshot`, {
            responseType: 'arraybuffer'
        });

        res.type('image/jpeg').send(response.data);
    } catch (error) {
        res.status(500).send('Screenshot failed');
    }
});

function extractUptime(html) {
    const match = html.match(/Uptime: (\d+)/);
    return match ? parseInt(match[1]) : 0;
}

app.listen(3000, () => {
    console.log('Monitoring dashboard running on http://localhost:3000');
});
```

### dashboard.html

```html
<!DOCTYPE html>
<html>
<head>
    <title>Player Monitoring Dashboard</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background: #f5f5f5;
        }
        .player-card {
            background: white;
            padding: 20px;
            margin: 10px 0;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .player-card.online { border-left: 4px solid #4CAF50; }
        .player-card.offline { border-left: 4px solid #f44336; }
        .status { font-size: 24px; margin-bottom: 10px; }
        .screenshot { max-width: 400px; margin-top: 10px; }
        button { padding: 8px 16px; margin: 5px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>Player Monitoring Dashboard</h1>
    <div id="players"></div>

    <script>
        async function updateStatus() {
            const response = await fetch('/api/status');
            const players = await response.json();

            const container = document.getElementById('players');
            container.innerHTML = players.map(player => `
                <div class="player-card ${player.online ? 'online' : 'offline'}">
                    <div class="status">
                        ${player.online ? '🟢' : '🔴'} ${player.id}
                    </div>
                    <div>IP: ${player.ip}</div>
                    ${player.online ? `
                        <div>Uptime: ${player.uptime} seconds</div>
                        <button onclick="viewLogs('${player.id}')">View Logs</button>
                        <button onclick="viewScreenshot('${player.id}')">Screenshot</button>
                        <div id="screenshot-${player.id}"></div>
                    ` : `
                        <div style="color: red">Error: ${player.error}</div>
                    `}
                </div>
            `).join('');
        }

        async function viewLogs(playerId) {
            const response = await fetch(`/api/logs/${playerId}`);
            const logs = await response.text();

            const win = window.open('', 'Logs');
            win.document.write(`<pre>${logs}</pre>`);
        }

        async function viewScreenshot(playerId) {
            const container = document.getElementById(`screenshot-${playerId}`);
            container.innerHTML = `<img class="screenshot" src="/api/screenshot/${playerId}" alt="Screenshot">`;
        }

        // Update every 10 seconds
        setInterval(updateStatus, 10000);
        updateStatus();
    </script>
</body>
</html>
```

---

## Best Practices

### Do

- **Enable debug features** in development only
- **Collect logs early** - first 5-10 minutes most useful
- **Use structured logging** - JSON format for parsing
- **Implement health checks** - HTTP endpoints for monitoring
- **Document debug procedures** - For field technicians
- **Test remote access** before deployment
- **Monitor memory usage** - Prevent leaks
- **Log to persistent storage** - Survive reboots

### Don't

- **Don't leave debug enabled** in production (web inspector)
- **Don't ignore memory warnings** - Address proactively
- **Don't assume network connectivity** - Always test
- **Don't delete logs** - Archive for analysis
- **Don't debug in production** - Use staging environment when possible
- **Don't expose DWS publicly** - Security risk

---

## Troubleshooting

| Problem | Diagnosis | Solution |
|---------|-----------|----------|
| Can't access player | Network down | Use serial console |
| Debug console won't break | STOP not hit | Add print statements, check logic |
| Chrome DevTools won't connect | Inspector not enabled | Add inspector_server config |
| Logs full of errors | Application bug | Filter, analyze, fix root cause |
| Player crashes | Memory/hardware issue | Check core dumps, reduce memory usage |

---

## Exercises

1. **Build log collector**: Create script to collect diagnostics from multiple players

2. **Memory monitor**: Implement memory tracking with alerts when threshold exceeded

3. **Remote dashboard**: Build web dashboard showing player status and screenshots

4. **Log analyzer**: Parse logs to identify common error patterns

5. **Health check service**: Create HTTP service that monitors player health

---

## Next Steps

- [Performance Optimization](18-performance-optimization.md) - Improve player performance
- [Secure Deployment Practices](19-secure-deployment-practices.md) - Secure production deployments
- [Building Custom Extensions](16-building-custom-extensions.md) - Advanced diagnostics extensions

---

## Additional Resources

- [BrightScript Debugger](https://docs.brightsign.biz/developers/brightscript-debugger)
- [BrightScript Debug Console](https://docs.brightsign.biz/developers/brightscript-debug-console)
- [Diagnostic Web Server](https://docs.brightsign.biz/advanced/diagnostic-web-server-dws)
- [Diagnostic Logging Event Codes](https://support.brightsign.biz/hc/en-us/articles/218064257-Diagnostic-Logging-Event-Codes)

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
