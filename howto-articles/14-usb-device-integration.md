# USB Device Integration

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers integrating USB devices with BrightSign players for enhanced interactivity and functionality. USB support enables connections to keyboards, mice, barcode scanners, RFID readers, storage devices, and other peripherals for creating sophisticated digital signage solutions.

### What You'll Learn

- Understanding USB HID device support
- Integrating barcode scanners and RFID readers
- Working with USB storage devices
- Detecting USB device insertion and removal
- USB keyboard and mouse input
- USB power management
- USB-to-serial adapter usage

### Common USB Device Applications

| Device Type | Use Case | Interface |
|-------------|----------|-----------|
| **Barcode Scanner** | Product lookup, inventory | HID (keyboard emulation) |
| **RFID Reader** | Access control, authentication | HID or serial |
| **USB Keyboard** | Data entry, kiosk input | HID |
| **USB Mouse** | Navigation (non-touch displays) | HID |
| **USB Storage** | Content delivery, logging | Mass storage |
| **USB Serial** | Legacy device connectivity | CDC-ACM |
| **Button Panels** | BP200/BP900 interactive controllers | HID |

---

## Prerequisites

- BrightSign player with USB ports
- Understanding of USB device classes
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))
- USB device for testing (keyboard, scanner, or storage)

---

## USB Hardware Specifications

### USB Power Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| **USB Version** | USB 2.0 / 3.0 | Model dependent |
| **Power per Port** | 500mA (USB 2.0) | Per USB specification |
| **Power per Port** | 900mA (USB 3.0) | On supported models |
| **Total USB Power** | Varies by model | Check player specifications |

**Important:** High-power USB devices (>500mA) may require powered USB hub.

### Supported USB Device Classes

| USB Class | Description | Support |
|-----------|-------------|---------|
| **HID** | Human Interface Devices | Full support |
| **Mass Storage** | USB drives, card readers | Full support |
| **CDC-ACM** | USB-to-serial adapters | Full support |
| **Audio** | USB audio devices | Limited support |
| **Video** | USB cameras | Limited (UVC) |

---

## Part 1: USB HID Devices

HID (Human Interface Device) class includes keyboards, mice, barcode scanners, and button panels.

### USB Keyboard Input

**BrightScript Example:**

```brightscript
Sub Main()
    ' Create message port
    msgPort = CreateObject("roMessagePort")

    ' Create HTML widget to capture keyboard events
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
    htmlWidget = CreateObject("roHtmlWidget", rect, {
        url: "file:///sd:/keyboard-input.html",
        mouse_enabled: false
    })
    htmlWidget.Show()
    htmlWidget.SetPort(msgPort)

    print "Waiting for keyboard input..."

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roHtmlWidgetEvent" then
            eventData = msg.GetData()

            if eventData.reason = "message" then
                ' Handle keyboard input from HTML
                if eventData.message.type = "keypress" then
                    key = eventData.message.key
                    print "Key pressed: "; key
                    ProcessKeyInput(key)
                end if
            end if
        end if
    end while
End Sub

Sub ProcessKeyInput(key as String)
    ' Handle specific keys
    if key = "Enter" then
        print "Enter key pressed"
    else if key = "Escape" then
        print "Escape key pressed"
    else
        print "Character: "; key
    end if
End Sub
```

**HTML keyboard-input.html:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            width: 1920px;
            height: 1080px;
            background: #1a1a1a;
            color: white;
            font-family: monospace;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        #input-display {
            font-size: 48px;
            padding: 20px;
            border: 2px solid #4CAF50;
            min-width: 800px;
            text-align: center;
        }
        #log {
            margin-top: 40px;
            font-size: 20px;
            opacity: 0.7;
        }
    </style>
</head>
<body>
    <div id="input-display">Type on USB keyboard...</div>
    <div id="log"></div>

    <script>
        let inputBuffer = '';

        document.addEventListener('keydown', (event) => {
            const display = document.getElementById('input-display');
            const log = document.getElementById('log');

            if (event.key === 'Enter') {
                // Send completed input to BrightScript
                window.bsMessage({
                    type: 'input',
                    value: inputBuffer
                });

                log.textContent = 'Sent: ' + inputBuffer;
                inputBuffer = '';
                display.textContent = '';

            } else if (event.key === 'Backspace') {
                inputBuffer = inputBuffer.slice(0, -1);
                display.textContent = inputBuffer;

            } else if (event.key.length === 1) {
                // Regular character
                inputBuffer += event.key;
                display.textContent = inputBuffer;

                // Send key to BrightScript
                window.bsMessage({
                    type: 'keypress',
                    key: event.key
                });
            }
        });
    </script>
</body>
</html>
```

### JavaScript Keyboard Handling

```javascript
// Direct keyboard event handling in Node.js
const keyboard = require('@brightsign/keyboard');

keyboard.addEventListener('keydown', (event) => {
    console.log('Key down:', event.key, 'Code:', event.code);

    if (event.key === 'Enter') {
        processInput();
    } else if (event.key === 'Escape') {
        cancelInput();
    }
});

keyboard.addEventListener('keyup', (event) => {
    console.log('Key up:', event.key);
});
```

---

## Part 2: Barcode Scanner Integration

Most USB barcode scanners emulate keyboards (HID keyboard wedge).

### Barcode Scanner Handler

```brightscript
Sub Main()
    msgPort = CreateObject("roMessagePort")

    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
    htmlWidget = CreateObject("roHtmlWidget", rect, {
        url: "file:///sd:/barcode-scanner.html"
    })
    htmlWidget.Show()
    htmlWidget.SetPort(msgPort)

    print "Barcode scanner ready"

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roHtmlWidgetEvent" then
            eventData = msg.GetData()

            if eventData.reason = "message" then
                if eventData.message.type = "barcode" then
                    barcode = eventData.message.value
                    print "Barcode scanned: "; barcode
                    ProcessBarcode(barcode)
                end if
            end if
        end if
    end while
End Sub

Sub ProcessBarcode(barcode as String)
    ' Look up product information
    print "Looking up product: "; barcode

    ' Make API call to get product info
    urlTransfer = CreateObject("roUrlTransfer")
    url = "https://api.example.com/products/" + barcode
    urlTransfer.SetUrl(url)

    response = urlTransfer.GetToString()

    if response <> "" then
        productInfo = ParseJson(response)
        DisplayProduct(productInfo)
    else
        print "Product not found"
    end if
End Sub

Sub DisplayProduct(product as Object)
    print "Product: "; product.name
    print "Price: $"; product.price
    ' Update display with product information
End Sub
```

**HTML barcode-scanner.html:**

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            width: 1920px;
            height: 1080px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .scanner-prompt {
            font-size: 48px;
            margin-bottom: 40px;
        }
        .barcode-display {
            font-size: 72px;
            font-family: monospace;
            background: rgba(255,255,255,0.1);
            padding: 40px;
            border-radius: 10px;
            min-width: 600px;
            text-align: center;
        }
        .status {
            margin-top: 40px;
            font-size: 24px;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="scanner-prompt">Scan Barcode</div>
    <div class="barcode-display" id="barcode">Ready...</div>
    <div class="status" id="status"></div>

    <script>
        let barcodeBuffer = '';
        let scanTimeout = null;

        document.addEventListener('keydown', (event) => {
            const barcodeDisplay = document.getElementById('barcode');
            const status = document.getElementById('status');

            // Clear previous timeout
            if (scanTimeout) {
                clearTimeout(scanTimeout);
            }

            if (event.key === 'Enter') {
                // Barcode scan complete
                if (barcodeBuffer.length > 0) {
                    console.log('Barcode scanned:', barcodeBuffer);

                    // Send to BrightScript
                    window.bsMessage({
                        type: 'barcode',
                        value: barcodeBuffer
                    });

                    // Visual feedback
                    barcodeDisplay.style.background = 'rgba(76, 175, 80, 0.3)';

                    setTimeout(() => {
                        barcodeBuffer = '';
                        barcodeDisplay.textContent = 'Ready...';
                        barcodeDisplay.style.background = 'rgba(255,255,255,0.1)';
                        status.textContent = '';
                    }, 2000);
                }

            } else if (event.key.length === 1) {
                // Accumulate barcode characters
                barcodeBuffer += event.key;
                barcodeDisplay.textContent = barcodeBuffer;
                status.textContent = 'Scanning...';

                // Timeout after 2 seconds of no input
                scanTimeout = setTimeout(() => {
                    barcodeBuffer = '';
                    barcodeDisplay.textContent = 'Ready...';
                    status.textContent = 'Scan timeout';
                }, 2000);
            }
        });
    </script>
</body>
</html>
```

---

## Part 3: USB Storage Device Integration

### Detecting USB Storage Events

**BrightScript Example:**

```brightscript
Sub Main()
    msgPort = CreateObject("roMessagePort")

    ' Create storage hotplug detector
    hotplug = CreateObject("roStorageHotplug")
    hotplug.SetPort(msgPort)

    print "Monitoring USB storage devices..."

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roStorageHotplugEvent" then
            event = msg.GetEvent()
            path = msg.GetPath()

            if event = "added" then
                print "USB device attached: "; path
                ProcessUSBStorage(path)

            else if event = "removed" then
                print "USB device removed: "; path
                HandleUSBRemoval(path)
            end if
        end if
    end while
End Sub

Sub ProcessUSBStorage(path as String)
    ' Check if storage is accessible
    fs = CreateObject("roFileSystem")

    if fs.Exists(path) then
        print "USB storage mounted at: "; path

        ' List files on USB drive
        files = fs.GetDirectoryListing(path)

        print "Files on USB drive:"
        for each file in files
            print "  "; file
        end for

        ' Look for specific files
        autoplayFile = path + "/autoplay.json"
        if fs.Exists(autoplayFile) then
            ProcessAutoplayFile(autoplayFile)
        end if
    end if
End Sub

Sub ProcessAutoplayFile(filePath as String)
    ' Read and process autoplay configuration
    content = ReadAsciiFile(filePath)
    config = ParseJson(content)

    if config <> invalid then
        print "Autoplay config loaded"

        if config.action = "play_video" then
            videoPath = config.path
            print "Playing video from USB: "; videoPath
            PlayVideoFromUSB(videoPath)
        end if
    end if
End Sub

Sub HandleUSBRemoval(path as String)
    print "USB storage removed, reverting to default content"
    ' Return to normal operation
End Sub

Function PlayVideoFromUSB(videoPath as String) as Void
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.PlayFile(videoPath)
End Function
```

### JavaScript USB Storage Monitoring

```javascript
const usbHotplug = require('@brightsign/usbhotplug');
const fs = require('fs');
const path = require('path');

// Monitor USB device events
usbHotplug.addEventListener('usbattached', (event) => {
    console.log('USB device attached:', event.path);

    // Check if it's storage
    if (event.path.startsWith('/storage/usb')) {
        processUSBStorage(event.path);
    }
});

usbHotplug.addEventListener('usbdetached', (event) => {
    console.log('USB device removed:', event.path);
    handleUSBRemoval(event.path);
});

function processUSBStorage(usbPath) {
    // List files on USB
    fs.readdir(usbPath, (err, files) => {
        if (err) {
            console.error('Error reading USB:', err);
            return;
        }

        console.log('Files on USB:', files);

        // Look for media files
        const mediaFiles = files.filter(f =>
            f.endsWith('.mp4') || f.endsWith('.jpg') || f.endsWith('.png')
        );

        if (mediaFiles.length > 0) {
            console.log('Found media files:', mediaFiles);
            playMediaFromUSB(path.join(usbPath, mediaFiles[0]));
        }
    });
}

function playMediaFromUSB(filePath) {
    console.log('Playing media from USB:', filePath);
    // Trigger media playback
}

function handleUSBRemoval(usbPath) {
    console.log('USB removed, returning to default content');
}
```

### Copying Files from USB

```brightscript
Function CopyFileFromUSB(sourcePath as String, destPath as String) as Boolean
    fs = CreateObject("roFileSystem")

    if not fs.Exists(sourcePath) then
        print "Source file not found: "; sourcePath
        return false
    end if

    ' Get file size
    stat = fs.Stat(sourcePath)
    fileSize = stat.size

    print "Copying file ("; fileSize; " bytes)..."

    ' Read source file
    sourceFile = CreateObject("roReadFile", sourcePath)
    if sourceFile = invalid then
        print "Cannot open source file"
        return false
    end if

    ' Create destination file
    destFile = CreateObject("roCreateFile", destPath)
    if destFile = invalid then
        print "Cannot create destination file"
        return false
    end if

    ' Copy in chunks
    chunkSize = 65536  ' 64KB
    totalCopied = 0

    while totalCopied < fileSize
        chunk = sourceFile.Read(chunkSize)
        if chunk.Count() = 0 then exit while

        destFile.Write(chunk)
        totalCopied = totalCopied + chunk.Count()

        ' Show progress
        percent = int((totalCopied * 100) / fileSize)
        print "Progress: "; percent; "%"
    end while

    print "Copy complete"
    return true
End Function

Sub AutoCopyFromUSB()
    msgPort = CreateObject("roMessagePort")
    hotplug = CreateObject("roStorageHotplug")
    hotplug.SetPort(msgPort)

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roStorageHotplugEvent" then
            if msg.GetEvent() = "added" then
                usbPath = msg.GetPath()
                print "USB detected, copying content..."

                ' Copy all videos from USB to SD
                fs = CreateObject("roFileSystem")
                files = fs.GetDirectoryListing(usbPath)

                for each file in files
                    if Right(file, 4) = ".mp4" then
                        source = usbPath + "/" + file
                        dest = "SD:/videos/" + file

                        if CopyFileFromUSB(source, dest) then
                            print "Copied: "; file
                        end if
                    end if
                end for

                print "Copy complete"
            end if
        end if
    end while
End Sub
```

---

## Part 4: RFID Reader Integration

RFID readers typically emulate keyboards or use serial communication.

### RFID Keyboard Wedge Mode

```javascript
// RFID reader in keyboard emulation mode
let rfidBuffer = '';

document.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
        if (rfidBuffer.length > 0) {
            console.log('RFID card scanned:', rfidBuffer);

            // Send to backend for authentication
            authenticateUser(rfidBuffer);

            rfidBuffer = '';
        }
    } else if (event.key.length === 1) {
        rfidBuffer += event.key;
    }
});

async function authenticateUser(cardId) {
    try {
        const response = await fetch(`https://api.example.com/auth/rfid/${cardId}`);
        const data = await response.json();

        if (data.authorized) {
            showWelcome(data.user);
        } else {
            showAccessDenied();
        }
    } catch (error) {
        console.error('Authentication error:', error);
    }
}

function showWelcome(user) {
    document.getElementById('message').textContent = `Welcome, ${user.name}!`;
}

function showAccessDenied() {
    document.getElementById('message').textContent = 'Access Denied';
}
```

---

## Part 5: USB Device Detection

### Querying USB Topology

```brightscript
Sub ListUSBDevices()
    deviceInfo = CreateObject("roDeviceInfo")
    usbDevices = deviceInfo.GetUSBTopology()

    print "Connected USB Devices:"
    print "====================="

    for each device in usbDevices
        print "Device: "; device.prd
        print "  Manufacturer: "; device.mfr
        print "  Type: "; device.type
        print "  VID: 0x"; hex(device.vid)
        print "  PID: 0x"; hex(device.pid)
        print "  FID: "; device.fid
        print "  Path: "; device.path
        print ""
    end for
End Sub

Function FindUSBDeviceByType(deviceType as String) as Object
    deviceInfo = CreateObject("roDeviceInfo")
    usbDevices = deviceInfo.GetUSBTopology()

    for each device in usbDevices
        if device.type = deviceType then
            return device
        end if
    end for

    return invalid
End Function

Sub DetectSpecificUSBDevice()
    ' Look for specific USB device
    device = FindUSBDeviceByType("storage")

    if device <> invalid then
        print "Storage device found:"
        print "  Product: "; device.prd
        print "  Path: "; device.path
    else
        print "No storage device found"
    end if
End Sub
```

---

## Part 6: USB Power Management

### Controlling USB Port Power

```javascript
const usbPowerControl = require('@brightsign/usbpowercontrol');

// Enable USB port
function enableUSBPort(portNumber) {
    usbPowerControl.setPortPower(portNumber, true);
    console.log(`USB port ${portNumber} enabled`);
}

// Disable USB port
function disableUSBPort(portNumber) {
    usbPowerControl.setPortPower(portNumber, false);
    console.log(`USB port ${portNumber} disabled`);
}

// Power cycle USB device
function powerCycleUSBPort(portNumber) {
    console.log('Power cycling USB port...');

    disableUSBPort(portNumber);

    setTimeout(() => {
        enableUSBPort(portNumber);
        console.log('Power cycle complete');
    }, 2000);
}

// Usage
powerCycleUSBPort(1);
```

---

## Complete Example - USB Content Delivery System

A system that automatically plays content from USB drives:

### autorun.brs

```brightscript
Sub Main()
    print "USB Content Delivery System"

    ' Set video mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Create message port
    msgPort = CreateObject("roMessagePort")

    ' Create video player
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetPort(msgPort)

    ' Create USB monitor
    hotplug = CreateObject("roStorageHotplug")
    hotplug.SetPort(msgPort)

    ' Play default content
    defaultPlaylist = ["video1.mp4", "video2.mp4", "video3.mp4"]
    currentIndex = 0
    videoPlayer.SetLoopMode(false)
    videoPlayer.PlayFile("SD:/" + defaultPlaylist[currentIndex])

    ' State
    usbContentActive = false

    while true
        msg = wait(0, msgPort)
        msgType = type(msg)

        if msgType = "roStorageHotplugEvent" then
            event = msg.GetEvent()
            path = msg.GetPath()

            if event = "added" then
                print "USB inserted"
                playlist = ScanUSBForVideos(path)

                if playlist.Count() > 0 then
                    print "Playing content from USB"
                    videoPlayer.Stop()
                    PlayUSBPlaylist(videoPlayer, playlist)
                    usbContentActive = true
                end if

            else if event = "removed" then
                print "USB removed"
                if usbContentActive then
                    videoPlayer.Stop()
                    currentIndex = 0
                    videoPlayer.PlayFile("SD:/" + defaultPlaylist[currentIndex])
                    usbContentActive = false
                end if
            end if

        else if msgType = "roVideoEvent" then
            eventCode = msg.GetInt()

            if eventCode = 8 then  ' Video ended
                if usbContentActive then
                    ' USB playlist ended, return to default
                    print "USB playlist complete"
                    currentIndex = 0
                    videoPlayer.PlayFile("SD:/" + defaultPlaylist[currentIndex])
                    usbContentActive = false
                else
                    ' Next video in default playlist
                    currentIndex = (currentIndex + 1) mod defaultPlaylist.Count()
                    videoPlayer.PlayFile("SD:/" + defaultPlaylist[currentIndex])
                end if
            end if
        end if
    end while
End Sub

Function ScanUSBForVideos(usbPath as String) as Object
    fs = CreateObject("roFileSystem")
    playlist = []

    if fs.Exists(usbPath) then
        files = fs.GetDirectoryListing(usbPath)

        for each file in files
            ext = LCase(Right(file, 4))
            if ext = ".mp4" or ext = ".mov" or ext = ".avi" then
                playlist.Push(usbPath + "/" + file)
            end if
        end for

        ' Sort alphabetically
        playlist.Sort()
    end if

    print "Found "; playlist.Count(); " videos on USB"
    return playlist
End Function

Sub PlayUSBPlaylist(player as Object, playlist as Object)
    ' Play first video, others will follow
    if playlist.Count() > 0 then
        player.PlayFile(playlist[0])

        ' Queue remaining videos
        for i = 1 to playlist.Count() - 1
            player.PreloadFile(playlist[i])
        end for
    end if
End Sub
```

---

## Best Practices

### Do

- **Check device compatibility** before deployment
- **Handle hotplug events** gracefully
- **Validate USB data** before processing
- **Provide visual feedback** for USB operations
- **Set appropriate timeouts** for USB operations
- **Log USB events** for troubleshooting
- **Use powered hubs** for high-power devices
- **Test with actual hardware** before production

### Don't

- **Don't assume USB device presence** - always check
- **Don't exceed USB power limits** (500mA/port typically)
- **Don't ignore hotplug events** - can cause issues
- **Don't perform long operations** without progress indication
- **Don't trust USB data implicitly** - validate first
- **Don't hot-swap USB** during file operations

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| USB device not detected | Insufficient power | Use powered USB hub |
| Barcode scanner not working | Wrong mode | Configure as HID keyboard wedge |
| USB storage not mounting | Filesystem not supported | Use FAT32 or exFAT |
| Erratic keyboard input | Multiple keyboards | Disable on-screen keyboard |
| File copy fails | Insufficient space | Check available storage |
| Device disconnects randomly | Power issue | Use powered hub or Y-cable |

---

## Exercises

1. **Barcode Product Lookup**: Build a system that looks up products via API when scanned

2. **USB Content Player**: Create automatic content playback from USB drives

3. **RFID Authentication**: Implement user authentication with RFID cards

4. **Data Logger**: Log sensor data to USB storage with timestamps

5. **Interactive Survey**: Build a USB keyboard-based survey kiosk

6. **USB File Manager**: Create a file browser for USB devices

---

## Next Steps

- [Using GPIO for Interactivity](12-using-gpio-for-interactivity.md) - Physical button control
- [Serial Communication](13-serial-communication.md) - RS-232 device interfacing
- [Touch Screen Configuration](15-touch-screen-configuration.md) - Touch input setup

---

## Additional Resources

- [BrightSign roStorageHotplug Documentation](https://docs.brightsign.biz/display/DOC/roStorageHotplug)
- USB-IF Specifications: usb.org
- HID Usage Tables: usb.org/hid

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
