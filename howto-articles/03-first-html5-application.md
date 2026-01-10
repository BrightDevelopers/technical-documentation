# Your First HTML5 Application

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide walks you through building and deploying a web-based application on BrightSign using HTML, CSS, and JavaScript. If you're a web developer, this approach will feel familiar—you'll use the same technologies you already know.

### Why HTML5 on BrightSign?

BrightSign players include a Chromium-based rendering engine, providing:

- Modern JavaScript (ES6+, async/await)
- CSS3 animations and flexbox/grid layouts
- Canvas and WebGL for graphics
- Standard web APIs (fetch, WebSocket, localStorage)
- BrightSign-specific JavaScript APIs for hardware access

### Chromium Versions

| BrightSign OS | Chromium Version | Notable Features |
|---------------|-----------------|------------------|
| 9.1.x | 120 | Latest web standards |
| 9.0.x | 87 | ES2020, optional chaining |
| 8.5.x | 87 | WebGL 2.0 |
| 8.1-8.4.x | 69 | CSS Grid, ES2018 |

Check compatibility at [caniuse.com](https://caniuse.com) for your target Chromium version.

---

## Prerequisites

- BrightSign player with HTML5 support (all current models)
- SD card formatted as FAT32 or exFAT
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))
- Basic knowledge of HTML, CSS, and JavaScript

---

## Critical Concept: The autorun.brs Requirement

**Even HTML5 applications need a BrightScript launcher.**

BrightSign players always boot by executing `autorun.brs`. For HTML applications, this file creates an `roHtmlWidget` that loads your web content.

Think of it as the bridge between the player's boot process and your web application.

---

## Step 1: Create the BrightScript Launcher

Create `autorun.brs`:

```brightscript
' autorun.brs - HTML5 Application Launcher
Sub Main()
    ' Set video mode for your display
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Define full-screen rectangle
    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)

    ' Configure the HTML widget
    config = {
        url: "file:///sd:/index.html",
        mouse_enabled: true,
        storage_path: "SD:/html-storage",
        storage_quota: 52428800  ' 50MB for localStorage
    }

    ' Create and display the widget
    htmlWidget = CreateObject("roHtmlWidget", rect, config)
    htmlWidget.Show()

    ' Create message port for events
    msgPort = CreateObject("roMessagePort")
    htmlWidget.SetPort(msgPort)

    print "HTML5 application started"

    ' Event loop - keeps the application running
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roHtmlWidgetEvent" then
            eventData = msg.GetData()

            if eventData.reason = "load-finished" then
                print "Page loaded: "; eventData.url

            else if eventData.reason = "load-error" then
                print "Load error: "; eventData.url
                print "Error: "; eventData.message

            else if eventData.reason = "message" then
                ' Handle messages from JavaScript
                print "JS message: "; formatJson(eventData.message)
            end if
        end if
    end while
End Sub
```

---

## Step 2: Create Your HTML Application

Create `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=1920, height=1080">
    <title>My BrightSign App</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            width: 1920px;
            height: 1080px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: white;
            overflow: hidden;
        }

        .container {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            height: 100%;
            padding: 50px;
        }

        h1 {
            font-size: 72px;
            font-weight: 300;
            margin-bottom: 20px;
            text-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
        }

        .subtitle {
            font-size: 28px;
            color: #94a3b8;
            margin-bottom: 60px;
        }

        .info-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px 60px;
            text-align: center;
        }

        .time {
            font-size: 96px;
            font-weight: 200;
            margin-bottom: 10px;
        }

        .date {
            font-size: 32px;
            color: #94a3b8;
        }

        .device-info {
            margin-top: 60px;
            font-size: 18px;
            color: #64748b;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello BrightSign!</h1>
        <p class="subtitle">Your first HTML5 application is running</p>

        <div class="info-card">
            <div class="time" id="time">--:--:--</div>
            <div class="date" id="date">Loading...</div>
        </div>

        <div class="device-info" id="device-info">
            Detecting device...
        </div>
    </div>

    <script>
        // Update clock every second
        function updateClock() {
            const now = new Date();

            const time = now.toLocaleTimeString('en-US', {
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            });

            const date = now.toLocaleDateString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });

            document.getElementById('time').textContent = time;
            document.getElementById('date').textContent = date;
        }

        // Get device information using BrightSign API
        function getDeviceInfo() {
            try {
                const DeviceInfo = require('@brightsign/deviceinfo');
                const device = new DeviceInfo();

                const info = `Model: ${device.model} | Serial: ${device.serialNumber} | OS: ${device.osVersion}`;
                document.getElementById('device-info').textContent = info;

                console.log('Device info loaded successfully');
            } catch (e) {
                // Running in browser or API not available
                document.getElementById('device-info').textContent =
                    'Running in development mode (BrightSign APIs not available)';
                console.log('BrightSign APIs not available:', e.message);
            }
        }

        // Initialize
        updateClock();
        setInterval(updateClock, 1000);
        getDeviceInfo();

        console.log('BrightSign HTML5 app initialized');
    </script>
</body>
</html>
```

---

## Step 3: Deploy and Test

1. Copy both files to your SD card root:
   ```
   /autorun.brs
   /index.html
   ```

2. Insert SD card into player and power on

3. You should see the clock application on your display

---

## Understanding roHtmlWidget Configuration

The `roHtmlWidget` accepts many configuration options:

```brightscript
config = {
    ' Required
    url: "file:///sd:/index.html",  ' Local file or remote URL

    ' Display options
    mouse_enabled: true,             ' Enable touch/mouse
    scrollbar_enabled: false,        ' Show scrollbars
    focus_enabled: true,             ' Allow keyboard focus

    ' Storage for localStorage/IndexedDB
    storage_path: "SD:/html-storage",
    storage_quota: 52428800,         ' Bytes (50MB)

    ' Performance
    javascript_enabled: true,
    webstorage_enabled: true,

    ' Debugging
    inspector_server: {port: 2999},  ' Enable Web Inspector

    ' Security
    security_params: {
        websecurity: false,          ' Disable CORS (dev only!)
        camera_enabled: false,
        microphone_enabled: false
    }
}
```

---

## Step 4: Adding Interactivity

Let's create a touch-interactive slideshow:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Interactive Slideshow</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            width: 1920px;
            height: 1080px;
            font-family: sans-serif;
            background: #000;
            overflow: hidden;
        }

        .slideshow {
            position: relative;
            width: 100%;
            height: 100%;
        }

        .slide {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
            opacity: 0;
            transition: opacity 0.5s ease-in-out;
        }

        .slide.active {
            opacity: 1;
        }

        .slide img {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
        }

        .slide-content {
            text-align: center;
            color: white;
        }

        .slide-content h2 {
            font-size: 64px;
            margin-bottom: 20px;
        }

        .slide-content p {
            font-size: 32px;
            color: #ccc;
        }

        .nav-hint {
            position: absolute;
            bottom: 40px;
            left: 50%;
            transform: translateX(-50%);
            color: rgba(255, 255, 255, 0.5);
            font-size: 24px;
        }

        .progress {
            position: absolute;
            bottom: 0;
            left: 0;
            height: 4px;
            background: #3b82f6;
            transition: width 0.1s linear;
        }

        /* Touch zones */
        .touch-zone {
            position: absolute;
            top: 0;
            height: 100%;
            width: 20%;
            cursor: pointer;
        }

        .touch-zone.left {
            left: 0;
        }

        .touch-zone.right {
            right: 0;
        }
    </style>
</head>
<body>
    <div class="slideshow">
        <div class="slide active" style="background: linear-gradient(135deg, #667eea, #764ba2);">
            <div class="slide-content">
                <h2>Welcome</h2>
                <p>Touch left or right to navigate</p>
            </div>
        </div>

        <div class="slide" style="background: linear-gradient(135deg, #f093fb, #f5576c);">
            <div class="slide-content">
                <h2>Slide 2</h2>
                <p>Beautiful gradient backgrounds</p>
            </div>
        </div>

        <div class="slide" style="background: linear-gradient(135deg, #4facfe, #00f2fe);">
            <div class="slide-content">
                <h2>Slide 3</h2>
                <p>Smooth transitions</p>
            </div>
        </div>

        <div class="slide" style="background: linear-gradient(135deg, #43e97b, #38f9d7);">
            <div class="slide-content">
                <h2>Slide 4</h2>
                <p>Touch or wait for auto-advance</p>
            </div>
        </div>

        <!-- Touch zones for navigation -->
        <div class="touch-zone left" id="prev"></div>
        <div class="touch-zone right" id="next"></div>

        <div class="nav-hint">Tap left/right to navigate • Auto-advances every 5 seconds</div>
        <div class="progress" id="progress"></div>
    </div>

    <script>
        const slides = document.querySelectorAll('.slide');
        const progress = document.getElementById('progress');
        let currentSlide = 0;
        let autoAdvanceTimer;
        let progressTimer;
        const SLIDE_DURATION = 5000; // 5 seconds

        function showSlide(index) {
            // Wrap around
            if (index >= slides.length) index = 0;
            if (index < 0) index = slides.length - 1;

            // Update active slide
            slides.forEach(slide => slide.classList.remove('active'));
            slides[index].classList.add('active');
            currentSlide = index;

            console.log(`Showing slide ${index + 1} of ${slides.length}`);

            // Reset auto-advance
            resetAutoAdvance();
        }

        function nextSlide() {
            showSlide(currentSlide + 1);
        }

        function prevSlide() {
            showSlide(currentSlide - 1);
        }

        function resetAutoAdvance() {
            // Clear existing timers
            clearTimeout(autoAdvanceTimer);
            clearInterval(progressTimer);

            // Reset progress bar
            progress.style.width = '0%';

            // Animate progress bar
            let elapsed = 0;
            const interval = 100;
            progressTimer = setInterval(() => {
                elapsed += interval;
                const percent = (elapsed / SLIDE_DURATION) * 100;
                progress.style.width = percent + '%';

                if (elapsed >= SLIDE_DURATION) {
                    clearInterval(progressTimer);
                }
            }, interval);

            // Set auto-advance timer
            autoAdvanceTimer = setTimeout(nextSlide, SLIDE_DURATION);
        }

        // Touch/click navigation
        document.getElementById('prev').addEventListener('click', prevSlide);
        document.getElementById('next').addEventListener('click', nextSlide);

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (e.key === 'ArrowRight' || e.key === ' ') {
                nextSlide();
            } else if (e.key === 'ArrowLeft') {
                prevSlide();
            }
        });

        // Initialize
        resetAutoAdvance();
        console.log('Slideshow initialized');
    </script>
</body>
</html>
```

---

## Step 5: Using BrightSign JavaScript APIs

BrightSign provides Node.js-style APIs for hardware access. These are available via `require()`.

### Device Information

```javascript
// Get device info
const DeviceInfo = require('@brightsign/deviceinfo');
const device = new DeviceInfo();

console.log('Model:', device.model);
console.log('Serial:', device.serialNumber);
console.log('OS Version:', device.osVersion);
console.log('Boot Version:', device.bootVersion);

// Get temperature
device.getTemperature().then(temp => {
    console.log('Temperature:', temp.celsius + '°C');
});

// Get memory info
device.getLoadStatistics('meminfo').then(stats => {
    console.log('Memory:', stats);
});
```

### Communicating with BrightScript

Use `@brightsign/messageport` to exchange data between JavaScript and BrightScript:

**JavaScript side:**

```javascript
const MessagePort = require('@brightsign/messageport');
const bsMessage = new MessagePort();

// Send message to BrightScript
function sendToBrightScript(eventType, data) {
    bsMessage.PostBSMessage({
        type: eventType,
        data: data,
        timestamp: Date.now()
    });
}

// Receive messages from BrightScript
bsMessage.addEventListener('bsmessage', (msg) => {
    console.log('Message from BrightScript:', msg);

    if (msg.command === 'updateContent') {
        updateDisplay(msg.data);
    } else if (msg.command === 'reload') {
        location.reload();
    }
});

// Example: notify BrightScript of user interaction
document.getElementById('button').addEventListener('click', () => {
    sendToBrightScript('buttonClicked', { buttonId: 'main-button' });
});
```

**BrightScript side (in autorun.brs):**

```brightscript
' In the event loop
while true
    msg = wait(0, msgPort)

    if type(msg) = "roHtmlWidgetEvent" then
        eventData = msg.GetData()

        if eventData.reason = "message" then
            ' Message from JavaScript
            jsMessage = eventData.message

            if jsMessage.type = "buttonClicked" then
                print "Button clicked: "; jsMessage.data.buttonId
                ' Send response back
                htmlWidget.PostJSMessage({command: "acknowledged"})
            end if
        end if
    end if
end while
```

### File System Access

```javascript
const FileSystem = require('@brightsign/filesystem');
const fs = new FileSystem();

// Read file
fs.readFile('/storage/sd/config.json')
    .then(content => {
        const config = JSON.parse(content);
        console.log('Config loaded:', config);
    })
    .catch(err => console.error('Read error:', err));

// Write file
const data = JSON.stringify({ lastRun: Date.now() });
fs.writeFile('/storage/sd/state.json', data)
    .then(() => console.log('State saved'))
    .catch(err => console.error('Write error:', err));
```

### Network Status

```javascript
const NetworkConfig = require('@brightsign/networkconfiguration');
const network = new NetworkConfig(0); // 0 = ethernet, 1 = wifi

network.getConfig().then(config => {
    console.log('IP Address:', config.ip4_address);
    console.log('Gateway:', config.ip4_gateway);
    console.log('DNS:', config.dns_servers);
});
```

---

## Step 6: Debugging with Web Inspector

Enable Chrome DevTools debugging to inspect your HTML application in real-time.

### Enable Web Inspector

Update `autorun.brs`:

```brightscript
config = {
    url: "file:///sd:/index.html",
    inspector_server: {port: 2999}  ' Enable inspector on port 2999
}
```

Also enable in registry (one-time setup):

```brightscript
reg = CreateObject("roRegistrySection", "html")
reg.Write("enable_web_inspector", "1")
reg.Flush()
```

### Connect from Chrome

1. Open Chrome on your development machine
2. Navigate to `chrome://inspect`
3. Click "Configure..." and add `<player-ip>:2999`
4. Your player's page should appear under "Remote Target"
5. Click "inspect" to open DevTools

You can now:
- View console logs
- Inspect DOM elements
- Debug JavaScript with breakpoints
- Profile performance
- Monitor network requests

---

## Step 7: Fetching Remote Data

Here's a complete example that fetches and displays data from an API:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Weather Display</title>
    <style>
        body {
            width: 1920px;
            height: 1080px;
            font-family: sans-serif;
            background: linear-gradient(to bottom, #1e3c72, #2a5298);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .weather-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 30px;
            padding: 60px 80px;
            text-align: center;
            min-width: 600px;
        }

        .location {
            font-size: 36px;
            margin-bottom: 20px;
            color: #a5b4fc;
        }

        .temperature {
            font-size: 144px;
            font-weight: 200;
            line-height: 1;
        }

        .description {
            font-size: 32px;
            margin-top: 20px;
            text-transform: capitalize;
        }

        .details {
            display: flex;
            justify-content: space-around;
            margin-top: 40px;
            padding-top: 40px;
            border-top: 1px solid rgba(255, 255, 255, 0.2);
        }

        .detail {
            text-align: center;
        }

        .detail-value {
            font-size: 36px;
            font-weight: 300;
        }

        .detail-label {
            font-size: 18px;
            color: #a5b4fc;
            margin-top: 5px;
        }

        .error {
            color: #f87171;
            font-size: 24px;
        }

        .loading {
            font-size: 32px;
            color: #a5b4fc;
        }

        .last-update {
            margin-top: 40px;
            font-size: 18px;
            color: rgba(255, 255, 255, 0.5);
        }
    </style>
</head>
<body>
    <div class="weather-card">
        <div id="content">
            <p class="loading">Loading weather data...</p>
        </div>
        <div class="last-update" id="last-update"></div>
    </div>

    <script>
        // Configuration
        const API_KEY = 'your_api_key_here'; // Get from openweathermap.org
        const CITY = 'San Francisco';
        const UPDATE_INTERVAL = 600000; // 10 minutes

        async function fetchWeather() {
            const content = document.getElementById('content');
            const lastUpdate = document.getElementById('last-update');

            try {
                // Using OpenWeatherMap API as example
                const response = await fetch(
                    `https://api.openweathermap.org/data/2.5/weather?q=${CITY}&appid=${API_KEY}&units=imperial`
                );

                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}`);
                }

                const data = await response.json();

                content.innerHTML = `
                    <div class="location">${data.name}, ${data.sys.country}</div>
                    <div class="temperature">${Math.round(data.main.temp)}°</div>
                    <div class="description">${data.weather[0].description}</div>
                    <div class="details">
                        <div class="detail">
                            <div class="detail-value">${data.main.humidity}%</div>
                            <div class="detail-label">Humidity</div>
                        </div>
                        <div class="detail">
                            <div class="detail-value">${Math.round(data.wind.speed)} mph</div>
                            <div class="detail-label">Wind</div>
                        </div>
                        <div class="detail">
                            <div class="detail-value">${Math.round(data.main.feels_like)}°</div>
                            <div class="detail-label">Feels Like</div>
                        </div>
                    </div>
                `;

                lastUpdate.textContent = `Last updated: ${new Date().toLocaleTimeString()}`;
                console.log('Weather data updated');

            } catch (error) {
                console.error('Weather fetch error:', error);
                content.innerHTML = `
                    <p class="error">Unable to load weather data</p>
                    <p class="error" style="font-size: 18px;">${error.message}</p>
                `;
            }
        }

        // Initial fetch
        fetchWeather();

        // Update periodically
        setInterval(fetchWeather, UPDATE_INTERVAL);
    </script>
</body>
</html>
```

---

## Best Practices

### 1. Design for Fixed Resolution

Unlike responsive websites, signage displays have fixed dimensions:

```css
body {
    width: 1920px;
    height: 1080px;
    overflow: hidden;  /* Prevent scrolling */
}
```

### 2. Use CSS Animations Over JavaScript

CSS animations are GPU-accelerated and perform better:

```css
/* GOOD - CSS animation */
.fade-in {
    animation: fadeIn 0.5s ease-in-out;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}
```

```javascript
// AVOID - JavaScript animation
// setInterval(() => element.style.opacity = ..., 16);
```

### 3. Handle Offline Gracefully

```javascript
// Check connectivity
window.addEventListener('online', () => {
    console.log('Network restored');
    refreshContent();
});

window.addEventListener('offline', () => {
    console.log('Network lost');
    showOfflineMessage();
});

// Cache critical data
localStorage.setItem('lastData', JSON.stringify(data));
```

### 4. Manage Memory

```javascript
// Clear large objects when done
let largeData = fetchLargeDataset();
processData(largeData);
largeData = null; // Allow garbage collection

// Remove event listeners when appropriate
element.removeEventListener('click', handler);
```

### 5. Disable Console in Production

```javascript
if (PRODUCTION) {
    console.log = () => {};
    console.warn = () => {};
    console.error = () => {};
}
```

---

## Common Issues and Solutions

### CORS Errors

If fetching from external APIs:

```brightscript
' In autorun.brs - DEVELOPMENT ONLY
config = {
    url: "file:///sd:/index.html",
    security_params: {websecurity: false}
}
```

Better solution: Use a proxy server or APIs that support CORS.

### Fonts Not Loading

Include fonts locally:

```css
@font-face {
    font-family: 'CustomFont';
    src: url('fonts/custom.woff2') format('woff2');
}
```

### Video in HTML Not Playing

Use HWZ (Hardware Video Zone) for better performance:

```html
<video src="video.mp4" hwz="z-index:-1" autoplay loop></video>
```

### Touch Not Working

Ensure mouse is enabled in config:

```brightscript
config = {
    url: "file:///sd:/index.html",
    mouse_enabled: true
}
```

---

## Exercises

1. **Create a digital menu board** with multiple pages that auto-rotate

2. **Build a touch kiosk** with buttons that send messages to BrightScript

3. **Make a dashboard** that fetches data from multiple APIs and displays charts

4. **Add local storage** to persist user preferences across reboots

---

## Next Steps

- [JavaScript Development Guide](../documentation/part-3-javascript-development/01-javascript-playback.md) - Full API reference
- [player-examples repository](https://github.com/BrightDevelopers/player-examples) - Working code samples

---

[← Previous: Your First BrightScript Application](02-first-brightscript-application.md) | [Back to How-To Articles](README.md)
