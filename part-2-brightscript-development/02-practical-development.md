# Chapter 3: Practical BrightSign Software Development

[← Back to Part 2: BrightScript Development](README.md) | [↑ Main](../README.md)

---

This chapter covers essential techniques and best practices for effective BrightScript development and player management in production environments.

## Development Workflow

### Setting Up Development Environments

Development on BrightSign players requires careful setup to maximize efficiency:

**Local Development Setup:**
- Install terminal applications for serial/SSH access (PuTTY for Windows, iTerm2/Serial for Mac, tio for Linux)
- Configure USB-to-Serial cables with compatible chipsets (FTDI FT232RL or Prolific PL2303GT recommended)
- Set up network access for remote deployment and debugging
- Enable development tools early in the workflow

**Development Storage Paths:**
- `/storage/sd/` - Primary SD card storage for content and scripts
- `/storage/usb/` - USB storage for development assets
- `/storage/flash/` - Internal flash storage (use for applet binaries for better performance)
- `/tmp/` - Temporary storage for development artifacts

**Best Practices:**
- Create a `dumps` folder on the player for crash information storage
- Use Ext3 or Ext4 file systems for SD cards (better compatibility than FAT32)
- Organize project files logically: separate content, scripts, and configuration files

### File Deployment Strategies

**SD Card Deployment:**

The most basic deployment method involves writing files directly to an SD card:

```brightscript
' Example: Create directory structure on SD card
CreateDirectory("SD:/content")
CreateDirectory("SD:/content/videos")
CreateDirectory("SD:/content/images")
CreateDirectory("SD:/logs")
```

**Important SD Card Rules:**
1. Write setup files to the card first, then power up the player
2. DO NOT publish a presentation between writing setup files and running them
3. Setup files will run over presentation files if both are present

**Remote Deployment with autorun.zip:**

Deploy entire file structures remotely using autorun.zip:

```text
autorun.zip structure:
  autorun.brs
  content/
    video1.mp4
    image1.jpg
  config/
    settings.json
```

When the unit reboots, it unpacks autorun.zip to the SD card and executes the configuration. The zip file should contain published files at the root level, not in a subfolder.

**Network Deployment:**

For Local File Networking (LFN), the player connects to a local network and receives updates via HTTP:

```brightscript
' Configure URL transfer for remote content
url = CreateObject("roUrlTransfer")
url.SetUrl("http://server.local/content/video.mp4")
url.AsyncGetToFile("SD:/content/video.mp4")
```

**SFTP Deployment:**

Once SSH is enabled, use SFTP for file transfers:
- Tools: FileZilla, WinSCP, or command-line sftp
- Connection: `sftp brightsign@<player-ip>`
- VS Code users can use the SFTP extension for automatic file transfer on save

## Player Communication

### Telnet/SSH Access

**Enabling Telnet (port 23):**

From BrightScript Debugger or in autorun.brs:
```brightscript
reg = CreateObject("roRegistrySection", "networking")
reg.write("telnet","23")
RebootSystem()
```

From BrightSign Shell:
```text
registry write networking telnet 23
reboot
```

**Accessing Telnet:**
```bash
telnet <IP_ADDRESS>
```

**Enabling SSH (port 22) - RECOMMENDED:**

SSH provides encrypted sessions and is more secure than Telnet:

```brightscript
reg = CreateObject("roRegistrySection", "networking")
reg.write("ssh","22")

n = CreateObject("roNetworkConfiguration", 0)
n.SetLoginPassword("password")
n.Apply()
reg.flush()
RebootSystem()
```

**Accessing SSH:**
```bash
ssh brightsign@<IP_ADDRESS>
# or using mDNS
ssh brightsign@brightsign-<SERIAL_NUMBER>.local
```

**Security Note:** For production environments, disable Telnet/SSH. Only enable for development and debugging.

### Diagnostic Web Server (DWS)

The DWS provides web-based access to player diagnostics, configuration, and remote operations.

**Local DWS (LDWS):**

Access via local network at `http://<player-ip>/`

Default credentials:
- Username: `admin`
- Password: Player serial number (or custom-configured)

**Enable Local DWS via BrightScript:**
```brightscript
reg = CreateObject("roRegistrySection", "networking")
reg.write("dwse", "yes")
reg.flush()
```

**LDWS API Examples:**

```bash
# Get player info
curl -u admin:serialnumber http://192.168.1.100/api/v1/info/player

# Download file from player
curl -u admin:serialnumber \
  "http://192.168.1.100/api/v1/files/sd/myfile.txt?contents&stream" \
  -o myfile.txt

# Reboot player
curl -u admin:serialnumber -X PUT \
  http://192.168.1.100/api/v1/reboot
```

**Remote DWS (RDWS):**

Accessed via BSN.cloud or BrightAuthor:connected. Uses OAuth bearer tokens for authentication and provides remote access to:
- Player status and logs
- Network diagnostics
- File upload/download (10MB limit)
- Remote reboot and configuration

**Using HTTPS with Local DWS:**

Generate self-signed certificate:
```bash
openssl req -nodes -new -x509 -keyout dws.key -out dws.crt
```

Place `dws.crt` and `dws.key` at the root of default storage, or configure via registry:
```brightscript
reg = CreateObject("roRegistrySection", "networking")
reg.write("ldws_cert_file_name", "mycert.crt")
reg.write("ldws_key_file_name", "mykey.key")
reg.flush()
```

### Remote Debugging

**BrightScript Debugger:**

Enable debugging via registry:
```brightscript
reg = CreateObject("roRegistrySection", "brightscript")
reg.write("debug","1")
```

Or from BrightSign Shell:
```text
script debug on
```

**Access the Debugger:**
1. Via serial, Telnet, or SSH
2. Press Ctrl-C during runtime to break into debugger
3. Add `stop` statements in code as breakpoints

**Debugger Commands:**
- `bt` - Print backtrace of function calls
- `var` - Display local variables and values
- `step` or `s` - Step one statement
- `cont` or `c` - Continue execution
- `print <expr>` - Evaluate and print expression
- `list` - List current source code
- `gc` - Run garbage collector and show stats

**JavaScript/HTML Debugging:**

For HTML content using roHtmlWidget:

1. Enable web inspector:
```brightscript
reg = CreateObject("roRegistrySection", "html")
reg.write("enable_web_inspector", "1")
reg.flush()
```

2. Configure roHtmlWidget:
```brightscript
config = {
    inspector_server: { port: 2999 }
}
widget = CreateObject("roHtmlWidget", rectangle, config)
```

3. Access Chrome DevTools:
   - Open `chrome://inspect` in Chrome browser
   - Click "Configure" and add `<player-ip>:2999`
   - Click "inspect" on the discovered target

## File Management

### Efficient Deployment

**Content Organization:**
- Group assets by type (videos/, images/, audio/, scripts/)
- Use asset pools for dynamic content management
- Implement version control for configuration files

**Asset Pool Example:**
```brightscript
pool = CreateObject("roAssetPool", "SD:/pool")
collection = CreateObject("roAssetCollection", pool)
collection.SetUrl("http://server.local/manifest.json")
collection.Realize()
```

**Optimized File Transfer:**
```brightscript
' Use roUrlTransfer with resume capability
url = CreateObject("roUrlTransfer")
url.SetUrl("http://server.local/largefile.mp4")
url.EnableResume(true)  ' Allow resume on failure
url.SetPort(msgPort)
url.AsyncGetToFile("SD:/content/largefile.mp4")
```

### SD Card Organization

**Recommended Structure:**
```
/storage/sd/
├── autorun.brs              # Main application script
├── content/                 # Media files
│   ├── videos/
│   ├── images/
│   └── audio/
├── config/                  # Configuration files
│   ├── setup.json
│   └── network.json
├── scripts/                 # Library scripts
│   ├── utils.brs
│   └── networking.brs
├── logs/                    # Application logs
├── pool/                    # Asset pool storage
└── dumps/                   # Crash dumps
```

**File System Best Practices:**
- Avoid deep directory nesting (limit to 3-4 levels)
- Use consistent naming conventions (lowercase, no spaces)
- Clean up temporary files regularly to prevent storage exhaustion

### Remote File Operations

**Using Local DWS APIs for File Management:**

```bash
# List files in directory
curl -u admin:serial http://192.168.1.100/api/v1/files/sd/content

# Upload file to player
curl -u admin:serial -X PUT \
  -F "file=@video.mp4" \
  http://192.168.1.100/api/v1/files/sd/content/video.mp4

# Delete file
curl -u admin:serial -X DELETE \
  http://192.168.1.100/api/v1/files/sd/content/oldfile.mp4
```

**Bulk File Operations Script:**
```brightscript
' Delete old log files
ListDir("SD:/logs/") ' Returns array of files
for each file in logFiles
    if file.age > 7 ' days
        DeleteFile("SD:/logs/" + file.name)
    end if
end for
```

## Testing Strategies

### Unit Testing Patterns

BrightScript lacks formal testing frameworks, but you can implement testing patterns:

**Basic Test Framework:**
```brightscript
' Simple assertion function
function Assert(condition as Boolean, message as String) as Void
    if not condition then
        print "TEST FAILED: " + message
        stop  ' Break to debugger
    else
        print "TEST PASSED: " + message
    end if
end function

' Example test
function TestStringParsing() as Void
    result = ParseConfigValue("key=value")
    Assert(result.key = "key", "Key should be 'key'")
    Assert(result.value = "value", "Value should be 'value'")
end function
```

**Mock Objects:**
```brightscript
' Mock message port for testing
function CreateMockMessagePort() as Object
    mock = {
        messages: []
        PostMessage: function(msg as Object)
            m.messages.Push(msg)
        end function
        GetMessage: function() as Dynamic
            if m.messages.Count() > 0 then
                return m.messages.Shift()
            end if
            return invalid
        end function
        WaitMessage: function(timeout as Integer) as Dynamic
            return m.GetMessage()
        end function
    }
    return mock
end function
```

### Integration Testing

**Network Diagnostics Test:**

BrightSign provides a network diagnostics script for testing connectivity:

```brightscript
' Test network connectivity
diagnostics = CreateObject("roNetworkConfiguration", 0)
status = diagnostics.GetCurrentConfig()

print "Interface: " + status.interface
print "IP Address: " + status.ip4_address
print "Gateway: " + status.ip4_gateway

' Test internet connectivity
url = CreateObject("roUrlTransfer")
url.SetUrl("http://www.google.com")
response = url.GetToString()
if response <> "" then
    print "Internet connectivity: OK"
else
    print "Internet connectivity: FAILED"
end if
```

**Video Mode Test:**
```brightscript
' Test video output configuration
videoMode = CreateObject("roVideoMode")
modes = videoMode.GetSupportedModes()
print "Supported video modes:"
for each mode in modes
    print mode
end for

' Set and verify mode
videoMode.SetMode("1920x1080x60p")
sleep(2000)
currentMode = videoMode.GetMode()
print "Current mode: " + currentMode
```

### Automated Testing

**Automated Deployment Test Script:**
```brightscript
' Test deployment workflow
sub TestDeployment()
    ' 1. Download test content
    url = CreateObject("roUrlTransfer")
    url.SetUrl("http://testserver/test-video.mp4")
    success = url.AsyncGetToFile("SD:/test/test-video.mp4")

    ' 2. Wait for completion
    msg = wait(30000, port)

    ' 3. Verify file exists and play
    if type(msg) = "roUrlEvent" and msg.GetResponseCode() = 200 then
        player = CreateObject("roVideoPlayer")
        player.PlayFile("SD:/test/test-video.mp4")
        print "Deployment test: PASSED"
    else
        print "Deployment test: FAILED"
    end if
end sub
```

**Continuous Integration Considerations:**
- Use BrightSign dev-cookbook GitHub Actions templates for automated builds
- Implement health check endpoints for monitoring
- Log test results to remote server for analysis
- Use Node.js v14.17.6 (pre-installed on most players) for build scripts

## Performance Optimization

### Memory Management

**Memory Limitations:**
BrightSign players have limited memory compared to general-purpose computers. Developers must manage memory carefully.

**Critical Memory Best Practices:**

1. **Release Video Elements Explicitly:**
```brightscript
' INCORRECT - memory leak
video = CreateObject("roVideoPlayer")
video.PlayFile("video1.mp4")
video.PlayFile("video2.mp4")  ' video1 still in memory!

' CORRECT - release previous video
video = CreateObject("roVideoPlayer")
video.PlayFile("video1.mp4")
video.Stop()
video = invalid  ' Release reference
video = CreateObject("roVideoPlayer")
video.PlayFile("video2.mp4")
```

2. **Clear HTML Widget Content:**
```brightscript
' Before switching content or destroying widget
htmlWidget.SetUrl("about:blank")
htmlWidget = invalid
```

3. **Garbage Collection:**
```brightscript
' Force garbage collection during idle periods
System.GC()  ' Available in JavaScript
' In BrightScript, use debugger command 'gc' for manual collection
```

**Monitor Memory Usage:**
```brightscript
' Check available memory
sysInfo = CreateObject("roDeviceInfo")
memInfo = sysInfo.GetMemoryLevel()
print "Memory level: " + memInfo.ToString() + "%"

if memInfo < 20 then
    ' Take action: clear caches, reload app
    print "WARNING: Low memory detected"
end if
```

### Execution Profiling

**Performance Timing:**
```brightscript
' Measure execution time
startTime = CreateObject("roTimespan")

' Your code here
for i = 1 to 10000
    result = ComplexCalculation(i)
end for

elapsed = startTime.TotalMilliseconds()
print "Execution time: " + elapsed.ToStr() + "ms"
```

**BrightScript Debugger Profiling:**

Use debugger commands to analyze performance:
```text
BrightScript Debugger> stats
BrightScript Debugger> counts    ' Show object instance counts
BrightScript Debugger> bsc       ' List all allocated components
BrightScript Debugger> hash      ' Show hash table statistics
```

**JavaScript Performance API:**
```javascript
// Use performance.now() for high-resolution timing
const start = performance.now();
// Your code
const end = performance.now();
console.log(`Execution time: ${end - start}ms`);
```

### Bottleneck Identification

**Common Bottlenecks:**

1. **File I/O Operations:**
```brightscript
' SLOW - synchronous read
content = ReadAsciiFile("SD:/large-config.json")

' FASTER - async with streaming
' Use roUrlTransfer for asynchronous operations
```

2. **Network Requests:**
```brightscript
' SLOW - blocking request
url = CreateObject("roUrlTransfer")
result = url.GetToString()  ' Blocks until complete

' FASTER - async request
url.SetPort(msgPort)
url.AsyncGetToString()  ' Non-blocking
```

3. **String Operations:**
```brightscript
' SLOW - repeated concatenation
result = ""
for i = 1 to 1000
    result = result + "line" + i.ToStr() + chr(10)
end for

' FASTER - use array and Join
lines = []
for i = 1 to 1000
    lines.Push("line" + i.ToStr())
end for
result = lines.Join(chr(10))
```

**Chromium Performance Tracing:**

Enable Chromium tracing via registry:
```brightscript
reg = CreateObject("roRegistrySection", "html")
reg.write("tracecategories", "blink,cc,gpu")
reg.write("traceduration", "30")  ' seconds
reg.write("tracemonitorinterval", "60")  ' seconds
reg.flush()
```

Traces are saved to `/storage/sd/chromium_trace_*.json` and can be analyzed in `chrome://tracing`.

## Development Tools

### CLI Tools

**BrightSign Shell Commands:**

Essential shell commands for development:

```text
# File operations
dir /storage/sd              # List directory contents
delete /storage/sd/old.mp4   # Delete file
cd /storage/sd/content       # Change directory

# System information
version                      # Show OS version
id                          # Show device info
uptime                      # Show device uptime
log                         # Display system log

# Network operations
ifconfig                    # Configure network
ping google.com             # Test connectivity
nslookup google.com         # DNS lookup
wifiscan                    # Scan WiFi networks

# Performance testing
readperf                    # Measure read performance
writeperf                   # Measure write performance
httpgetperf <url>           # Measure download performance

# Media testing
videoplay <file>            # Play video snippet
audioplay <file>            # Play audio snippet
imageplay <file>            # Display image

# Registry management
registry read <section> <key>
registry write <section> <key> <value>
registry delete <section> <key>

# Debugging
script                      # Enter BrightScript debugger
node                        # Enter Node.js interpreter
```

### Automation Scripts

**Registry Configuration Script:**
```brightscript
' Configure player via script
function ConfigurePlayer() as Void
    reg = CreateObject("roRegistrySection", "networking")

    ' Enable SSH
    reg.Write("ssh", "22")

    ' Enable Local DWS
    reg.Write("dwse", "yes")

    ' Configure syslog
    reg.Write("syslog", "192.168.1.10")

    reg.Flush()

    ' Set network password
    net = CreateObject("roNetworkConfiguration", 0)
    net.SetLoginPassword("dev-password-123")
    net.Apply()

    print "Configuration complete. Rebooting..."
    RebootSystem()
end function
```

**Automated Log Collection:**
```brightscript
' Collect and upload logs
function UploadLogs() as Void
    ' Read system log
    logFile = "SD:/logs/app-log-" + GetCurrentDate() + ".txt"

    ' Copy log to file
    CopyFile("/tmp/messages", logFile)

    ' Upload to server
    url = CreateObject("roUrlTransfer")
    url.SetUrl("http://logserver/upload")
    url.AddHeader("X-Device-Serial", GetDeviceSerial())
    url.AsyncPostFromFile(logFile)

    print "Log upload initiated"
end function
```

**Health Check Script:**
```brightscript
' Periodic health monitoring
function HealthCheck() as Void
    status = {
        timestamp: CreateObject("roDateTime").ToISOString()
        uptime: GetSystemUptime()
        memory: GetMemoryLevel()
        storage: GetStorageInfo()
        network: GetNetworkStatus()
    }

    ' Send to monitoring server
    url = CreateObject("roUrlTransfer")
    url.SetUrl("http://monitor.local/health")
    url.AddHeader("Content-Type", "application/json")
    url.PostFromString(FormatJson(status))
end function
```

### Deployment Pipelines

**GitHub Actions Example (from dev-cookbook):**

```yaml
name: Deploy to BrightSign
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '14.17.6'

      - name: Install dependencies
        run: npm install

      - name: Build application
        run: npm run build

      - name: Create deployment package
        run: |
          mkdir deploy
          cp -r dist/* deploy/
          cd deploy && zip -r ../autorun.zip .

      - name: Deploy to player
        env:
          PLAYER_IP: ${{ secrets.PLAYER_IP }}
          PLAYER_USER: brightsign
          PLAYER_PASS: ${{ secrets.PLAYER_PASS }}
        run: |
          sshpass -p $PLAYER_PASS scp autorun.zip \
            $PLAYER_USER@$PLAYER_IP:/storage/sd/
```

**Build Script Example:**
```javascript
// build.js - Node.js build script for BrightSign
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

function buildAutorun() {
    // Compile TypeScript/ES6 to BrightScript-compatible JS
    console.log('Building application...');

    // Copy assets
    fs.cpSync('src/assets', 'dist/assets', { recursive: true });

    // Create autorun.brs
    const autorunTemplate = fs.readFileSync('templates/autorun.brs', 'utf8');
    const autorun = autorunTemplate.replace('{{VERSION}}', process.env.VERSION);
    fs.writeFileSync('dist/autorun.brs', autorun);

    console.log('Build complete: dist/');
}

buildAutorun();
```

## Player Configuration

### Registry Management

**Registry Structure:**

The BrightSign registry is organized into sections with key-value pairs:

```brightscript
' Access registry sections
networking = CreateObject("roRegistrySection", "networking")
html = CreateObject("roRegistrySection", "html")
video = CreateObject("roRegistrySection", "video")
brightscript = CreateObject("roRegistrySection", "brightscript")
```

**Common Registry Keys:**

**Networking Section:**
```brightscript
reg = CreateObject("roRegistrySection", "networking")

' Telnet/SSH
reg.Write("telnet", "23")           ' Enable Telnet on port 23
reg.Write("ssh", "22")              ' Enable SSH on port 22
reg.Write("serial_with_telnet", "1") ' Enable serial with telnet

' DWS Configuration
reg.Write("dwse", "yes")            ' Enable local DWS
reg.Write("http_server", "80")      ' DWS on standard port

' Network Logging
reg.Write("syslog", "192.168.1.10") ' Remote syslog server
reg.Write("curl_debug", "1")        ' Enable curl debug output

reg.Flush()
```

**HTML Section:**
```brightscript
reg = CreateObject("roRegistrySection", "html")

' Web Inspector
reg.Write("enable_web_inspector", "1")

' Performance
reg.Write("disable-http-cache", "1")      ' Disable HTTP cache
reg.Write("use-brightsign-media-player", "0") ' Use Chromium player

' Debugging
reg.Write("disable-web-security", "1")    ' Disable CORS (dev only)
reg.Write("js-trace-gc", "1")             ' Trace garbage collection

reg.Flush()
```

**BrightScript Section:**
```brightscript
reg = CreateObject("roRegistrySection", "brightscript")
reg.Write("debug", "1")  ' Enable BrightScript debugger
reg.Flush()
```

**Video Section:**
```brightscript
reg = CreateObject("roRegistrySection", "video")
reg.Write("auto_mode_vms_override", "1920x1080x60p")
reg.Flush()
```

### Network Setup

**Static IP Configuration:**
```brightscript
nc = CreateObject("roNetworkConfiguration", 0)
config = nc.GetCurrentConfig()

' Set static IP
config.ip4_address = "192.168.1.100"
config.ip4_netmask = "255.255.255.0"
config.ip4_gateway = "192.168.1.1"
config.dns_servers = ["8.8.8.8", "8.8.4.4"]

nc.SetIP4Address(config.ip4_address)
nc.SetIP4Netmask(config.ip4_netmask)
nc.SetIP4Gateway(config.ip4_gateway)
nc.SetDnsServers(config.dns_servers)
nc.Apply()

' Save to registry for persistence
reg = CreateObject("roRegistrySection", "networking")
reg.Write("sip", config.ip4_address)
reg.Flush()
```

**WiFi Configuration:**
```brightscript
' Enable WiFi
reg = CreateObject("roRegistrySection", "networking")
reg.Write("wifi", "1")
reg.Flush()

' Configure WiFi network
wifi = CreateObject("roNetworkConfiguration", 1)  ' 1 = WiFi interface
wifi.SetWiFiSSID("MyNetwork")
wifi.SetWiFiPassphrase("MyPassword")
wifi.Apply()
```

### System Configuration

**Time Zone Setup:**
```brightscript
' Set time zone
tz = CreateObject("roTimeZone")
tz.SetTimeZone("America/New_York")

' Or via registry
reg = CreateObject("roRegistrySection", "networking")
reg.Write("tz", "America/New_York")
reg.Flush()
```

**Display Configuration:**
```brightscript
' Configure video mode
vm = CreateObject("roVideoMode")
vm.SetMode("1920x1080x60p")

' Set HDMI output settings
vm.SetCaptionMode("off")
vm.SetDeInterlace(true)
```

**Boot Configuration:**
```brightscript
' Disable splash screen
reg = CreateObject("roRegistrySection", "boot")
reg.Write("splash", "0")
reg.Flush()
```

## Remote Management

### Batch Operations

**Multi-Player Configuration Script:**
```brightscript
' Configure multiple players from CSV
sub ConfigureFleet(csvFile as String)
    players = ParseCSV(ReadAsciiFile(csvFile))

    for each player in players
        url = CreateObject("roUrlTransfer")
        url.SetUrl("http://" + player.ip + "/api/v1/registry")
        url.SetUserAndPassword("admin", player.serial)

        ' Set registry values
        config = {
            networking: {
                sip: player.static_ip
                ssh: "22"
            }
        }

        url.AddHeader("Content-Type", "application/json")
        url.PostFromString(FormatJson(config))

        print "Configured: " + player.serial
    end for
end sub
```

**Remote Reboot Script:**
```bash
#!/bin/bash
# Reboot multiple players

PLAYERS=("192.168.1.100" "192.168.1.101" "192.168.1.102")
PASSWORD="admin-password"

for ip in "${PLAYERS[@]}"; do
    echo "Rebooting $ip..."
    curl -u admin:$PASSWORD -X PUT \
        http://$ip/api/v1/reboot
    sleep 2
done
```

### Fleet Management

**Control Cloud / BSN.Cloud Features:**
- Real-time player health monitoring with 24-hour health reports
- Remote player controls (reboot, diagnostics, settings)
- Network groups and tagging for organization
- Filtered reporting across entire fleet
- Remote configuration for single or multiple players

**API-Based Fleet Management:**

```python
# Python script for fleet management via Remote DWS APIs
import requests

class BrightSignFleet:
    def __init__(self, oauth_token):
        self.token = oauth_token
        self.base_url = "https://api.bsn.cloud/rdws"

    def get_player_status(self, device_id):
        headers = {"Authorization": f"Bearer {self.token}"}
        response = requests.get(
            f"{self.base_url}/devices/{device_id}/status",
            headers=headers
        )
        return response.json()

    def reboot_player(self, device_id):
        headers = {"Authorization": f"Bearer {self.token}"}
        response = requests.put(
            f"{self.base_url}/devices/{device_id}/reboot",
            headers=headers
        )
        return response.status_code == 200

    def batch_update_registry(self, device_ids, section, key, value):
        for device_id in device_ids:
            headers = {"Authorization": f"Bearer {self.token}"}
            data = {
                "section": section,
                "key": key,
                "value": value
            }
            requests.post(
                f"{self.base_url}/devices/{device_id}/registry",
                headers=headers,
                json=data
            )
```

### Monitoring Tools

**Health Check Endpoint:**
```brightscript
' Create health check HTTP server
function StartHealthServer() as Void
    server = CreateObject("roHttpServer", { port: 8080 })
    server.AddGetRequest("/health", HealthHandler)
    server.Start()
end function

function HealthHandler(req as Object) as Object
    device = CreateObject("roDeviceInfo")

    health = {
        status: "healthy"
        uptime: device.GetUptime()
        memory: device.GetMemoryLevel()
        storage: GetStorageInfo()
        version: device.GetVersion()
    }

    return {
        status: 200
        headers: { "Content-Type": "application/json" }
        body: FormatJson(health)
    }
end function
```

**Log Aggregation:**
```brightscript
' Send logs to central server
function SendLogs() as Void
    ' Read recent logs
    logs = GetRecentLogs(100)  ' Last 100 lines

    ' Upload to log server
    url = CreateObject("roUrlTransfer")
    url.SetUrl("http://logserver.local/ingest")
    url.AddHeader("X-Device-Serial", GetDeviceSerial())
    url.AddHeader("X-Device-Model", GetDeviceModel())
    url.AddHeader("Content-Type", "application/json")

    payload = {
        timestamp: CreateObject("roDateTime").ToISOString()
        device: GetDeviceSerial()
        logs: logs
    }

    url.PostFromString(FormatJson(payload))
end function
```

**Prometheus Metrics Export:**

Enable node_exporter via registry:
```brightscript
reg = CreateObject("roRegistrySection", "networking")
reg.Write("prometheus-node-exporter-port", "9100")
reg.Flush()
```

Metrics available at `http://<player-ip>:9100/metrics`:
```text
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode
# HELP node_memory_MemAvailable_bytes Memory available for use
# HELP node_filesystem_avail_bytes Filesystem space available
```

**Remote Snapshot Monitoring:**
```brightscript
' Configure remote snapshots
reg = CreateObject("roRegistrySection", "networking")
reg.Write("enableremotesnapshot", "true")
reg.Write("remotesnapshotinterval", "300")  ' 5 minutes
reg.Write("remotesnapshotjpegqualitylevel", "80")
reg.Write("remotesnapshotmaximages", "10")
reg.Flush()
```

Access snapshots via DWS:
```bash
# Get latest snapshot
curl -u admin:serial \
  http://192.168.1.100/api/v1/snapshot
```

## Summary

This chapter covered the essential techniques for practical BrightSign development:

- **Development Workflow**: Setting up environments, organizing projects, and deploying files efficiently
- **Player Communication**: Accessing players via Telnet/SSH, using the Diagnostic Web Server, and remote debugging
- **File Management**: Efficient deployment strategies, SD card organization, and remote file operations
- **Testing**: Unit testing patterns, integration testing, and automated testing approaches
- **Performance**: Memory management, execution profiling, and bottleneck identification
- **Development Tools**: CLI commands, automation scripts, and deployment pipelines
- **Configuration**: Registry management, network setup, and system configuration
- **Remote Management**: Batch operations, fleet management, and monitoring tools

By mastering these techniques, developers can build robust, maintainable, and performant BrightSign applications ready for production deployment.

For specialized debugging techniques and advanced troubleshooting, continue to [Chapter 4: Debugging BrightScript](../chapter04-debugging-brightscript/).


---

[← Previous](01-brightscript-language-reference.md) | [↑ Part 2: BrightScript Development](README.md) | [Next →](03-debugging-brightscript.md)
