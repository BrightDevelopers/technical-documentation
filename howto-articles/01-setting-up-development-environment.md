# Setting Up Your Development Environment

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide walks you through configuring your workstation for BrightSign development. By the end, you'll be able to:

- Connect to your player via serial or SSH
- Transfer files using multiple methods
- Choose between local and cloud-based development workflows
- Understand the critical role of `autorun.brs`
- Use the interactive debugger effectively

## Prerequisites

**Hardware Required:**
- BrightSign player (any Series 4 or 5 model)
- MicroSD card (Class 10 minimum, 16GB+ recommended)
- Display with HDMI input
- HDMI cable
- Network connection (Ethernet recommended for development)

**Optional but Recommended:**
- USB-to-serial cable for console access (FTDI FT232RL or Prolific PL2303GT chipset)

**Accounts:**
- BSN.cloud account (free tier available) - required for Remote DWS and cloud management

---

## Development Control Options

BrightSign offers two approaches to device management and development. Choose based on your needs:

| Approach | Best For | Requirements |
|----------|----------|--------------|
| **Local Control** | On-premise development, no cloud dependency | Player on local network |
| **Cloud Control** | Remote management, fleet operations, CI/CD | BSN.cloud account + API credentials |

You can use both approaches simultaneously.

---

## Local Control: Local DWS + CLI

Local control uses the Local Diagnostic Web Server (LDWS) built into every BrightSign player.

### Step 1: Enable Local DWS

The DWS is **disabled by default** due to EU Radio Equipment Directive (RED) compliance. Enable it by running this BrightScript on your player:

Create a file called `autorun.brs` with the following content:

```brightscript
' enable-dws.brs - Run once to enable Local DWS
Sub Main()
    ' Enable DWS
    reg = CreateObject("roRegistrySection", "networking")
    reg.Write("dwse", "yes")
    reg.Flush()

    ' Configure DWS on port 80 with authentication
    nc = CreateObject("roNetworkConfiguration", 0)
    nc.SetupDWS({port: "80", password: "yourpassword"})

    print "Local DWS enabled. Rebooting..."
    RebootSystem()
End Sub
```

Copy this file to an SD card, insert it into your player, and power on. After reboot, the DWS will be accessible.

### Step 2: Access Local DWS

Open a browser and navigate to:

```
http://<player-ip-address>/
```

**Default credentials:**
- Username: `admin`
- Password: Player serial number (or the password you set)

The DWS provides:
- Player status and diagnostics
- File browser and upload
- Screenshot capture
- Registry viewer
- Reboot controls
- REST API access

### Step 3: Install the BSC CLI Tool

The `@brightsign/bsc` CLI communicates with the Local DWS REST APIs:

```bash
npm install -g @brightsign/bsc
```

**Common BSC commands:**

```bash
# Set player credentials
export BSC_HOST=192.168.1.100
export BSC_USER=admin
export BSC_PASS=yourpassword

# Upload file to player
bsc put ./index.html /storage/sd/

# Download file from player
bsc get /storage/sd/logs/app.log ./

# List files
bsc ls /storage/sd/

# Take screenshot
bsc screenshot ./screenshot.png

# Reboot player
bsc reboot
```

---

## Cloud Control: Remote DWS via BSN.cloud

Cloud control enables remote management from anywhere using BSN.cloud and the Remote DWS (RDWS) API.

### Step 1: Get API Credentials

1. Log into [BSN.cloud](https://www.bsn.cloud)
2. Navigate to **Admin** → **API Access**
3. Create new OAuth2 credentials
4. Note your **Client ID** and **Secret**

### Step 2: Choose Your SDK

**Option A: gopurple SDK (Recommended)**

The [gopurple SDK](https://github.com/BrightDevelopers/gopurple) provides 73 ready-to-use CLI tools for BSN.cloud operations.

```bash
# Set credentials
export BS_CLIENT_ID=your_client_id
export BS_SECRET=your_client_secret
export BS_NETWORK=your_network_name

# Build the tools
git clone https://github.com/BrightDevelopers/gopurple
cd gopurple
make build-examples

# Use Remote DWS tools
./bin/rdws-info --serial BS123456789
./bin/rdws-snapshot --serial BS123456789 --output screenshot.png
./bin/rdws-reboot --serial BS123456789
./bin/rdws-files-list --serial BS123456789 --path /storage/sd/
```

See the complete list of 34 Remote DWS tools in the [gopurple examples documentation](https://github.com/BrightDevelopers/gopurple/blob/main/examples/README.md#remote-dws-operations-34).

**Option B: Direct REST API**

Use any language with HTTP support:

```python
import requests

# Authenticate
auth_response = requests.post(
    'https://auth.bsn.cloud/api/v1/oauth2/token',
    data={
        'grant_type': 'client_credentials',
        'client_id': 'your_client_id',
        'client_secret': 'your_secret',
        'scope': 'bsn.api.main.*'
    }
)
token = auth_response.json()['access_token']

# Use Remote DWS
headers = {'Authorization': f'Bearer {token}'}
# ... make API calls
```

---

## Connecting to Your Player

### Serial Connection

Serial provides direct console access, works even without network connectivity, and shows boot messages.

**Hardware:**
- USB-to-serial cable with 3.5mm TRS jack
- Recommended chipsets: FTDI FT232RL or Prolific PL2303GT

**Connection settings:**
- Baud rate: 115200
- Data bits: 8
- Parity: None
- Stop bits: 1
- Flow control: None

**Software by platform:**

| Platform | Command/Application |
|----------|---------------------|
| macOS | `screen /dev/tty.usbserial-* 115200` or Serial.app |
| Linux | `tio /dev/ttyUSB0 -b 115200` or `minicom -D /dev/ttyUSB0 -b 115200` |
| Windows | PuTTY (select Serial, set COM port and 115200 baud) |

### SSH Connection (Recommended)

SSH provides encrypted remote access with file transfer capabilities.

**Enable SSH on the player:**

```brightscript
' Add to autorun.brs or run via serial console
reg = CreateObject("roRegistrySection", "networking")
reg.Write("ssh", "22")

nc = CreateObject("roNetworkConfiguration", 0)
nc.SetLoginPassword("your-secure-password")
nc.Apply()
reg.Flush()

RebootSystem()
```

**Connect via SSH:**

```bash
# Using IP address
ssh brightsign@192.168.1.100

# Using mDNS (player serial number)
ssh brightsign@brightsign-D4A3B2C1.local
```

### Telnet (Development Only)

Telnet is unencrypted and should only be used in isolated development environments.

```brightscript
reg = CreateObject("roRegistrySection", "networking")
reg.Write("telnet", "23")
reg.Flush()
RebootSystem()
```

```bash
telnet 192.168.1.100
```

---

## File Transfer Methods

### Method 1: SD Card (Basic)

The simplest approach for initial setup:

1. Format SD card as FAT32 (≤32GB) or exFAT (>32GB)
2. Copy files to root directory
3. Insert into player and power on

### Method 2: SCP (SSH File Copy)

Requires SSH to be enabled on the player.

```bash
# Copy single file
scp index.html brightsign@192.168.1.100:/storage/sd/

# Copy entire directory
scp -r ./dist/ brightsign@192.168.1.100:/storage/sd/

# Sync directory (upload changes only)
rsync -avz --progress ./dist/ brightsign@192.168.1.100:/storage/sd/
```

### Method 3: BSC CLI

Using the `@brightsign/bsc` tool:

```bash
# Upload file
bsc put ./autorun.brs /storage/sd/

# Upload directory
bsc put -r ./content/ /storage/sd/content/
```

### Method 4: Local DWS API

Using curl:

```bash
# Upload file
curl -u admin:password -X PUT \
  -F "file=@index.html" \
  http://192.168.1.100/api/v1/files/sd/index.html

# Download file
curl -u admin:password \
  "http://192.168.1.100/api/v1/files/sd/logs/app.log?contents&stream" \
  -o app.log
```

### Method 5: VS Code Integration

For rapid development, configure VS Code's SFTP extension to auto-upload on save:

1. Install the "SFTP" extension
2. Create `.vscode/sftp.json`:

```json
{
    "name": "BrightSign Player",
    "host": "192.168.1.100",
    "protocol": "sftp",
    "port": 22,
    "username": "brightsign",
    "password": "your-password",
    "remotePath": "/storage/sd/",
    "uploadOnSave": true,
    "ignore": [".vscode", ".git", "node_modules"]
}
```

---

## The autorun.brs Requirement

**Critical concept:** Every BrightSign player requires an `autorun.brs` file in the root of the storage device. This file executes automatically at boot.

Even if your application is entirely HTML/JavaScript or Node.js, you still need an `autorun.brs` to launch it.

### Example 1: HTML Application Launcher

```brightscript
' autorun.brs - Launch HTML5 application
Sub Main()
    ' Create full-screen rectangle
    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)

    ' Configure HTML widget
    config = {
        url: "file:///sd:/index.html",
        mouse_enabled: true
    }

    ' Create and show widget
    htmlWidget = CreateObject("roHtmlWidget", rect, config)
    htmlWidget.Show()

    ' Event loop (required to keep application running)
    msgPort = CreateObject("roMessagePort")
    htmlWidget.SetPort(msgPort)

    while true
        msg = wait(0, msgPort)
        ' Handle events if needed
    end while
End Sub
```

### Example 2: Video Player

```brightscript
' autorun.brs - Loop video playback
Sub Main()
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetLoopMode(true)

    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    videoPlayer.PlayFile("video.mp4")

    while true
        msg = wait(0, msgPort)
        if type(msg) = "roVideoEvent" then
            print "Video event: "; msg.GetInt()
        end if
    end while
End Sub
```

### Example 3: Node.js Application Launcher

```brightscript
' autorun.brs - Launch Node.js server
Sub Main()
    ' Start Node.js with script
    nodeJs = CreateObject("roNodeJs", "/storage/sd/server.js")

    msgPort = CreateObject("roMessagePort")
    nodeJs.SetPort(msgPort)

    while true
        msg = wait(0, msgPort)
        if type(msg) = "roNodeJsEvent" then
            print "Node.js event: "; msg.GetInfo()
        end if
    end while
End Sub
```

---

## Interactive Debugging: Ctrl-C Behavior

When connected via SSH or serial while your application is running, you can use Ctrl-C to access debugging tools.

### First Ctrl-C: BrightScript Debugger

Pressing Ctrl-C the first time breaks into the BrightScript debugger at the current execution point.

**Debugger commands:**

| Command | Description |
|---------|-------------|
| `bt` | Print backtrace (call stack) |
| `var` | Display local variables |
| `step` or `s` | Execute one statement |
| `over` or `o` | Step over function call |
| `cont` or `c` | Continue execution |
| `print <expr>` or `? <expr>` | Evaluate and print expression |
| `list` | Show source code around current line |
| `gc` | Run garbage collector, show stats |
| `exit` | Exit debugger |

**Example session:**

```
BrightScript Debugger> bt
#0  Function processdata(data As Object) As Object
#1  Function main() As Void

BrightScript Debugger> var
Local Variables:
data          roAssociativeArray
index         Integer val: 5

BrightScript Debugger> ? data.count()
3

BrightScript Debugger> cont
```

### Second Ctrl-C: BrightSign Shell

Pressing Ctrl-C again (from the debugger) drops to the BrightSign shell, providing OS-level access.

**Useful shell commands:**

```bash
# File operations
dir /storage/sd              # List directory
delete /storage/sd/file.txt  # Delete file

# System info
version                      # Show OS version
id                          # Show device info
uptime                      # Show uptime

# Network
ifconfig                    # Show network config
ping google.com             # Test connectivity
nslookup google.com         # DNS lookup

# Registry
registry read networking ssh   # Read registry value
registry write networking ssh 22  # Write registry value

# Control
reboot                      # Reboot player
script                      # Return to BrightScript debugger
```

### Typing `exit`

**From BrightScript debugger:** Returns to shell or continues execution

**From BrightSign shell:** **Reboots the player** by default

**Exception - "Insecured" Mode:**

Players can be put into "insecured" mode for native extension development. In this mode, `exit` from the shell does NOT reboot, allowing you to return to a login prompt. This is required when developing custom C/C++ extensions.

---

## Complete Development Workflow Example

Here's a typical edit-deploy-test cycle:

```bash
# 1. Edit files on your workstation
vim index.html
vim autorun.brs

# 2. Deploy to player via SCP
scp autorun.brs index.html brightsign@192.168.1.100:/storage/sd/

# 3. Reboot player to reload
ssh brightsign@192.168.1.100 'reboot'

# 4. Connect to watch output
ssh brightsign@192.168.1.100
# Wait for boot, watch console output

# 5. Debug if needed
# Press Ctrl-C to enter debugger
# Use 'var', 'bt', 'print' to inspect state
# Press 'c' to continue or Ctrl-C again for shell
```

---

## Choosing Your Development Stack

| Use Case | Recommended Approach |
|----------|---------------------|
| Simple video signage | BrightScript + video files |
| Interactive kiosk | HTML5 + JavaScript + autorun.brs launcher |
| Data-driven displays | Node.js server + REST APIs |
| Cloud fleet management | gopurple SDK + BSN.cloud |
| CI/CD automation | gopurple CLI tools or @brightsign/bsc |
| Rapid prototyping | VS Code + SFTP auto-upload |

---

## Troubleshooting

### DWS Not Accessible

- Verify DWS is enabled: Check registry key `networking.dwse`
- Check firewall: Ensure port 80 (or 443 for HTTPS) is accessible
- Verify IP address: Use serial connection to confirm with `ifconfig`

### SSH Connection Refused

- Verify SSH is enabled: Registry key `networking.ssh` should be "22"
- Check password: Was `SetLoginPassword()` called?
- Reboot required: SSH changes require reboot

### Files Not Loading After Transfer

- Check file paths: BrightSign uses `/storage/sd/` not just `/sd/`
- Verify autorun.brs: Must be in root directory
- Check permissions: Files should be readable

### Player Not Rebooting with New Content

- Ensure autorun.brs is in the root directory
- Check for syntax errors: Connect via serial to see boot errors
- Verify SD card: Try reformatting if issues persist

---

## Next Steps

Now that your development environment is set up, continue with:

- [Your First BrightScript Application](02-first-brightscript-application.md) - Create a video player
- [Your First HTML5 Application](03-first-html5-application.md) - Build a web-based display

---

[← Back to How-To Articles](README.md) | [Next: Your First BrightScript Application →](02-first-brightscript-application.md)
