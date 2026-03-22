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

## Quick Start

The easiest way to quickly set your player up for development is to put this `autorun.brs` on a blank SD card and boot your player. Once it runs and displays the prompt on screen, remove the card and manually reboot the player. It will enable the Local Diagnostic Web Server (DWS), SSH, BrightScript debug mode, and verbose logging, with no password required.

1. Format an SD card as FAT32 and create a file called `autorun.brs` at the root with exactly the following content:

```brightscript
Sub Main()

    regB = CreateObject("roRegistrySection", "brightscript")
    regB.Write("debug", "1")
    regB.Flush()

    reg = CreateObject("roRegistrySection", "networking")
    reg.Write("bbhf", "on")
    reg.Write("dwse", "yes")
    reg.Write("curl_debug", "1")
    reg.Write("prometheus-node-exporter-port", "9100")
    reg.write("ssh", "22")
    reg.write("telnet_log_level", "7")
    reg.Flush()

    CreateObject("roNetworkConfiguration", 0).SetupDWS({port:"80", open:"none"})

    n = CreateObject("roNetworkConfiguration", 0) ' ethernet interface
    n.SetLoginPassword("none")
    n.Apply()

    ShowMessage("now manually reboot the player...")

    'DeleteFile("autorun.brs")
    sleep(50000)
    'RebootSystem()

End Sub


Sub ShowMessage(msg)

    gaa = GetGlobalAA()

    videoMode = CreateObject("roVideoMode")
    resX = videoMode.GetResX()
    resY = videoMode.GetResY()
    videoMode = invalid
    r = CreateObject("roRectangle", 0, resY/2-resY/64, resX, resY/32)
    twParams = CreateObject("roAssociativeArray")
    twParams.LineCount = 1
    twParams.TextMode = 2
    twParams.Rotation = 0
    twParams.Alignment = 1
    gaa.tw = CreateObject("roTextWidget", r, 1, 2, twParams)

    gaa.tw.PushString(msg)
    gaa.tw.Show()
    print msg

End Sub
```

2. Insert the SD card into the player and apply power.
3. Wait for the player to display **"now manually reboot the player..."** on screen.
4. Remove the SD card, then manually reboot the player.
5. After reboot without the SD card, the player is ready:
   - **Local DWS** — open `http://<player-ip>/` in a browser (no login required)
   - **SSH** — `ssh brightsign@<player-ip>` with no password
   - **BSC CLI** — install with `npm install -g @brightsign/bsc` and use `bsc` commands against the player

This is sufficient for BrightScript, HTML5, and Node.js development.

**If you need to develop native OS extensions** — compiled code that runs as part of the OS rather than inside BrightScript or Node.js — you must first insecure the player. See [Insecuring a Player for Extension Development](#insecuring-a-player-for-extension-development). **This is an irreversible, one-way operation. Never do it to a production player.**

---

# Detailed Explanation of Developer Setup

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
import base64

# Authenticate using Basic auth with client credentials
client_id = 'your_client_id'
client_secret = 'your_secret'
credentials = base64.b64encode(f'{client_id}:{client_secret}'.encode()).decode()

auth_response = requests.post(
    'https://auth.bsn.cloud/realms/bsncloud/protocol/openid-connect/token',
    data={'grant_type': 'client_credentials'},
    headers={
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': f'Basic {credentials}'
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

Players can be put into "insecured" mode for native extension development. In this mode, `exit` from the shell does NOT reboot — instead it drops to a Linux shell prompt. See [Insecuring a Player for Extension Development](#insecuring-a-player-for-extension-development) below. **Insecuring is irreversible and must never be done to production players.**

---

## Insecuring a Player for Extension Development

"Insecuring" a player permanently disables secure boot so the player will load unsigned OS extensions. **This is a one-way, irreversible operation — it cannot be undone by factory reset, OS update, or any other means. Only do this to a dedicated development unit. Never insecure a production player.**

**When you need this:**
- Building custom native extensions (compiled code that runs as part of the OS, outside of BrightScript or Node.js)
- Accessing the Linux kernel shell directly over SSH
- Deep system-level debugging that the BrightScript shell cannot reach

**When you do NOT need this:**
- BrightScript development
- HTML5/JavaScript/Node.js development
- Standard DWS, SSH, or serial console access

### Critical Caveats

> ⚠️ **This action is irreversible under all circumstances.** Once secure boot is disabled, it cannot be re-enabled — not by factory reset, not by OS update, not by any means. The player will permanently operate in an insecure state. **Do not do this to any player intended for production use.**

> ⚠️ **This voids the player's warranty.** Use a dedicated development unit, never a production device.

> ⚠️ **SSH disables serial console access.** When SSH is enabled, the serial port no longer provides an interactive console. All future console access must happen over SSH.

> ⚠️ **Developer settings (console, script debug) reset on OS update or factory reset.** The insecure state persists, but you will need to re-enable console and script debug after any OS update.

> ⚠️ **The SVC button only works without an SD card.** With an SD card inserted, SVC will not drop into the debugger or shell unless `autorun.brs` contains only `end`.

### Step 1: Enable the BrightSign Console

The console must be enabled before secure boot can be disabled. It enables shell, debugger, and log access over the serial port.

1. Connect your serial cable and open a terminal session (115200 baud, 8N1).
2. **Remove any SD card from the player.**
3. Power the player off.
4. **Hold the SVC button** while applying power. Within 2–5 seconds you will see:
   ```
   Hit key to stop autoboot (CTRL+C): 3
   ```
5. **Press Ctrl-C** within the countdown. You will land at a bootloader prompt — one of:
   ```
   bolt>
   secure>
   insecure>
   ```
6. Enable the console persistently:
   ```
   console on
   reboot
   ```

> Holding SVC enables console for one boot only. `console on` + `reboot` makes it permanent until `console off` is run or a factory reset is performed.

### Step 2: Disable Secure Boot

1. With **no SD card inserted**, power cycle while holding SVC.
2. Press **Ctrl-C** at the countdown.
3. At the bootloader prompt, try the primary command (use whichever does not error):
   ```
   disable_secure_boot
   ```
   or
   ```
   set env insecure
   ```
4. Confirm the irreversible action when prompted.
5. Reboot:
   ```
   reboot
   ```

**Fallback** — if the above commands error, use the environment variable approach:
```
setenv SECURE_CHECKS 0
saveenv
boot
```

### Step 3: Enable the BrightScript Debugger

1. Allow the player to boot fully with **no SD card inserted**. Wait 30–60 seconds after the splash screen.
2. Give a single firm press of the **SVC button** (do not hold). You should land at:
   ```
   BrightSign>
   ```
   If you land in a debugger prompt instead, type `exit` first.
3. Enable script debug:
   ```
   script debug on
   reboot
   ```

### Step 4: Verify Insecure Status

With the player booted and an SD card with an `autorun.brs` inserted, connect via serial or SSH and walk down through each shell layer by typing `exit` at each prompt:

1. Connect to the player over serial or SSH. You will see BrightScript output in the console as your application runs.
2. Press **Ctrl-C** to interrupt execution. You will be dropped into the BrightScript debugger:
   ```
   BrightScript Debugger>
   ```
3. Type `exit` to leave the debugger. You will be dropped into the BrightSign shell:
   ```
   BrightSign>
   ```
4. Type `exit` again. On a secure player this reboots the device. On an insecure player it drops you into the Linux root shell:
   ```
   #
   ```
   A root shell prompt confirms the player is insecure. ✅

If the player reboots at step 4 instead of dropping to a root shell, revisit Step 2 using the `setenv SECURE_CHECKS 0` fallback.

### Development Mode autorun.brs

Once insecured, use this `autorun.brs` to configure a player for development in a single boot. It enables all the tools you need — DWS (unauthenticated), SSH, BrightScript debug, curl debug, and Prometheus metrics — then displays a message prompting for a manual reboot to apply registry changes.

```brightscript
Sub Main()
    ' Enable BrightScript debug mode
    regB = CreateObject("roRegistrySection", "brightscript")
    regB.Write("debug", "1")
    regB.Flush()

    reg = CreateObject("roRegistrySection", "networking")
    reg.Write("bbhf", "on")
    ' Enable Local DWS
    reg.Write("dwse", "yes")
    ' Enable curl verbose logging for HTTP debugging
    reg.Write("curl_debug", "1")
    ' Expose Prometheus node exporter for metrics scraping
    reg.Write("prometheus-node-exporter-port", "9100")
    ' Enable SSH on port 22
    reg.Write("ssh", "22")
    ' Maximum telnet log verbosity
    reg.Write("telnet_log_level", "7")
    reg.Flush()

    ' Open DWS on port 80 with no authentication
    CreateObject("roNetworkConfiguration", 0).SetupDWS({port: "80", open: "none"})

    ' Set SSH/shell login password to empty
    n = CreateObject("roNetworkConfiguration", 0)
    n.SetLoginPassword("none")
    n.Apply()

    ShowMessage("Setup complete -- manually reboot the player to apply settings")

    sleep(50000)
End Sub

Sub ShowMessage(msg)
    gaa = GetGlobalAA()

    videoMode = CreateObject("roVideoMode")
    resX = videoMode.GetResX()
    resY = videoMode.GetResY()
    videoMode = invalid

    r = CreateObject("roRectangle", 0, resY / 2 - resY / 64, resX, resY / 32)

    twParams = CreateObject("roAssociativeArray")
    twParams.LineCount = 1
    twParams.TextMode = 2
    twParams.Rotation = 0
    twParams.Alignment = 1

    gaa.tw = CreateObject("roTextWidget", r, 1, 2, twParams)
    gaa.tw.PushString(msg)
    gaa.tw.Show()

    print msg
End Sub
```

> ⚠️ **Development only.** This autorun sets DWS to unauthenticated and SSH to no password. It is intended exclusively for isolated development networks — never run it on production hardware or shared infrastructure. Remember: the insecure state of the player is permanent and cannot be reversed.

After running this autorun and manually rebooting, the player will have:
- Local DWS accessible at `http://<player-ip>/` with no login
- SSH accessible at port 22 with no password
- BrightScript debug and verbose logging enabled
- Prometheus metrics at port 9100

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

### Insecuring a Player

**No output in the terminal after holding SVC and applying power**
- Verify the cable is properly connected at both ends
- Confirm the correct TTY device is selected (`ls /dev/tty*`; unplug and re-run to identify which device disappears)
- Confirm terminal settings match: 115200 baud, 8N1
- Check for counterfeit or incompatible USB-to-serial chipsets

**"Resource busy" error on macOS**
```bash
lsof | grep 'usbserial'
sudo kill -9 <PID>
```
Then re-open your terminal session.

**Ctrl-C window missed / cannot interrupt boot**
- Power cycle and retry. The countdown is short — have your finger on Ctrl-C before applying power.

**`exit` at the BrightSign prompt reboots the player instead of dropping to a Linux shell**
- The player is not yet fully insecure. Revisit Step 2 of the insecuring process and use the `setenv SECURE_CHECKS 0` / `saveenv` / `boot` fallback method.

**SVC button press does nothing**
- Confirm no SD card is inserted
- Confirm you are pressing SVC (not the adjacent Reset button)
- Do not hold SVC longer than necessary — holding 15 or more seconds may trigger rescue mode, indicated by a continuously flashing ERR LED

**Player enters rescue mode (ERR LED flashing continuously)**
- The ERR LED will flash for approximately 15 minutes before the player reboots automatically. If an OS update is present on a storage device, it will be applied during this window.

**Serial console output disappears after enabling SSH**
- This is expected. SSH disables the interactive serial console. To re-enable serial output alongside SSH/telnet:
  ```brightscript
  reg = CreateObject("roRegistrySection", "networking")
  reg.Write("serial_with_telnet", "1")
  reg.Flush()
  ```
  Note: With this enabled, interaction with serial devices via `roSerialPort` will become unreliable.

---

## Next Steps

Now that your development environment is set up, continue with:

- [Your First BrightScript Application](02-first-brightscript-application.md) - Create a video player
- [Your First HTML5 Application](03-first-html5-application.md) - Build a web-based display

---

[← Back to How-To Articles](README.md) | [Next: Your First BrightScript Application →](02-first-brightscript-application.md)
