# Secure Deployment Practices

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers implementing security best practices for BrightSign deployments. Security is critical for production digital signage to prevent unauthorized access, content tampering, and system compromise. This article provides practical strategies for securing players, content, and network communications.

### What You'll Learn

- BrightSign's built-in security features
- Development vs production configuration
- Content security and integrity
- Network security best practices
- BSN.cloud security integration
- Extension security
- Physical security considerations
- Secure provisioning methods

### Security Threat Model

| Threat | Impact | Mitigation |
|--------|--------|------------|
| **Unauthorized access** | Content tampering | Disable debug interfaces, strong passwords |
| **Network attacks** | Data interception | HTTPS, VPN, firewall |
| **Physical tampering** | Device compromise | Lockable enclosures, tamper detection |
| **Malicious content** | System exploit | Content validation, signed packages |
| **Data breaches** | Privacy violation | Encryption, access control |

---

## Prerequisites

- Understanding of security principles
- BrightSign player for deployment
- Network security knowledge
- BSN.cloud account (for cloud features)
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))

---

## Part 1: BrightSign Security Features

### Built-in Security

**Cryptographically Signed Firmware:**
- Players only execute BrightSign-signed firmware
- Prevents unauthorized firmware modifications
- Verified during boot process

**Read-Only Filesystem:**
- Root filesystem is read-only during normal operation
- Prevents runtime system modifications
- Only SD card and specific directories are writable

**Secure Boot:**
- Hardware root of trust
- Chain of trust from bootloader through kernel
- Available on select models

---

## Part 2: Development vs Production Configuration

### Disable Debug Interfaces in Production

**Web Inspector (Chrome DevTools):**

```brightscript
' DEVELOPMENT: Inspector enabled
config = {
    url: "file:///sd:/app/index.html",
    inspector_server: {
        port: 2999  ' INSECURE: Remove in production
    }
}

' PRODUCTION: Inspector disabled
config = {
    url: "file:///sd:/app/index.html"
    ' No inspector_server - secure
}

htmlWidget = CreateObject("roHtmlWidget", rect, config)
```

**Disable SSH/Telnet:**

```brightscript
Sub SecureProductionPlayer()
    reg = CreateObject("roRegistrySection", "networking")

    ' Disable SSH
    reg.Write("ssh", "")
    reg.Delete("ssh")

    ' Disable Telnet
    reg.Write("telnet", "")
    reg.Delete("telnet")

    ' Disable Local DWS (optional, reduces attack surface)
    reg.Write("dwsEnabled", "0")

    reg.Flush()

    print "Debug interfaces disabled"
End Sub
```

**Use strong DWS password:**

```brightscript
Sub ConfigureDWSPassword()
    reg = CreateObject("roRegistrySection", "networking")

    ' Change from default (serial number)
    reg.Write("dwsPassword", "strong-random-password-here")
    reg.Flush()

    print "DWS password updated"
End Sub
```

---

## Part 3: Content Security

### HTTPS for Content Delivery

**Always use HTTPS for remote content:**

```brightscript
' INSECURE: HTTP
urlTransfer.SetUrl("http://content.example.com/video.mp4")

' SECURE: HTTPS
urlTransfer.SetUrl("https://content.example.com/video.mp4")

' Enable certificate verification
urlTransfer.EnablePeerVerification(true)
urlTransfer.EnableHostVerification(true)
```

### Content Validation with Checksums

```brightscript
Function SecureDownload(url as String, destination as String, expectedHash as String) as Boolean
    ' Download file
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(url)
    urlTransfer.EnablePeerVerification(true)

    if urlTransfer.GetToFile(destination) <> 200 then
        print "Download failed"
        return false
    end if

    ' Calculate hash
    digest = CreateObject("roMessageDigest")
    digest.SetAlgorithm("sha256")

    fs = CreateObject("roFileSystem")
    file = fs.OpenInputFile(destination)

    while true
        chunk = file.Read(65536)
        if chunk.Count() = 0 then exit while
        digest.Update(chunk)
    end while

    actualHash = LCase(digest.Final())

    ' Verify hash
    if actualHash = LCase(expectedHash) then
        print "Content verified"
        return true
    else
        print "SECURITY ALERT: Hash mismatch!"
        print "Expected: "; expectedHash
        print "Actual: "; actualHash

        ' Delete potentially malicious file
        fs.Delete(destination)
        return false
    end if
End Function

' Usage with manifest
manifest = {
    files: [
        {
            url: "https://cdn.example.com/video.mp4",
            path: "SD:/content/video.mp4",
            sha256: "abc123..."
        }
    ]
}

for each file in manifest.files
    SecureDownload(file.url, file.path, file.sha256)
end for
```

### Input Sanitization

**Prevent XSS in HTML5 applications:**

```javascript
// WRONG: Direct HTML injection (XSS vulnerability)
element.innerHTML = userInput;

// CORRECT: Sanitize input
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

element.innerHTML = escapeHtml(userInput);

// Or use textContent
element.textContent = userInput;
```

**Validate API responses:**

```javascript
async function fetchSecurely(url) {
    const response = await fetch(url);
    const data = await response.json();

    // Validate structure
    if (!data || typeof data !== 'object') {
        throw new Error('Invalid response format');
    }

    // Validate required fields
    if (!data.content || !data.signature) {
        throw new Error('Missing required fields');
    }

    // Verify signature (if implementing content signing)
    if (!verifySignature(data.content, data.signature)) {
        throw new Error('Signature verification failed');
    }

    return data.content;
}
```

---

## Part 4: Network Security

### Firewall Configuration

**Minimum required outbound ports:**
```
Port 443 (HTTPS): BSN.cloud, content delivery
Port 80 (HTTP): Legacy services, diagnostics
Port 123 (NTP): Time synchronization
```

**Restrict inbound access:**
```
Block all inbound except:
- Port 22 (SSH): Only from management network
- Port 80 (DWS): Only from management network
- VPN for remote access
```

### VPN Integration

```brightscript
Sub ConfigureVPN()
    ' Configure VPN via registry
    reg = CreateObject("roRegistrySection", "networking")

    ' OpenVPN configuration
    reg.Write("vpn", "openvpn")
    reg.Write("vpn_config", ReadAsciiFile("SD:/vpn/client.ovpn"))

    reg.Flush()

    print "VPN configured"
End Sub
```

### Certificate Management

**Install custom CA certificates:**

```bash
# Copy certificate to player
scp ca-bundle.crt root@192.168.1.100:/storage/sd/

# Install certificate
ssh root@192.168.1.100
mkdir -p /etc/ssl/certs
cp /storage/sd/ca-bundle.crt /etc/ssl/certs/
update-ca-certificates
```

**Use certificates in BrightScript:**

```brightscript
urlTransfer = CreateObject("roUrlTransfer")
urlTransfer.SetUrl("https://api.example.com/data")

' Use custom CA bundle
urlTransfer.SetCertificatesFile("SD:/certs/ca-bundle.crt")

' Enable verification
urlTransfer.EnablePeerVerification(true)
urlTransfer.EnableHostVerification(true)
```

---

## Part 5: BSN.cloud Security

### OAuth2 Authentication

**Secure token management:**

```brightscript
Function GetSecureToken(username as String, password as String) as Object
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl("https://api.bsn.cloud/2022/06/REST/Token")
    urlTransfer.EnablePeerVerification(true)

    ' Build secure request
    payload = {
        grant_type: "password",
        username: username,
        password: password,
        client_id: "your-client-id"
    }

    response = urlTransfer.PostFromString(formatJson(payload))

    if urlTransfer.GetResponseCode() = 200 then
        tokenData = ParseJson(response)

        ' Store in secure registry
        reg = CreateObject("roRegistrySection", "bsncloud")
        reg.Write("accessToken", tokenData.access_token)
        reg.Write("refreshToken", tokenData.refresh_token)
        reg.Write("expiresAt", Str(GetExpiryTime(tokenData.expires_in)))
        reg.Flush()

        return tokenData
    end if

    return invalid
End Function

Function GetExpiryTime(expiresIn as Integer) as Integer
    dateTime = CreateObject("roDateTime")
    return dateTime.AsSeconds() + expiresIn
End Function
```

**Never log credentials:**

```brightscript
' WRONG: Logs password
print "Logging in with "; username; " / "; password

' CORRECT: Don't log sensitive data
print "Authenticating user: "; username
```

### API Key Protection

**Store API keys in registry:**

```brightscript
Function GetAPIKey() as String
    reg = CreateObject("roRegistrySection", "credentials")
    apiKey = reg.Read("apiKey")

    if apiKey = "" then
        print "ERROR: API key not configured"
        return ""
    end if

    return apiKey
End Function

Sub SetAPIKey(key as String)
    reg = CreateObject("roRegistrySection", "credentials")
    reg.Write("apiKey", key)
    reg.Flush()
End Sub

' Use in requests
apiKey = GetAPIKey()
urlTransfer.AddHeader("X-API-Key", apiKey)
```

**Never hardcode in source:**

```brightscript
' WRONG: Hardcoded credential
apiKey = "sk_live_abc123xyz"  ' INSECURE!

' CORRECT: Load from registry
apiKey = GetAPIKey()
```

---

## Part 6: Extension Security

### Production Signing

**All extensions for secure players must be signed:**

1. Develop extension with unique name
2. Test on unsecured player
3. Submit .sqsh to BrightSign for signing
4. Deploy .bsfw (signed) to production

**Extension best practices:**

```bash
#!/bin/sh
# Secure extension init script

# Run as unprivileged user (if supported)
# Validate inputs
# Log security events
# Limit network exposure

start() {
    # Check if already running
    if [ -f "$PID_FILE" ]; then
        echo "Extension already running"
        return 1
    fi

    # Validate configuration
    if [ ! -f "$CONFIG_FILE" ]; then
        logger -t extension "ERROR: Config file missing"
        return 1
    fi

    # Start with limited permissions
    logger -t extension "Starting extension"
    $APP_BINARY &
    echo $! > $PID_FILE
}
```

### Minimize Attack Surface

```typescript
// Limit exposed endpoints
const server = http.createServer((req, res) => {
    // Whitelist allowed paths
    const allowedPaths = ['/health', '/metrics'];

    if (!allowedPaths.includes(req.url)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }

    // Validate origin (if needed)
    const origin = req.headers['origin'];
    if (origin && !isAllowedOrigin(origin)) {
        res.writeHead(403);
        res.end('Forbidden origin');
        return;
    }

    // Handle request...
});

function isAllowedOrigin(origin) {
    const allowed = ['http://localhost', 'https://app.example.com'];
    return allowed.includes(origin);
}
```

---

## Part 7: Physical Security

### SD Card Security

**Detect SD card removal:**

```brightscript
Sub MonitorSDCard()
    msgPort = CreateObject("roMessagePort")
    hotplug = CreateObject("roStorageHotplug")
    hotplug.SetPort(msgPort)

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roStorageHotplugEvent" then
            if msg.GetEvent() = "removed" and msg.GetPath() = "SD:" then
                print "SECURITY ALERT: SD card removed!"

                ' Stop playback
                ' Log event
                ' Alert monitoring system

                ' Optionally lock player
                LockPlayer()
            end if
        end if
    end while
End Sub

Sub LockPlayer()
    ' Display warning
    ' Disable functionality until authorized
    print "Player locked due to security event"
End Sub
```

### USB Port Access Control

**Disable USB in kiosk mode:**

```brightscript
Sub DisableUSBStorage()
    ' Disable USB mass storage mounting
    reg = CreateObject("roRegistrySection", "system")
    reg.Write("usbStorageEnabled", "0")
    reg.Flush()

    print "USB storage disabled"
End Sub
```

### GPIO Security

**Secure GPIO-controlled functions:**

```brightscript
Sub SecureGPIOControl()
    gpio = CreateObject("roControlPort", "BrightSign")
    msgPort = CreateObject("roMessagePort")
    gpio.SetPort(msgPort)

    ' Configure button input with security check
    gpio.EnableInput(0)

    ' Require authentication sequence
    authSequence = [0, 1, 0, 2]  ' Button sequence
    inputSequence = []

    while true
        msg = wait(30000, msgPort)  ' 30s timeout

        if msg = invalid then
            ' Timeout - clear sequence
            inputSequence.Clear()
            print "Auth timeout"
        else if type(msg) = "roControlDown" then
            buttonId = msg.GetInt()
            inputSequence.Push(buttonId)

            if inputSequence.Count() = authSequence.Count() then
                if SequencesMatch(inputSequence, authSequence) then
                    print "Authentication successful"
                    UnlockAdminFunctions()
                else
                    print "Authentication failed"
                end if

                inputSequence.Clear()
            end if
        end if
    end while
End Sub

Function SequencesMatch(a as Object, b as Object) as Boolean
    if a.Count() <> b.Count() then return false

    for i = 0 to a.Count() - 1
        if a[i] <> b[i] then return false
    end for

    return true
End Function
```

---

## Part 8: Secure Provisioning

### Automatic Provisioning Security

**DHCP Option 43 with HTTPS:**

```conf
# /etc/dhcp/dhcpd.conf
# Use HTTPS for recovery URL

option space BrightSign code width 1 length width 1 hash size 7;
option BrightSign.recovery code 85 = text;

pool {
    allow members of "BrightSign-Players";
    vendor-option-space BrightSign;
    option BrightSign.recovery "https://provision.example.com/recovery/";
    # Use HTTPS, not HTTP
}
```

**Validate provisioning source:**

```brightscript
' recovery.brs - Secure provisioning script
Sub Main()
    print "Secure provisioning starting..."

    ' Verify we're on expected network
    if not VerifyNetwork() then
        print "SECURITY: Unexpected network, aborting"
        return
    end if

    ' Download configuration over HTTPS
    config = DownloadConfig("https://provision.example.com/config.json")

    if config <> invalid and VerifyConfigSignature(config) then
        ApplyConfiguration(config)
    else
        print "SECURITY: Invalid configuration"
        return
    end if

    ' Download and verify application
    DownloadApplication()

    ' Reboot
    CreateObject("roDeviceInfo").Reboot()
End Sub

Function VerifyNetwork() as Boolean
    nc = CreateObject("roNetworkConfiguration", 0)
    currentIP = nc.GetCurrentConfig().ip4_address

    ' Check if on trusted network (example: 10.x.x.x)
    return Left(currentIP, 3) = "10."
End Function

Function VerifyConfigSignature(config as Object) as Boolean
    ' Implement signature verification
    ' Use public key to verify config wasn't tampered
    return true  ' Placeholder
End Function
```

---

## Part 9: Network Security Best Practices

### Certificate Pinning

**Pin server certificates:**

```javascript
// Certificate pinning for critical APIs
const trustedCertificates = [
    '5F:3B:8C:F8:81:...', // SHA-256 fingerprint
];

async function fetchWithPinning(url) {
    const response = await fetch(url, {
        // Note: Certificate pinning requires native implementation
        // This is conceptual
    });

    // Verify certificate fingerprint
    // Implementation would require extension or native code

    return response;
}
```

### Rate Limiting

**Prevent abuse:**

```javascript
class RateLimiter {
    constructor(maxRequests, timeWindowMs) {
        this.maxRequests = maxRequests;
        this.timeWindowMs = timeWindowMs;
        this.requests = [];
    }

    allowRequest(identifier) {
        const now = Date.now();

        // Remove old requests outside time window
        this.requests = this.requests.filter(
            req => now - req.timestamp < this.timeWindowMs
        );

        // Count requests from this identifier
        const count = this.requests.filter(
            req => req.identifier === identifier
        ).length;

        if (count >= this.maxRequests) {
            console.warn(`Rate limit exceeded for ${identifier}`);
            return false;
        }

        // Log request
        this.requests.push({
            identifier: identifier,
            timestamp: now
        });

        return true;
    }
}

// Usage
const limiter = new RateLimiter(10, 60000);  // 10 requests per minute

async function handleAPIRequest(userId) {
    if (!limiter.allowRequest(userId)) {
        throw new Error('Rate limit exceeded');
    }

    // Process request...
}
```

---

## Complete Example: Secure Kiosk Deployment

### autorun.brs

```brightscript
Sub Main()
    print "Secure Kiosk Application Starting"

    ' Apply security hardening
    SecurePlayer()

    ' Set video mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Create secure HTML widget
    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
    config = {
        url: "file:///sd:/kiosk/index.html",
        mouse_enabled: false,
        ' NO inspector_server in production
        storage_path: "SD:/kiosk-storage",
        storage_quota: 10485760  ' 10MB limit
    }

    htmlWidget = CreateObject("roHtmlWidget", rect, config)
    htmlWidget.Show()

    ' Create message port
    msgPort = CreateObject("roMessagePort")
    htmlWidget.SetPort(msgPort)

    ' Inactivity timeout
    inactivityTimer = CreateObject("roTimer")
    inactivityTimer.SetPort(msgPort)
    inactivityTimer.SetElapsed(60, 0)  ' 60 second timeout

    ' Monitor for tampering
    hotplug = CreateObject("roStorageHotplug")
    hotplug.SetPort(msgPort)

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roHtmlWidgetEvent" then
            eventData = msg.GetData()

            if eventData.reason = "message" then
                ' Reset inactivity timer on user interaction
                inactivityTimer.Start()

                ' Validate and handle message
                HandleSecureMessage(eventData.message, htmlWidget)
            end if

        else if type(msg) = "roTimerEvent" then
            ' Timeout - return to attract screen
            print "Inactivity timeout"
            htmlWidget.PostJSMessage({type: "timeout"})
            ClearSensitiveData()

        else if type(msg) = "roStorageHotplugEvent" then
            ' Detect tampering
            if msg.GetEvent() = "removed" then
                print "SECURITY: Storage removed"
                LogSecurityEvent("storage_removed")
                LockKiosk(htmlWidget)
            end if
        end if
    end while
End Sub

Sub SecurePlayer()
    reg = CreateObject("roRegistrySection", "networking")

    ' Disable SSH/Telnet
    reg.Delete("ssh")
    reg.Delete("telnet")

    ' Set strong DWS password
    reg.Write("dwsPassword", GenerateSecurePassword())

    ' Disable unnecessary services
    reg.Write("dwsEnabled", "0")  ' Disable if not needed

    reg.Flush()

    print "Player secured"
End Sub

Function GenerateSecurePassword() as String
    ' Generate random password (simplified)
    deviceInfo = CreateObject("roDeviceInfo")
    seed = deviceInfo.GetDeviceUniqueId() + Str(CreateObject("roDateTime").AsSeconds())

    digest = CreateObject("roMessageDigest")
    digest.SetAlgorithm("sha256")
    digest.Update(CreateObject("roByteArray").FromAsciiString(seed))

    return Left(digest.Final(), 16)
End Function

Sub HandleSecureMessage(message as Object, widget as Object)
    ' Validate message structure
    if message = invalid or message.type = invalid then
        print "Invalid message received"
        return
    end if

    ' Whitelist allowed actions
    allowedTypes = ["navigate", "select", "submit"]

    typeAllowed = false
    for each allowedType in allowedTypes
        if message.type = allowedType then
            typeAllowed = true
            exit for
        end if
    end for

    if not typeAllowed then
        print "Unauthorized action: "; message.type
        LogSecurityEvent("unauthorized_action")
        return
    end if

    ' Process validated message
    print "Processing: "; message.type
End Sub

Sub ClearSensitiveData()
    ' Clear any user-entered data
    print "Clearing sensitive data"
End Sub

Sub LockKiosk(widget as Object)
    widget.PostJSMessage({type: "lock"})
    print "Kiosk locked"
End Sub

Sub LogSecurityEvent(eventType as String)
    ' Log to secure location
    fs = CreateObject("roFileSystem")
    logFile = "SD:/security.log"

    dateTime = CreateObject("roDateTime")
    entry = "[" + dateTime.ToISOString() + "] " + eventType + chr(10)

    ' Append to log
    if fs.Exists(logFile) then
        existing = ReadAsciiFile(logFile)
        WriteAsciiFile(logFile, existing + entry)
    else
        WriteAsciiFile(logFile, entry)
    end if
End Sub
```

---

## Security Audit Checklist

### Pre-Deployment

- [ ] Debug interfaces disabled (SSH, Telnet, Web Inspector)
- [ ] Strong DWS password set (not default)
- [ ] HTTPS used for all remote content
- [ ] Certificate verification enabled
- [ ] API keys stored in registry (not hardcoded)
- [ ] Input validation implemented
- [ ] XSS protection in HTML applications
- [ ] Content signatures verified
- [ ] Sensitive data never logged
- [ ] Inactivity timeouts configured
- [ ] Physical security measures planned

### Post-Deployment

- [ ] Regular firmware updates
- [ ] Security log monitoring
- [ ] Anomaly detection active
- [ ] Incident response plan documented
- [ ] Backup and recovery tested
- [ ] Access control audited

---

## Best Practices

### Do

- **Use HTTPS everywhere** - Encrypt all network traffic
- **Validate all inputs** - Never trust external data
- **Disable debug features** - In production deployments
- **Use strong passwords** - Change defaults
- **Log security events** - For audit trail
- **Implement timeouts** - Prevent unauthorized extended access
- **Update firmware regularly** - Security patches
- **Monitor for anomalies** - Detect attacks early
- **Test security** - Penetration testing before deployment

### Don't

- **Don't hardcode credentials** - Use registry or secure storage
- **Don't use HTTP** - Always use HTTPS
- **Don't ignore security warnings** - Address immediately
- **Don't expose debug interfaces** - In production
- **Don't trust user input** - Validate and sanitize
- **Don't log sensitive data** - Passwords, API keys, PII
- **Don't skip updates** - Security vulnerabilities

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Certificate errors | Expired/invalid cert | Update certificates, check date/time |
| Authentication failures | Wrong credentials | Verify credentials, check token expiry |
| Unauthorized access | Weak password | Use strong passwords, disable defaults |
| Content tampering detected | Compromised source | Verify content signatures, audit logs |

---

## Exercises

1. **Security Audit**: Audit existing application for security vulnerabilities

2. **Secure API Client**: Build API client with OAuth2, certificate pinning, and rate limiting

3. **Tamper Detection**: Implement SD card and USB tamper detection with alerts

4. **Encrypted Storage**: Create encrypted credential storage system

5. **Security Monitor**: Build dashboard monitoring security events across fleet

---

## Next Steps

- [Debugging Production Issues](17-debugging-production-issues.md) - Investigate security incidents
- [Building Custom Extensions](16-building-custom-extensions.md) - Secure extension development
- [Setting Up BSN.cloud](10-setting-up-bsn-cloud.md) - Cloud security features

---

## Additional Resources

- [BSN.Cloud Network Security](https://docs.brightsign.biz/advanced/bsncloud-network-security)
- [BrightSign Network (BSN) Security](https://docs.brightsign.biz/advanced/brightsign-network-bsn-security)
- [BrightSign Security Statements](https://support.brightsign.biz/hc/en-us/sections/360008618754-BrightSign-Security-Announcements)
- OWASP Top 10: owasp.org/top-ten

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
