# Chapter 6: JavaScript Playback

[← Back to Part 3: JavaScript Development](README.md) | [↑ Main](../../README.md)

---

## HTML5 & JavaScript for Media Playback

BrightSign players use the Chromium rendering engine to display HTML5 content and execute JavaScript applications. This chapter covers how to leverage HTML5 and JavaScript for rich interactive media playback on BrightSign devices.

## HTML5 Support

### Chromium Rendering Engine

BrightSign players use Chromium as their HTML rendering engine. The version varies by firmware:

| Rendering Engine | Version | BrightSign FW Versions |
|------------------|---------|------------------------|
| Chromium         | 87      | 8.5.x, 9.0.x          |
| Chromium         | 69      | 8.4.x, 8.3.x, 8.2.x, 8.1.x |
| Chromium         | 65      | 8.0.x                 |
| Chromium         | 45      | 7.1.x, 7.0.x, 6.2.x   |
| Chromium         | 37      | 6.1.x, 6.0.x          |

Use [caniuse.com](http://caniuse.com/) to determine which HTML5 features and APIs are supported in specific Chromium versions.

### Supported HTML5 Features

BrightSign HTML5 support includes:
- Standard HTML5 elements (div, canvas, video, audio)
- CSS3 styling and animations
- WebGL for 3D graphics
- SVG for vector graphics
- Web Storage (localStorage, sessionStorage, IndexedDB)
- WebSockets for real-time communication
- Geolocation and device APIs
- Media Source Extensions (MSE) for adaptive streaming

### Limitations

**No Flash Support**: BrightSign players do not support Flash content. Export Flash content as HTML using Adobe Creative Suite tools.

**4K Graphics Restrictions**:
- **XTx44, XTx43**: Support native 4K HTML graphics with performance limitations (max 20 FPS for animations, recommend 1-2 4K images maximum)
- **XDx34, XDx33, HDx24, HDx23, LS424, LS423, 4Kx42**: Graphics limited to 1920x1200, upscaled to 4K output

**Image Size Limits**: Default maximum is 2048x1280x32bpp (or 3840x2160x32bpp for XT/4K models). Use `roVideoMode.SetImageSizeThreshold()` to increase.

**Memory Constraints by Model** (Series 4 and older):
- XTx43/44: 512MB graphics, 512MB JavaScript
- XDx33/34: 256MB graphics, 512MB JavaScript
- HDx24: 460MB graphics
- LS4x5: 280MB graphics
- HDx23/LS423/HO523: 256MB graphics, 128MB JavaScript

Series 5 players have dynamic memory allocation without pre-allocated graphics/system memory.

### Best Practices

**Page Structure**:
1. Match HTML page aspect ratio to display resolution
2. Use a master div aligned to 0,0 for correct alignment
3. Keep all assets (images, videos, fonts) in the same site folder
4. Test locally using Google Chrome for similar rendering

**Performance**:
- Use images at their native size (avoid downscaling)
- Use Class 10 SD cards for resource-intensive presentations
- Limit directory depth to prevent complex folder structure issues
- Scale images to output resolution before rendering in HTML

**GPU Optimization**:
- GPU rasterization is enabled by default in firmware 6.2.x and later
- Use `image-rendering: optimizeSpeedBS` for fast bilinear filtering when scaling images to 50% or less

## JavaScript Engine

### V8 Engine Capabilities

BrightSign uses the V8 JavaScript engine embedded in Chromium. Capabilities include:
- ECMAScript standards support (version depends on Chromium version)
- ES6 features (can be disabled via registry if needed)
- Asynchronous operations (Promises, async/await)
- Web Workers for multi-threading
- Full DOM API access

### Performance Considerations

**Memory Management**:
- Each HTML widget has its own JavaScript heap
- Hard memory limit - Chromium terminates if no memory after garbage collection
- Multiple HTML widgets can overcommit JavaScript memory
- Use Chromium Web Inspector to monitor resource usage

**Execution Context**:
- BrightSign players are HTML players with interactive capabilities, not general-purpose web browsers
- Thoroughly test each page before deployment
- Avoid complex, resource-intensive web applications designed for desktop browsers

**Optimization Tips**:
- Minimize DOM manipulation operations
- Avoid memory leaks with console.log of complex objects
- Use TraceEvent system for debugging memory and performance issues
- Disable Web Inspector in production (it consumes memory continuously in OS 8.5.31+)

## DOM Manipulation

### Working with HTML Elements

Standard DOM methods work as expected:

```javascript
// Creating and appending elements
var div = document.createElement('div');
div.id = 'content';
div.className = 'container';
document.body.appendChild(div);

// Modifying elements
var element = document.getElementById('myElement');
element.textContent = 'Updated content';
element.style.backgroundColor = '#FF0000';

// Removing elements
var parent = document.getElementById('parent');
var child = document.getElementById('child');
parent.removeChild(child);
```

### Event Handling

BrightSign supports standard DOM event handling:

```javascript
// addEventListener pattern
element.addEventListener('click', function(event) {
    console.log('Element clicked');
});

// Mouse and touch events (must enable mouse_enabled)
element.addEventListener('touchstart', handleTouch);
element.addEventListener('touchmove', handleMove);
element.addEventListener('touchend', handleEnd);

// Keyboard events (USB keyboard support)
document.addEventListener('keydown', function(event) {
    console.log('Key pressed:', event.key);
});
```

### Animations

**Use CSS Animations Over JavaScript**:

JavaScript timer-based animations (including jQuery .animate()) don't efficiently use GPU resources. Use CSS animations instead:

```html
<style>
.slide-in {
    -webkit-animation-name: slideAnimation;
    -webkit-animation-duration: 2s;
    -webkit-animation-fill-mode: forwards;
}

@-webkit-keyframes slideAnimation {
    0% { -webkit-transform: translateX(-100%); }
    100% { -webkit-transform: translateX(0); }
}
</style>
```

For jQuery users, use the [Transit library](https://github.com/rstacruz/jquery.transit) which provides CSS animation-based API similar to .animate().

**Canvas Animations**:
- Canvas 2D acceleration is enabled by default (OS8+)
- Bitmap animations display smoothly when 1/3 or less of 1080p canvas
- Set canvas to 720p for larger high-quality animations

## CSS & Styling

### Advanced Styling

BrightSign supports modern CSS features based on Chromium version:

```css
/* Flexbox layouts */
.container {
    display: flex;
    justify-content: center;
    align-items: center;
}

/* Grid layouts */
.grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
}

/* Custom properties */
:root {
    --primary-color: #0066cc;
    --spacing: 16px;
}
```

### Responsive Design

Design for the player's output resolution:

```css
/* Example for 1920x1080 display */
body {
    width: 1920px;
    height: 1080px;
    margin: 0;
    padding: 0;
    overflow: hidden;
}

/* Media queries work but consider fixed resolution */
@media (min-width: 1920px) {
    .container { font-size: 24px; }
}
```

### Hardware Acceleration

**CSS Transforms**:

Always specify transforms as WebKit transforms. Don't use inline transforms:

```css
/* CORRECT: Use CSS classes */
.rotate-element {
    -webkit-animation-name: rotation;
    -webkit-animation-duration: 2s;
    -webkit-animation-iteration-count: 1;
    -webkit-animation-fill-mode: forwards;
}

@-webkit-keyframes rotation {
    0% { -webkit-transform: rotateY(0deg); }
    50% { -webkit-transform: rotateY(180deg); }
    100% { -webkit-transform: rotateY(360deg); }
}
```

**GPU Rasterization**:
- Force GPU rasterization is deprecated (enabled by default in OS8)
- Canvas 2D acceleration enabled by default (can disable with `canvas_2d_acceleration_enabled: false`)

**Web Fonts**:

Include font files for better aesthetics. Supported formats:
- TrueType Font (.ttf)
- OpenType Font (.otf)
- Web Open Font (.woff, .woff2)

```css
@font-face {
    font-family: 'CustomFont';
    src: url('fonts/customfont.woff2') format('woff2'),
         url('fonts/customfont.woff') format('woff');
}

body {
    font-family: 'CustomFont', sans-serif;
}
```

## Media Integration

### HTML5 Video/Audio

BrightSign extends standard HTML5 video with custom attributes:

```html
<!-- Basic video playback -->
<video src="video.mp4" width="1920" height="1080" autoplay loop>
    Your browser does not support video.
</video>

<!-- Streaming video -->
<video src="http://example.com/stream.m3u8" autoplay></video>
<video src="udp://239.192.1.1:5004" autoplay></video>
<video src="rtsp://example.com/stream" autoplay></video>

<!-- HDMI input -->
<video width="1920" height="1080" autoplay>
    <source src="tv:brightsign.biz/hdmi">
</video>
```

**BrightSign Streaming Parameters**:

```html
<!-- Set stream timeout -->
<video src="udp://239.192.1.1:5004" x-bs-stream-timeout="5000"></video>

<!-- Low latency mode for RTSP -->
<video src="rtsp://camera.local/stream" x-bs-stream-low-latency="1"></video>

<!-- Reduce latency by 500ms -->
<video src="udp://239.192.1.1:5004" x-bs-stream-latency="-500"></video>

<!-- Set intrinsic size for proper aspect ratio -->
<video src="stream.m3u8"
       x-bs-intrinsic-width="1920"
       x-bs-intrinsic-height="1080"></video>
```

**JavaScript Video Control**:

```javascript
var video = document.getElementById('myVideo');

// Set attributes programmatically
video.setAttribute('x-bs-stream-low-latency', '1');

// Standard video controls
video.play();
video.pause();
video.currentTime = 30; // Seek to 30 seconds

// Event listeners
video.addEventListener('loadedmetadata', function() {
    console.log('Duration:', video.duration);
});

video.addEventListener('ended', function() {
    console.log('Video finished');
});
```

**HWZ Video (Hardware Video Plane)**:

Use HWZ to route video directly to hardware compositor for better performance:

```html
<!-- Video on hardware plane, behind graphics -->
<video src="video.mp4" hwz="z-index:-1" autoplay></video>

<!-- Video with rotation -->
<video src="video.mp4" hwz="z-index:-1; transform:rot90;" autoplay></video>

<!-- Video with luma keying -->
<video src="keyed.mp4" hwz="z-index:1; luma-key:#ff0020;" autoplay></video>
```

Enable HWZ globally in BrightScript:

```brightscript
htmlWidget = CreateObject("roHtmlWidget", rect)
htmlWidget.SetHWZDefault("on")
```

**Audio Routing**:

```html
<!-- Route PCM audio to HDMI -->
<video src="video.mp4" pcmaudio="hdmi" autoplay></video>

<!-- Route compressed audio to HDMI and USB -->
<video src="video.mp4" compaudio="hdmi;usb" autoplay></video>

<!-- Multiple outputs for Series 5 -->
<video src="video.mp4" pcmaudio="hdmi-1;hdmi-2" autoplay></video>
```

**Video Decryption**:

```html
<video src="udp://239.192.1.59:5000"
       EncryptionAlgorithm="TsAesEcb"
       EncryptionKey="01030507090b0d0f00020406080a0c0e">
</video>
```

```javascript
var player = document.getElementById('secureVideo');
player.setAttribute('EncryptionAlgorithm', 'TsAesEcb');
player.setAttribute('EncryptionKey', '01030507090b0d0f00020406080a0c0e');
```

### Synchronization with BrightScript

**Message Passing from JavaScript to BrightScript**:

```javascript
// In HTML/JavaScript
var MESSAGE_PORT = require("@brightsign/messageport");
var bsMessage = new MESSAGE_PORT();

// Send message to BrightScript
bsMessage.PostBSMessage({
    event: 'videoComplete',
    result: 'success',
    timestamp: Date.now()
});
```

```brightscript
' In BrightScript
htmlWidget = CreateObject("roHtmlWidget", rect, {url: "file:///index.html"})
port = CreateObject("roMessagePort")
htmlWidget.SetPort(port)

while true
    msg = wait(0, port)
    if type(msg) = "roHtmlWidgetEvent" then
        data = msg.GetData()
        if data.reason = "message" then
            print "Message from JS: "; data.message.event
            print "Result: "; data.message.result
        end if
    end if
end while
```

**Message Passing from BrightScript to JavaScript**:

```brightscript
' In BrightScript with roHtmlWidget
htmlWidget.PostJSMessage({command: "play", videoId: "video1"})
```

```javascript
// In JavaScript
var MESSAGE_PORT = require("@brightsign/messageport");
var bsMessage = new MESSAGE_PORT();

bsMessage.addEventListener('bsmessage', function(msg) {
    console.log('Received from BrightScript:', msg);
    if (msg.command === 'play') {
        playVideo(msg.videoId);
    }
});
```

## Local Storage

### Browser Storage APIs

BrightSign supports standard web storage APIs:

**localStorage and sessionStorage**:

```javascript
// Store data
localStorage.setItem('username', 'John');
localStorage.setItem('settings', JSON.stringify({volume: 80, brightness: 100}));

// Retrieve data
var username = localStorage.getItem('username');
var settings = JSON.parse(localStorage.getItem('settings'));

// Remove data
localStorage.removeItem('username');
localStorage.clear(); // Remove all

// sessionStorage (cleared on widget close)
sessionStorage.setItem('tempData', 'value');
```

**IndexedDB**:

```javascript
// Open database
var request = indexedDB.open('MyDatabase', 1);

request.onupgradeneeded = function(event) {
    var db = event.target.result;
    var objectStore = db.createObjectStore('videos', {keyPath: 'id'});
    objectStore.createIndex('title', 'title', {unique: false});
};

request.onsuccess = function(event) {
    var db = event.target.result;

    // Add data
    var transaction = db.transaction(['videos'], 'readwrite');
    var objectStore = transaction.objectStore('videos');
    objectStore.add({id: 1, title: 'Video 1', duration: 120});

    // Read data
    var getRequest = objectStore.get(1);
    getRequest.onsuccess = function() {
        console.log('Video:', getRequest.result);
    };
};
```

### Data Persistence

**Configuring Storage in BrightScript**:

```brightscript
' Set storage path and quota
rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
config = {
    url: "file:///index.html",
    storage_path: "SD:/html-storage",
    storage_quota: "1073741824" ' 1GB in bytes (use string for >2GB)
}
htmlWidget = CreateObject("roHtmlWidget", rect, config)
```

**Configuring Storage in JavaScript**:

```javascript
var HtmlWidgetClass = require("@brightsign/htmlwidget");
var htmlwidget = new HtmlWidgetClass({
    rect: {x: 0, y: 0, width: 1920, height: 1080},
    url: "https://example.com",
    storage: {
        path: "/storage/sd/html-data",
        quota: 1073741824, // 1GB
        forceSharedStorage: false,
        forceUnsharedStorage: false
    }
});
```

### Offline Functionality

**Application Cache** (deprecated but supported):

```html
<!DOCTYPE html>
<html manifest="cache.appcache">
<head>
    <title>Offline App</title>
</head>
<body>
    <h1>Content works offline</h1>
</body>
</html>
```

**Service Workers** (preferred for modern applications):

```javascript
// Register service worker
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js')
        .then(function(registration) {
            console.log('ServiceWorker registered:', registration);
        });
}
```

## Web APIs

### Device APIs Available in BrightSign

BrightSign provides JavaScript APIs for hardware access:

**Device Information**:

```javascript
var DeviceInfoClass = require("@brightsign/deviceinfo");
var deviceInfo = new DeviceInfoClass();

console.log('Model:', deviceInfo.model);
console.log('OS Version:', deviceInfo.osVersion);
console.log('Serial Number:', deviceInfo.serialNumber);

// Check capabilities
if (deviceInfo.hasFeature('hdmi')) {
    console.log('HDMI output available');
}

// Get temperature
deviceInfo.getTemperature().then(function(temp) {
    console.log('Temperature:', temp.celsius + '°C');
});
```

**Storage Management**:

```javascript
var StorageClass = require("@brightsign/storage");
var storage = new StorageClass();

// Format SD card
storage.format("/storage/sd", "vfat").then(function() {
    console.log("SD card formatted");
});

// Safely eject
storage.eject("/storage/sd").then(function() {
    console.log("SD card can be removed");
});
```

**GPIO Control**:

```javascript
var ControlPortClass = require("@brightsign/controlport");
var controlPort = new ControlPortClass("BrightSign");

// Set GPIO output
controlPort.SetPinValue(0, true); // Set pin 0 high

// Read GPIO input
controlPort.addEventListener("controldown", function(event) {
    console.log("Button pressed on pin:", event.detail);
});
```

**Serial Communication**:

```javascript
var SerialPortClass = require("@brightsign/serialport");
var serial = new SerialPortClass("/dev/ttyUSB0");

serial.open({
    baudRate: 115200,
    dataBits: 8,
    stopBits: 1,
    parity: "none"
});

serial.on('data', function(data) {
    console.log('Received:', data);
});

serial.write('Hello\r\n');
```

**Video Output Control**:

```javascript
var VideoOutputClass = require("@brightsign/videooutput");
var videoOutput = new VideoOutputClass();

// Set video mode
videoOutput.setMode({
    width: 1920,
    height: 1080,
    refreshRate: 60
}).then(function() {
    console.log('Video mode set');
});
```

### Sensors

Temperature monitoring:

```javascript
var DeviceInfoClass = require("@brightsign/deviceinfo");
var deviceInfo = new DeviceInfoClass();

setInterval(function() {
    deviceInfo.getTemperature().then(function(temp) {
        if (temp.celsius > 70) {
            console.warn('High temperature:', temp.celsius);
        }
    });
}, 60000); // Check every minute
```

### Geolocation

Standard Geolocation API (requires network connection):

```javascript
if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(function(position) {
        console.log('Latitude:', position.coords.latitude);
        console.log('Longitude:', position.coords.longitude);
    }, function(error) {
        console.error('Geolocation error:', error);
    });
}
```

## Communication

### JavaScript to BrightScript Interaction

**Using messageport**:

The messageport is the preferred communication method.

```javascript
// JavaScript side
var MESSAGE_PORT = require("@brightsign/messageport");
var bsMessage = new MESSAGE_PORT();

// Listen for messages from BrightScript
bsMessage.addEventListener('bsmessage', function(msg) {
    console.log('Received:', JSON.stringify(msg));

    // Process commands
    switch(msg.command) {
        case 'updateContent':
            updateDisplay(msg.data);
            break;
        case 'restart':
            location.reload();
            break;
    }
});

// Send message to BrightScript
function notifyBrightScript(eventType, data) {
    bsMessage.PostBSMessage({
        type: eventType,
        timestamp: Date.now(),
        data: data
    });
}

// Example usage
document.getElementById('button').addEventListener('click', function() {
    notifyBrightScript('buttonClicked', {buttonId: 'button1'});
});
```

```brightscript
' BrightScript side
rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
port = CreateObject("roMessagePort")
config = {
    url: "file:///index.html",
    port: port
}
htmlWidget = CreateObject("roHtmlWidget", rect, config)

' Send message to JavaScript
htmlWidget.PostJSMessage({
    command: "updateContent",
    data: {title: "New Title", content: "New content"}
})

' Event loop
while true
    msg = wait(0, port)
    if type(msg) = "roHtmlWidgetEvent" then
        data = msg.GetData()

        if data.reason = "message" then
            print "Message from JS: "; data.message.type
            if data.message.type = "buttonClicked" then
                print "Button ID: "; data.message.data.buttonId
                ' Handle button click
            end if
        else if data.reason = "load-finished" then
            print "Page loaded successfully"
        else if data.reason = "load-error" then
            print "Page load error: "; data.url
        end if
    end if
end while
```

### Message Passing Patterns

**Request-Response Pattern**:

```javascript
// JavaScript - Request data
var requestId = 0;
var pendingRequests = {};

function requestData(type) {
    var id = ++requestId;

    return new Promise(function(resolve, reject) {
        pendingRequests[id] = {resolve: resolve, reject: reject};
        bsMessage.PostBSMessage({
            requestId: id,
            type: 'request',
            dataType: type
        });

        // Timeout after 5 seconds
        setTimeout(function() {
            if (pendingRequests[id]) {
                reject(new Error('Request timeout'));
                delete pendingRequests[id];
            }
        }, 5000);
    });
}

// Handle responses
bsMessage.addEventListener('bsmessage', function(msg) {
    if (msg.type === 'response' && pendingRequests[msg.requestId]) {
        pendingRequests[msg.requestId].resolve(msg.data);
        delete pendingRequests[msg.requestId];
    }
});

// Usage
requestData('currentPlaylist').then(function(playlist) {
    console.log('Playlist:', playlist);
});
```

**Event Broadcasting**:

```javascript
// JavaScript - Broadcast events
var EventEmitter = {
    emit: function(eventName, data) {
        bsMessage.PostBSMessage({
            type: 'event',
            event: eventName,
            data: data,
            timestamp: Date.now()
        });
    }
};

// Usage
EventEmitter.emit('userInteraction', {action: 'touch', x: 100, y: 200});
EventEmitter.emit('videoEnded', {videoId: 'video1', duration: 120});
```

### Multiple HTML Widget Communication

Using JavaScript htmlwidget for parent-child communication:

```javascript
// Parent widget
var HtmlWidgetClass = require("@brightsign/htmlwidget");
var childWidget = new HtmlWidgetClass({
    rect: {x: 100, y: 100, width: 800, height: 600},
    url: "child.html"
});

// Send message to child
childWidget.postMessage({command: 'play', videoId: 'video1'});

// Listen for events from child
childWidget.addEventListener('message', function(event) {
    console.log('Child message:', event);
});
```

## Performance Optimization

### Rendering Performance

**Minimize Repaints and Reflows**:

```javascript
// BAD - Multiple reflows
element.style.width = '100px';
element.style.height = '100px';
element.style.backgroundColor = 'red';

// GOOD - Single reflow
element.style.cssText = 'width: 100px; height: 100px; background-color: red;';

// BETTER - Use CSS classes
element.className = 'optimized-style';
```

**Batch DOM Operations**:

```javascript
// BAD - Multiple DOM insertions
for (var i = 0; i < 100; i++) {
    var div = document.createElement('div');
    div.textContent = 'Item ' + i;
    container.appendChild(div);
}

// GOOD - Build fragment first
var fragment = document.createDocumentFragment();
for (var i = 0; i < 100; i++) {
    var div = document.createElement('div');
    div.textContent = 'Item ' + i;
    fragment.appendChild(div);
}
container.appendChild(fragment);
```

**Use requestAnimationFrame**:

```javascript
// Smooth animation loop
function animate() {
    // Update animation state
    updatePosition();

    // Request next frame
    requestAnimationFrame(animate);
}

requestAnimationFrame(animate);
```

**Hardware-Accelerated Properties**:

Prefer CSS properties that use GPU acceleration:

```css
/* GPU-accelerated */
.animated {
    transform: translateX(100px);
    opacity: 0.5;
}

/* Avoid - causes repaints */
.slow {
    left: 100px;
    background-color: rgba(0, 0, 0, 0.5);
}
```

### Memory Management

**Avoid Memory Leaks**:

```javascript
// Remove event listeners when done
var handler = function() { /* ... */ };
element.addEventListener('click', handler);

// Later, when element is removed
element.removeEventListener('click', handler);

// Clear intervals and timeouts
var interval = setInterval(update, 1000);
clearInterval(interval);

// Null references to large objects
var largeArray = new Array(1000000);
// ... use array ...
largeArray = null; // Allow garbage collection
```

**Manage Video Elements**:

```javascript
// Release video resources when switching
function switchVideo(newSource) {
    var video = document.getElementById('player');

    // Important: set src to empty to release resources
    video.src = '';

    // Create new video element
    video = document.createElement('video');
    video.id = 'player';
    video.src = newSource;
    video.play();

    document.getElementById('container').appendChild(video);
}
```

**Monitor Memory Usage**:

```javascript
// Check available memory (if performance.memory is available)
if (performance.memory) {
    console.log('Used JS Heap:', performance.memory.usedJSHeapSize);
    console.log('Total JS Heap:', performance.memory.totalJSHeapSize);
    console.log('Heap Limit:', performance.memory.jsHeapSizeLimit);
}
```

### Profiling

**Web Inspector for Debugging**:

Enable in BrightScript:

```brightscript
' Enable Web Inspector
reg = CreateObject("roRegistrySection", "html")
reg.Write("enable_web_inspector", "1")
reg.Flush()

' Create widget with inspector
rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
config = {
    url: "file:///index.html",
    inspector_server: {port: 2999}
}
htmlWidget = CreateObject("roHtmlWidget", rect, config)
```

Access from Chrome on same network:
1. Navigate to `chrome://inspect/devices`
2. Configure with player IP and port (e.g., `192.168.1.100:2999`)
3. Click "Inspect" to open DevTools

**TraceEvent System**:

Enable trace events for advanced profiling:

```javascript
var registryClass = require("@brightsign/registry");
var registry = new registryClass();

registry.write("html", {
    "tracecategories": "toplevel,blink_gc,disabled-by-default-memory-infra",
    "tracemaxsnapshots": "25",
    "tracemonitorinterval": "60"
}).then(function() {
    console.log("TraceEvent enabled");
});
```

Create `brightsign-webinspector` directory on SD card. JSON trace files will be written there for import into Chrome's `chrome://tracing`.

**Performance Monitoring**:

```javascript
var DeviceInfoClass = require("@brightsign/deviceinfo");
var deviceInfo = new DeviceInfoClass();

// Get system load statistics
deviceInfo.getLoadStatistics('loadavg').then(function(stats) {
    console.log('System load:', stats);
});

deviceInfo.getLoadStatistics('meminfo').then(function(stats) {
    console.log('Memory info:', stats);
});
```

**Console Logging Best Practices**:

```javascript
// Disable console in production
if (PRODUCTION) {
    console.log = function() {};
    console.error = function() {};
    console.warn = function() {};
}

// Use performance markers
performance.mark('video-load-start');
// ... load video ...
performance.mark('video-load-end');
performance.measure('video-load', 'video-load-start', 'video-load-end');

var measures = performance.getEntriesByType('measure');
console.log('Video load time:', measures[0].duration, 'ms');
```

## Complete Example: Interactive Video Player

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>BrightSign Video Player</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            width: 1920px;
            height: 1080px;
            background-color: #000;
            overflow: hidden;
        }

        #videoContainer {
            position: absolute;
            width: 100%;
            height: 100%;
        }

        #player {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        #controls {
            position: absolute;
            bottom: 50px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(0, 0, 0, 0.7);
            padding: 20px;
            border-radius: 10px;
        }

        button {
            padding: 15px 30px;
            margin: 0 10px;
            font-size: 18px;
            border: none;
            border-radius: 5px;
            background-color: #0066cc;
            color: white;
            cursor: pointer;
        }

        button:hover {
            background-color: #0052a3;
        }
    </style>
</head>
<body>
    <div id="videoContainer">
        <video id="player" hwz="z-index:-1"></video>
    </div>

    <div id="controls">
        <button id="playBtn">Play</button>
        <button id="pauseBtn">Pause</button>
        <button id="nextBtn">Next</button>
    </div>

    <script>
        // BrightSign messageport for communication
        var MESSAGE_PORT = require("@brightsign/messageport");
        var bsMessage = new MESSAGE_PORT();

        // Device info
        var DeviceInfoClass = require("@brightsign/deviceinfo");
        var deviceInfo = new DeviceInfoClass();

        console.log('Player model:', deviceInfo.model);
        console.log('OS version:', deviceInfo.osVersion);

        // Video player state
        var currentVideoIndex = 0;
        var playlist = [];
        var player = document.getElementById('player');

        // Initialize
        function init() {
            // Request playlist from BrightScript
            bsMessage.PostBSMessage({
                type: 'request',
                action: 'getPlaylist'
            });

            // Setup event listeners
            setupVideoEvents();
            setupControls();
            setupMessageListener();
        }

        function setupVideoEvents() {
            player.addEventListener('loadedmetadata', function() {
                console.log('Video loaded, duration:', player.duration);
                notifyBrightScript('videoLoaded', {
                    duration: player.duration,
                    index: currentVideoIndex
                });
            });

            player.addEventListener('ended', function() {
                console.log('Video ended');
                notifyBrightScript('videoEnded', {index: currentVideoIndex});
                playNext();
            });

            player.addEventListener('error', function(e) {
                console.error('Video error:', e);
                notifyBrightScript('videoError', {
                    index: currentVideoIndex,
                    error: player.error.code
                });
            });
        }

        function setupControls() {
            document.getElementById('playBtn').addEventListener('click', function() {
                player.play();
                notifyBrightScript('userAction', {action: 'play'});
            });

            document.getElementById('pauseBtn').addEventListener('click', function() {
                player.pause();
                notifyBrightScript('userAction', {action: 'pause'});
            });

            document.getElementById('nextBtn').addEventListener('click', function() {
                playNext();
                notifyBrightScript('userAction', {action: 'next'});
            });
        }

        function setupMessageListener() {
            bsMessage.addEventListener('bsmessage', function(msg) {
                console.log('Message from BrightScript:', msg);

                switch(msg.type) {
                    case 'playlist':
                        playlist = msg.videos;
                        if (playlist.length > 0) {
                            loadVideo(0);
                        }
                        break;

                    case 'command':
                        handleCommand(msg);
                        break;

                    case 'updateSettings':
                        updateSettings(msg.settings);
                        break;
                }
            });
        }

        function handleCommand(msg) {
            switch(msg.command) {
                case 'play':
                    player.play();
                    break;
                case 'pause':
                    player.pause();
                    break;
                case 'seek':
                    player.currentTime = msg.position;
                    break;
                case 'setVolume':
                    player.volume = msg.volume;
                    break;
            }
        }

        function loadVideo(index) {
            if (index >= 0 && index < playlist.length) {
                currentVideoIndex = index;

                // Clear current video to release resources
                player.src = '';

                // Load new video
                player.src = playlist[index].url;
                player.load();

                console.log('Loading video:', playlist[index].title);
            }
        }

        function playNext() {
            var nextIndex = (currentVideoIndex + 1) % playlist.length;
            loadVideo(nextIndex);
            player.play();
        }

        function notifyBrightScript(eventType, data) {
            bsMessage.PostBSMessage({
                type: 'event',
                event: eventType,
                timestamp: Date.now(),
                data: data
            });
        }

        function updateSettings(settings) {
            if (settings.volume !== undefined) {
                player.volume = settings.volume;
            }

            // Save to localStorage
            localStorage.setItem('settings', JSON.stringify(settings));
        }

        // Load saved settings
        var savedSettings = localStorage.getItem('settings');
        if (savedSettings) {
            updateSettings(JSON.parse(savedSettings));
        }

        // Start application
        init();

        // Notify BrightScript that page is ready
        notifyBrightScript('ready', {});
    </script>
</body>
</html>
```

Corresponding BrightScript code:

```brightscript
Sub Main()
    ' Create HTML widget
    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
    port = CreateObject("roMessagePort")

    config = {
        url: "file:///sd:/index.html",
        port: port,
        mouse_enabled: true,
        storage_path: "SD:/html-storage",
        storage_quota: "536870912"  ' 512MB
    }

    htmlWidget = CreateObject("roHtmlWidget", rect, config)
    htmlWidget.Show()

    ' Playlist data
    playlist = [
        {title: "Video 1", url: "file:///sd:/videos/video1.mp4"},
        {title: "Video 2", url: "file:///sd:/videos/video2.mp4"},
        {title: "Video 3", url: "file:///sd:/videos/video3.mp4"}
    ]

    ' Event loop
    while true
        msg = wait(0, port)

        if type(msg) = "roHtmlWidgetEvent" then
            data = msg.GetData()

            if data.reason = "message" then
                ' Handle messages from JavaScript
                HandleJavaScriptMessage(htmlWidget, data.message)

            else if data.reason = "load-finished" then
                print "Page loaded successfully"

            else if data.reason = "load-error" then
                print "Page load error: "; data.url
            end if
        end if
    end while
End Sub

Sub HandleJavaScriptMessage(htmlWidget as Object, message as Object)
    print "Message from JS: "; message.type

    if message.type = "request" and message.action = "getPlaylist" then
        ' Send playlist to JavaScript
        htmlWidget.PostJSMessage({
            type: "playlist",
            videos: GetPlaylist()
        })

    else if message.type = "event" then
        print "Event: "; message.event

        if message.event = "videoEnded" then
            print "Video ended at index: "; message.data.index

        else if message.event = "userAction" then
            print "User action: "; message.data.action
            LogUserAction(message.data.action)
        end if
    end if
End Sub

Function GetPlaylist() as Object
    return [
        {title: "Video 1", url: "file:///sd:/videos/video1.mp4"},
        {title: "Video 2", url: "file:///sd:/videos/video2.mp4"},
        {title: "Video 3", url: "file:///sd:/videos/video3.mp4"}
    ]
End Function

Sub LogUserAction(action as String)
    ' Log to registry or file
    print "User performed: "; action
End Sub
```

## Summary

JavaScript and HTML5 playback on BrightSign provides powerful capabilities for creating interactive media experiences:

- **HTML5 Support**: Chromium-based rendering with modern web standards
- **JavaScript Engine**: V8 engine with full DOM API access
- **DOM Manipulation**: Standard web APIs with hardware-optimized rendering
- **CSS & Styling**: Modern CSS3 features with GPU acceleration
- **Media Integration**: Extended HTML5 video with BrightSign-specific features
- **Local Storage**: Full support for localStorage, IndexedDB, and persistent data
- **Web APIs**: BrightSign-specific device APIs for hardware access
- **Communication**: Robust messageport system for JavaScript-BrightScript interaction
- **Performance**: Hardware acceleration, profiling tools, and optimization techniques

Always test thoroughly on target hardware, monitor resource usage, and disable debugging features in production deployments.


---

[↑ Part 3: JavaScript Development](README.md) | [Next →](02-javascript-node-programs.md)
