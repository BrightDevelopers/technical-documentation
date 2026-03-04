# Automated Provisioning

[<- Back to Part 5: BSN Cloud](README.md) | [^ Main](../../README.md)

---

## Overview

BrightSign players include a built-in provisioning and recovery system that enables zero-touch deployment and remote content management. This system works independently of BSN.cloud and can be integrated with custom provisioning servers, making it suitable for both cloud-managed and self-hosted deployment scenarios.

The provisioning system uses a **recovery URL** (`ru`) to download autorun scripts from a remote server. The player makes HTTP GET requests to this URL at different stages of its lifecycle, allowing your server to push updates, monitor health, and recover from failures.

**Key capabilities:**
- Zero-touch deployment via DHCP Option 43
- Automatic content updates on boot and during runtime
- Emergency recovery from storage failures or runtime errors
- Fleet-wide configuration without per-device setup
- Custom provisioning server integration

---

## Recovery URL Configuration

### The Registry Key: `ru`

The primary registry key for recovery is **`ru`** -- the provisioning/recovery URL used by the player to download an autorun script. Related keys include:

| Key | Purpose |
|-----|---------|
| `ru` | Recovery/provisioning URL (main endpoint) |
| `eu` | Error notification URL |
| `cu` | Crash report URL |
| `ub` | URL prefix applied to `ru`, `eu`, and `cu` (unless value contains a colon) |
| `p` | Password for the recovery handler |

These keys live in the **"networking"** section of the player registry, accessible via the BrightScript `roRegistrySection` object or through BrightAuthor:connected setup.

---

### How the Player Finds the Recovery URL at Boot

When a BrightSign player boots and obtains an IP address, it checks for a recovery URL (`ru`) using this priority order:

1. **DHCP Option 43** -- if a recovery URL is found via DHCP Option 43, it overrides any registry value for `ru` until the end of the DHCP lease
2. **Registry value** -- if no DHCP Option 43 RU is found, the `ru` value stored in the registry is used
3. **Well-known host / DNS mapping** -- if the registry value is blank, the player attempts "well-known host provisioning" by checking if `brightsign.b-deploy` is mapped in DNS
4. **mDNS** -- the player automatically checks `http://brightsign.b-deploy.local/` for a local provisioning server

---

### Configuration Methods

**Option A -- BrightAuthor:connected Setup**

During player setup, the provisioning/recovery URL is one of the fields configured in the setup wizard before writing to the SD card.

**Option B -- DHCP Option 43 (network-wide)**

The `ru` value in the registry can be overridden using DHCP Option 43, meaning that with properly configured network infrastructure, players can set themselves up and begin playing content without manual on-site configuration. This is the preferred method for large deployments since it applies to all players on the network segment without touching each device.

The recovery URL in the DHCP Option 43 payload is prepended with `U` + the ASCII character representing the URL's length. For example, if the URL is 64 characters long, the value would be prepended with `U@` (where `@` is decimal 64 in ASCII).

**Option C -- Direct registry edit via Diagnostic Web Server (DWS)**

Access the player's DWS at `http://<player-ip>/` and navigate to the registry editor to set the `ru` key manually.

---

### Configuration Summary

| Where | How |
|-------|-----|
| Player registry (`ru` key) | Set during BrightAuthor:connected setup or via DWS |
| DHCP Option 43 | Network-level override; no per-device config needed |
| DNS mapping | Zero-config fallback using `brightsign.b-deploy` hostname |
| mDNS | Auto-discovery of `brightsign.b-deploy.local` on local network |

> **Best Practice:** The **DHCP Option 43 approach** is the most robust for emergency/fallback scenarios since it works even if the player's registry was wiped (e.g., after a factory reset), as long as the player gets a DHCP lease.

---

## Recovery Modes

There are three recovery modes, all of which hit the same `ru` endpoint. The modes are distinguished by the `recoverymode` header value the player sends in its HTTP GET request, which tells your request handler server exactly what situation it's dealing with.

### Mode 1: Override (`recoverymode: override`)

This mode fires on **every boot** when the player finds a valid autorun on its storage device. It's not really a "recovery" in the emergency sense -- it's the normal check-in that gives your server the opportunity to push updated content before the local autorun executes.

**Sequence of events:**

Once the boot process completes, the player scans each storage device to determine if one or more devices contain an autorun file. If at least one device contains an autorun, the player **delays executing it** while a background process sends an HTTP GET to the provisioning/recovery URL.

If the request handler responds with HTTP 200 and a non-empty body, the player uses the response body as the new autorun script. If the handler responds with HTTP 204, or HTTP 200 with an empty body, the player executes the pre-existing local autorun as normal.

**Timeout behavior:**

If no response is received within 20 seconds, the pre-existing autorun will be executed. The player will then send another request to the request handler after five minutes, then after 10 minutes, and then once every two hours after that.

**Storage device priority:**

If multiple storage devices contain an autorun file, the player selects the first autorun in this order: USB, SD, SD2, SSD. Note that if it takes too long to check the integrity of a storage device, that device might be skipped -- so don't build a system that relies on this order.

**Key design implication:** Override mode is your primary mechanism for remote content updates in normal operation. Your server can respond with 204 to leave a healthy player alone, or 200 + a new autorun to push an update. The 20-second timeout is important to design around -- your server must respond quickly or the local autorun just runs anyway.

---

### Mode 2: Periodic (`recoverymode: periodic`)

This mode fires **while the player is running normally** -- it's the recurring heartbeat check-in that happens after the initial override check on boot.

**When it fires:**

The player periodically sends an HTTP GET to the provisioning/recovery URL to determine if the device should be updated. The check-in interval defaults to two hours, but the server can control this via a `Retry-After` header in the response (value in seconds).

**Response handling:**

If no response is received, the pre-existing autorun continues without interruption. If the handler responds with HTTP 204, or HTTP 200 with an empty body, the pre-existing autorun also continues without interruption. If the handler responds with HTTP 200 and a non-empty body, the player uses the response body as the new autorun script.

**Key design implication:** Periodic mode is how you push updates to players that are already up and running healthy. It's also your opportunity to detect a player that's been running stale content. The `Retry-After` header is powerful here -- you can dial the check-in frequency up or down dynamically. For example, you could respond with a short `Retry-After` when you know a content update is imminent, and a long one during stable periods to reduce server load.

---

### Mode 3: Last Resort (`recoverymode: last_resort`)

This is the true emergency recovery mode. It triggers when the player genuinely cannot play anything on its own.

**What triggers it:**

Last resort recovery begins when none of the attached storage devices contain an autorun file, **or** when the designated autorun encounters an `autorun load error` or `autorun runtime error`.

The `storagestatus` header in the request will tell your server exactly what happened on each device. Possible status values per device are:

| Status | Meaning |
|--------|---------|
| `none` | Device not detected |
| `storage` | Device present but no autorun found |
| `autorun` | Device present with valid autorun |
| `autorun load error` | Autorun found but failed to load |
| `autorun runtime error` | Autorun found but crashed at runtime |
| `error` | Device present but failed filesystem check, including failed repair attempts |

**Response handling:**

If the handler responds with HTTP 200 and a non-empty body, the player uses the response body as the new autorun script. Importantly, **the autorun script must reboot the player itself** once it performs the necessary recovery tasks -- the player will not automatically reboot. If the handler responds with HTTP 204 or HTTP 200 with an empty body, the player immediately reboots.

**Timeout and retry behavior:**

If the request handler does not respond, the player will continue sending requests for **30 minutes** before rebooting. However, if the autorun encountered a runtime error (rather than a missing autorun), the reboot occurs after only **5 minutes**. This process cycles indefinitely until an autorun script is received from the request handler.

**Key design implication:** Last resort is where your server needs to be smart. Because the `storagestatus` header tells you the condition of every storage device, your request handler can make decisions: send a lightweight recovery autorun that reformats the SD card and re-downloads content for a filesystem corruption case, or send a diagnostic autorun for a runtime error case. The fact that the cycle repeats indefinitely means a player in this state will keep trying -- but it's also why your recovery autorun *must* explicitly reboot, otherwise the player just sits in the recovery script forever.

---

## Recovery Mode Comparison

| | Override | Periodic | Last Resort |
|---|---|---|---|
| **Trigger** | Boot, valid autorun found | Running normally, interval elapsed | No autorun / autorun error |
| **`recoverymode` header value** | `override` | `periodic` | `last_resort` |
| **Player state at trigger** | Healthy, about to run local autorun | Healthy, playing content | Broken -- cannot play |
| **Timeout if no server response** | 20 seconds -> runs local autorun | No timeout -> continues as-is | 30 min (5 min for runtime error) -> reboots |
| **200 + body response** | Replaces local autorun | Replaces running autorun | Executes recovery autorun |
| **204 / empty 200 response** | Runs local autorun normally | Continues current autorun | Immediately reboots |
| **Loops indefinitely?** | No | No | Yes, until autorun received |
| **Must script explicit reboot?** | No | No | **Yes** |

---

## Building a Recovery Server

### Minimal HTTP Handler

Your recovery server needs to handle HTTP GET requests and inspect the `recoverymode` header to determine the appropriate response:

```python
from flask import Flask, request, Response

app = Flask(__name__)

@app.route('/recovery')
def recovery_handler():
    mode = request.headers.get('recoverymode', 'unknown')
    serial = request.headers.get('serial', 'unknown')
    storage = request.headers.get('storagestatus', '')

    # Log the check-in
    print(f"Player {serial}: mode={mode}, storage={storage}")

    if mode == 'override':
        # Player just booted, decide if we want to update it
        if should_update_player(serial):
            return Response(get_autorun_script(serial), mimetype='text/plain')
        else:
            return Response('', status=204)  # Use existing autorun

    elif mode == 'periodic':
        # Heartbeat check-in during normal operation
        if has_pending_update(serial):
            return Response(get_autorun_script(serial), mimetype='text/plain')
        else:
            return Response('', status=204, headers={'Retry-After': '7200'})

    elif mode == 'last_resort':
        # Emergency recovery needed
        recovery_script = generate_recovery_script(serial, storage)
        return Response(recovery_script, mimetype='text/plain')

    return Response('', status=204)
```

### Request Headers

The player sends several headers with each recovery request:

| Header | Description |
|--------|-------------|
| `recoverymode` | One of: `override`, `periodic`, `last_resort` |
| `serial` | Player serial number |
| `model` | Player model (e.g., `XT2145`) |
| `version` | BrightSign OS version |
| `storagestatus` | Comma-separated status of each storage device (USB, SD, SD2, SSD) |

### Response Headers

Your server can control player behavior with these response headers:

| Header | Purpose |
|--------|---------|
| `Retry-After` | Number of seconds until next periodic check-in (default: 7200) |
| `Content-Type` | Should be `text/plain` when returning an autorun script |

---

## Best Practices

### Fleet Management

1. **Track player state** -- use the serial number and headers to maintain a database of player status
2. **Version control autoruns** -- keep track of which version each player is running
3. **Staged rollouts** -- push updates to a subset of players first, monitor for issues
4. **Fast response times** -- the override mode has a 20-second timeout, ensure your server responds quickly

### Error Handling

1. **Parse `storagestatus` carefully** -- it tells you exactly what went wrong
2. **Send appropriate recovery scripts** -- filesystem errors need different recovery than runtime errors
3. **Log all recovery requests** -- last resort mode indicates a problem that needs investigation
4. **Include diagnostics in recovery scripts** -- have the player report detailed error information

### Security

1. **Use HTTPS** -- protect autorun scripts in transit
2. **Authenticate players** -- verify the serial number and model before sending scripts
3. **Use the `p` registry key** -- require a password for recovery requests
4. **Rate limiting** -- prevent abuse from rogue players

### Testing

1. **Test all three modes** -- simulate boot, periodic, and failure scenarios
2. **Test timeout behavior** -- ensure your server responds within the timeout windows
3. **Test storage failures** -- verify last resort recovery works when storage is corrupt
4. **Monitor production** -- track recovery mode frequencies to detect fleet issues

---

## Example: DHCP Option 43 Configuration

### ISC DHCP Server

```
option space brightsign;
option brightsign.recovery-url code 1 = text;

class "brightsign-players" {
    match if substring(option vendor-class-identifier, 0, 10) = "BrightSign";
    vendor-option-space brightsign;
    option brightsign.recovery-url "https://provisioning.example.com/recovery";
}
```

### Windows DHCP Server

1. Open DHCP management console
2. Right-click IPv4 -> Set Predefined Options
3. Add new option:
   - Name: BrightSign Recovery URL
   - Data type: String
   - Code: 43
   - Value: `U@https://provisioning.example.com/recovery` (where `@` is chr(64) for a 64-character URL)

---

## Next Steps

- [Per-Player Control](03-per-player-control.md) -- Remote commands and monitoring
- [BSN.content](04-bsn-content.md) -- Content management and scheduling
- [Code Examples](examples/README.md) -- Recovery server implementations

---

[^ Part 5: BSN Cloud](README.md)
