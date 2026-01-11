# Setting Up BSN.cloud

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide walks you through connecting your BrightSign player to BSN.cloud, BrightSign's cloud management platform. BSN.cloud provides centralized device management, content deployment, remote monitoring, and enterprise-scale control over your digital signage network.

### What You'll Learn

- Creating a BSN.cloud account and network
- Registering players with BSN.cloud
- Automatic provisioning methods (mDNS, DHCP Option 43)
- Using Remote DWS for cloud-based management
- Deploying content through BSN.cloud
- Monitoring player status and diagnostics

### BSN.cloud Benefits

| Feature | Description |
|---------|-------------|
| **Remote Management** | Control players anywhere via web interface |
| **Content Deployment** | Push content updates without physical access |
| **Device Monitoring** | Real-time status, health checks, diagnostics |
| **Scheduling** | Time-based content scheduling |
| **Grouping** | Organize players by location, purpose, or network |
| **REST APIs** | Programmatic control for custom integrations |

---

## Prerequisites

- BrightSign player with network connectivity
- Email address for BSN.cloud account
- Basic understanding of networking (DHCP, DNS)
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))

---

## Part 1: BSN.cloud Account Setup

### Step 1: Create a BSN.cloud Account

1. Navigate to [BSN.cloud](https://www.bsn.cloud)
2. Click "Sign Up" or "Create Account"
3. Enter your email address and create a password
4. Verify your email address
5. Complete your profile information

### Step 2: Create a Network

A network is a logical grouping for your players and content:

1. Log in to BSN.cloud
2. Navigate to **Admin** > **Networks**
3. Click **Create Network**
4. Enter a network name (e.g., "Retail Stores - West Region")
5. Select your subscription tier
6. Click **Create**

Your network is now ready for player registration.

---

## Part 2: Manual Player Registration

The simplest way to register a player with BSN.cloud.

### Step 1: Connect Player to Network

1. Connect your BrightSign player to Ethernet or configure WiFi
2. Power on the player
3. Wait for the player to complete initial boot

### Step 2: Access Local DWS

1. Find the player's IP address:
   - Check your router's DHCP client list, or
   - Use the player's mDNS address: `http://BrightSign-SERIALNUMBER.local`

2. Open a browser and navigate to `http://PLAYER_IP_ADDRESS`

3. Log in with default credentials:
   - Username: `admin`
   - Password: Player's serial number (found on device label)

### Step 3: Register with BSN.cloud

1. In Local DWS, go to **Setup** > **Cloud Services**
2. Select **BSN.cloud**
3. Enter your BSN.cloud credentials
4. Select the network to join
5. Click **Register**

The player will:
- Generate a registration token
- Contact BSN.cloud authentication services
- Complete OAuth token exchange
- Establish WebSocket connection for real-time communication

### Step 4: Verify Registration

In BSN.cloud:
1. Navigate to **Devices** > **Players**
2. Your player should appear with status "Online"
3. Click the player to view details and diagnostics

---

## Part 3: Automatic Provisioning

For deploying multiple players efficiently, use automatic provisioning.

### Method 1: mDNS Provisioning

mDNS (Multicast DNS) provisioning works on local networks that support multicast.

#### How It Works

BrightSign players automatically look for a server at `http://brightsign-b-deploy.local/` during boot. If found, they download provisioning configuration.

#### Setup mDNS Server

1. **Install Avahi** (Linux) or Bonjour (macOS/Windows):

   ```bash
   # Ubuntu/Debian
   sudo apt-get install avahi-daemon

   # Configure hostname
   sudo hostnamectl set-hostname brightsign-b-deploy
   ```

2. **Create provisioning endpoint**:

   Host a web server with your provisioning files at the mDNS address.

3. **Create recovery script**:

   ```brightscript
   ' recovery.brs - Provisioning script
   Sub Main()
       ' Configure BSN.cloud registration
       reg = CreateObject("roRegistrySection", "networking")
       reg.Write("nu", "https://api.bsn.cloud/...")  ' Network update URL
       reg.Flush()

       ' Download and install autorun
       DownloadAutorun()

       ' Reboot to apply
       device = CreateObject("roDeviceInfo")
       device.Reboot()
   End Sub
   ```

#### Player-Specific mDNS

Each player has its own mDNS address for direct access:

```
http://BrightSign-SERIALNUMBER.local
```

Replace `SERIALNUMBER` with your player's actual serial number.

### Method 2: DHCP Option 43 Provisioning

For enterprise networks, DHCP Option 43 provides automatic provisioning during DHCP handshake.

#### How It Works

1. Player sends DHCP request with Option 60 (Vendor Class): `BrightSign MODEL`
2. DHCP server recognizes BrightSign and responds with Option 43
3. Option 43 contains the recovery URL encoded in TLV format
4. Player downloads provisioning from that URL

#### Configure DHCP Server (ISC DHCP)

```conf
# /etc/dhcp/dhcpd.conf

# Define BrightSign option space
option space BrightSign code width 1 length width 1 hash size 7;
option BrightSign.recovery code 85 = text;

# Match BrightSign players
class "BrightSign-Players" {
    match if substring(option vendor-class-identifier, 0, 10) = "BrightSign";
}

# Subnet configuration
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers 192.168.1.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;

    pool {
        allow members of "BrightSign-Players";
        range 192.168.1.50 192.168.1.99;

        # Provide recovery URL via Option 43
        vendor-option-space BrightSign;
        option BrightSign.recovery "https://provision.example.com/recovery/";
    }
}
```

#### Configure dnsmasq

```conf
# Simpler configuration for dnsmasq
dhcp-option=vendor:BrightSign,85,"https://provision.example.com/recovery/"
```

#### Option 43 Encoder

Generate the TLV-encoded Option 43 value:

```html
<!DOCTYPE html>
<html>
<head>
    <title>BrightSign Option 43 Encoder</title>
</head>
<body>
    <h1>BrightSign Option 43 Recovery URL Encoder</h1>
    <input type="text" id="url" size="80" placeholder="https://provision.example.com/recovery/">
    <button onclick="encode()">Encode</button>
    <pre id="output"></pre>

    <script>
    function encode() {
        const url = document.getElementById('url').value;
        const output = document.getElementById('output');

        // Build TLV: Tag 85 (0x55) + Length + Value
        const data = [0x55, url.length];

        for (let i = 0; i < url.length; i++) {
            data.push(url.charCodeAt(i));
        }

        // Convert to hex string
        const hex = data.map(b => b.toString(16).padStart(2, '0').toUpperCase()).join('');

        output.textContent = `option 43 hex ${hex}`;
    }
    </script>
</body>
</html>
```

Example output for `https://example.com/`:
```
option 43 hex 551468747470733a2f2f6578616d706c652e636f6d2f
```

---

## Part 4: Using Remote DWS

Remote DWS (Device Web Server) allows cloud-based access to player settings through BSN.cloud.

### Accessing Remote DWS

1. Log in to BSN.cloud
2. Navigate to **Devices** > **Players**
3. Click on your player
4. Click **Remote DWS** or **Device Settings**

### Remote DWS APIs

For programmatic access, use the Remote DWS REST APIs:

**Base URL**: `https://api.bsn.cloud/2022/06/REST`

#### Authentication

```javascript
// Get OAuth token
async function getToken(username, password) {
    const response = await fetch('https://api.bsn.cloud/2022/06/REST/Token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'password',
            username: username,
            password: password,
            client_id: 'your-client-id'
        })
    });

    const data = await response.json();
    return data.access_token;
}
```

#### List Devices

```javascript
async function listDevices(token, networkId) {
    const response = await fetch(
        `https://api.bsn.cloud/2022/06/REST/Devices/?networkId=${networkId}`,
        {
            headers: { 'Authorization': `Bearer ${token}` }
        }
    );

    return await response.json();
}
```

#### Send Command to Device

```javascript
async function rebootDevice(token, deviceId) {
    const response = await fetch(
        `https://api.bsn.cloud/2022/06/REST/Devices/${deviceId}/Reboot`,
        {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` }
        }
    );

    return response.ok;
}
```

### BrightScript: Remote DWS Integration

```brightscript
Sub RegisterWithBsnCloud()
    ' Configuration
    bsnCloudUrl = "https://api.bsn.cloud"
    registrationToken = "your-registration-token"

    ' Create device info
    deviceInfo = CreateObject("roDeviceInfo")
    serialNumber = deviceInfo.GetDeviceUniqueId()
    model = deviceInfo.GetModel()
    firmwareVersion = deviceInfo.GetVersion()

    ' Registration payload
    payload = {
        serialNumber: serialNumber,
        model: model,
        firmwareVersion: firmwareVersion,
        registrationToken: registrationToken
    }

    ' Make registration request
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(bsnCloudUrl + "/registration/v1/devices")
    urlTransfer.AddHeader("Content-Type", "application/json")

    response = urlTransfer.PostFromString(formatJson(payload))

    if urlTransfer.GetResponseCode() = 200 then
        result = ParseJson(response)
        print "Registration successful"
        print "Device ID: "; result.deviceId

        ' Store credentials
        StoreCloudCredentials(result)
    else
        print "Registration failed: "; urlTransfer.GetResponseCode()
    end if
End Sub

Sub StoreCloudCredentials(credentials as Object)
    reg = CreateObject("roRegistrySection", "bsncloud")
    reg.Write("deviceId", credentials.deviceId)
    reg.Write("accessToken", credentials.accessToken)
    reg.Write("refreshToken", credentials.refreshToken)
    reg.Flush()
End Sub
```

---

## Part 5: Content Deployment

### Using BSN.cloud Web Interface

1. **Upload Content**:
   - Navigate to **Library** > **Media**
   - Click **Upload** and select files
   - Wait for processing to complete

2. **Create Presentation**:
   - Go to **Presentations**
   - Click **Create Presentation**
   - Add media to timeline
   - Configure transitions and timing

3. **Publish to Players**:
   - Select your presentation
   - Click **Publish**
   - Choose target players or groups
   - Confirm deployment

### Using Sync Spec for Custom Deployment

For programmatic content deployment, use sync specs:

```json
{
    "meta": {
        "client": "custom-cms",
        "version": "1.0"
    },
    "files": {
        "download": [
            {
                "name": "video1.mp4",
                "link": "https://cdn.example.com/content/video1.mp4",
                "size": 52428800,
                "hash": "sha1:abc123..."
            },
            {
                "name": "playlist.json",
                "link": "https://cdn.example.com/content/playlist.json",
                "size": 1024,
                "hash": "sha1:def456..."
            }
        ],
        "delete": [
            "old-video.mp4"
        ]
    }
}
```

Configure player to use sync spec:

```brightscript
Sub ConfigureSyncSpec()
    reg = CreateObject("roRegistrySection", "networking")
    reg.Write("nu", "https://content.example.com/sync-spec.json")
    reg.Flush()
End Sub
```

---

## Part 6: Monitoring and Diagnostics

### Player Status Monitoring

BSN.cloud provides real-time monitoring:

| Metric | Description |
|--------|-------------|
| Online/Offline | WebSocket connection status |
| Last Check-in | Time since last communication |
| Storage Usage | SD card space used/available |
| Network Stats | IP address, connection type |
| Firmware Version | Current OS version |
| Temperature | Device temperature (if supported) |

### Accessing Logs

Through BSN.cloud:
1. Select your player
2. Click **Diagnostics** > **Logs**
3. View or download log files

Through Remote DWS API:

```javascript
async function getDeviceLogs(token, deviceId) {
    const response = await fetch(
        `https://api.bsn.cloud/2022/06/REST/Devices/${deviceId}/Logs`,
        {
            headers: { 'Authorization': `Bearer ${token}` }
        }
    );

    return await response.json();
}
```

### Health Checks

Implement local health reporting:

```brightscript
Sub ReportHealth()
    deviceInfo = CreateObject("roDeviceInfo")
    storageInfo = CreateObject("roStorageInfo", "SD:")

    health = {
        timestamp: GetCurrentTimestamp(),
        serialNumber: deviceInfo.GetDeviceUniqueId(),
        uptime: deviceInfo.GetBootCount(),
        freeStorage: storageInfo.GetFreeInMegabytes(),
        totalStorage: storageInfo.GetSizeInMegabytes(),
        temperature: deviceInfo.GetTemperature(),
        firmwareVersion: deviceInfo.GetVersion()
    }

    ' Report to BSN.cloud via WebSocket or REST
    SendHealthReport(health)
End Sub
```

---

## Complete Example: Auto-Provisioning Setup

A complete provisioning server setup:

### server.js (Node.js Provisioning Server)

```javascript
const express = require('express');
const app = express();

// Provisioning configuration
const config = {
    bsnCloudNetwork: 'your-network-id',
    contentServer: 'https://content.example.com',
    firmwareServer: 'https://firmware.example.com'
};

// Serve recovery script
app.get('/recovery.brs', (req, res) => {
    const script = `
' Auto-provisioning recovery script
Sub Main()
    print "Starting auto-provisioning..."

    ' Configure BSN.cloud
    ConfigureBsnCloud()

    ' Download initial content
    DownloadInitialContent()

    ' Reboot to start application
    RebootDevice()
End Sub

Sub ConfigureBsnCloud()
    reg = CreateObject("roRegistrySection", "networking")
    reg.Write("nu", "${config.contentServer}/sync-spec.json")
    reg.Flush()

    print "BSN.cloud configuration complete"
End Sub

Sub DownloadInitialContent()
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl("${config.contentServer}/autorun.brs")
    urlTransfer.GetToFile("SD:/autorun.brs")
    print "Initial content downloaded"
End Sub

Sub RebootDevice()
    print "Rebooting..."
    sleep(2000)
    device = CreateObject("roDeviceInfo")
    device.Reboot()
End Sub
`;
    res.type('text/plain').send(script);
});

// Serve sync spec
app.get('/sync-spec.json', (req, res) => {
    res.json({
        meta: { client: 'auto-provision', version: '1.0' },
        files: {
            download: [
                {
                    name: 'autorun.brs',
                    link: `${config.contentServer}/autorun.brs`,
                    size: 2048
                }
            ]
        }
    });
});

app.listen(80, () => {
    console.log('Provisioning server running on port 80');
});
```

---

## Best Practices

### Do

- **Use automatic provisioning** for large deployments
- **Implement health monitoring** for proactive maintenance
- **Use sync specs** for reliable content updates
- **Store credentials securely** using encrypted registry
- **Test provisioning** on a few devices before mass deployment
- **Document your network topology** for troubleshooting
- **Use player groups** for organized management

### Don't

- **Don't expose Local DWS** to public networks without authentication
- **Don't hardcode credentials** in scripts
- **Don't skip firmware updates** - keep players current
- **Don't ignore offline alerts** - investigate promptly
- **Don't use weak passwords** for DWS access

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Player won't register | Network/firewall blocking | Check ports 443, 80; verify DNS |
| mDNS not working | Multicast disabled | Enable multicast on network switches |
| Option 43 not received | DHCP misconfigured | Verify DHCP class match and TLV encoding |
| Player shows offline | WebSocket connection lost | Check network stability, firewall rules |
| Content not updating | Sync spec URL wrong | Verify `nu` registry key |

### Network Requirements

Ensure these endpoints are accessible:

| Endpoint | Purpose |
|----------|---------|
| `*.bsn.cloud` | BSN.cloud services |
| `*.brightsignnetwork.com` | Legacy services, diagnostics |
| `time.brightsignnetwork.com` | NTP time sync |

---

## Exercises

1. **Manual Registration**: Register a player with BSN.cloud using Local DWS

2. **mDNS Provisioning**: Set up an mDNS provisioning server and register 3 players automatically

3. **Remote Management**: Use the BSN.cloud REST API to list devices and send a reboot command

4. **Content Deployment**: Create a sync spec and deploy content to multiple players

---

## Next Steps

- [Implementing Live Data Feeds](11-implementing-live-data-feeds.md) - Display real-time information
- [Fetching Remote Content](08-fetching-remote-content.md) - Download and cache content
- [Integrating with REST APIs](09-integrating-rest-apis.md) - Consume external APIs

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
