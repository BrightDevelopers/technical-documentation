# Chapter 8: Debugging JavaScript

[← Back to Part 3: JavaScript Development](README.md) | [↑ Main](../README.md)

---

## Introduction

Debugging JavaScript applications on BrightSign players requires specialized techniques due to the embedded Chromium environment and Node.js runtime. This chapter covers comprehensive debugging strategies for both browser-based HTML content and Node.js applications running on BrightSign hardware.

## Browser DevTools

### Remote Debugging Setup

BrightSign players support Chromium's remote debugging protocol, enabling Chrome DevTools access over the network.

**Enabling Web Inspector via BrightScript:**

```brightscript
' Enable web inspector registry key (required for BOS 8.5.31+)
reg = CreateObject("roRegistrySection", "html")
reg.Write("enable_web_inspector", "1")
reg.Flush()

' Configure roHtmlWidget with inspector
r = CreateObject("roRectangle", 0, 0, 1920, 1080)
config = {
    url: "file:///sd:/index.html"
    inspector_server: { port: 2999 }
    nodejs_enabled: true
}
widget = CreateObject("roHtmlWidget", r, config)
widget.Show()
```

**Accessing Remote Inspector:**

1. Open Chrome browser on development machine
2. Navigate to `chrome://inspect/#devices`
3. Click **Configure** and add player IP with port: `192.168.1.100:2999`
4. Click **Inspect** when page appears in device list

**Security Warning:** Disable web inspector in production deployments. The console logs data to memory even when disconnected, causing memory exhaustion and crashes.

### Console Access

**JavaScript Console Methods:**

```javascript
// Standard output
console.log('Debug message:', variable);
console.info('Information:', data);
console.warn('Warning:', issue);
console.error('Error:', error);

// Grouped logging
console.group('Processing Data');
console.log('Step 1: Load');
console.log('Step 2: Transform');
console.groupEnd();

// Table formatting
console.table([
    { id: 1, name: 'Item A' },
    { id: 2, name: 'Item B' }
]);

// Performance timing
console.time('operation');
performExpensiveTask();
console.timeEnd('operation');
```

**Accessing Console Output:**

- Remote DevTools: `chrome://inspect` connected to player
- Local logs: Available via Diagnostic Web Server (DWS) logs endpoint
- Serial/SSH/Telnet: Standard output visible in terminal

### Network Inspection

Monitor network requests through DevTools Network tab:

```javascript
// Track XHR requests
const xhr = new XMLHttpRequest();
xhr.addEventListener('load', function() {
    console.log('Response received:', this.responseText);
});
xhr.addEventListener('error', function() {
    console.error('Request failed:', this.status);
});
xhr.open('GET', '/api/data');
xhr.send();

// Fetch API with detailed logging
async function fetchWithLogging(url) {
    console.log('Fetching:', url);
    try {
        const response = await fetch(url);
        console.log('Status:', response.status);
        console.log('Headers:', [...response.headers.entries()]);
        const data = await response.json();
        console.log('Data:', data);
        return data;
    } catch (error) {
        console.error('Fetch error:', error);
        throw error;
    }
}
```

**Network Panel Features:**

- Request/response headers inspection
- Timing waterfall analysis
- Payload examination
- WebSocket frame inspection

### Chromium Version Compatibility

BrightSign players use older Chromium versions. For Web Inspector compatibility, download matching Chrome builds:

- Linux x64: Chromium 576753
- Mac: Chromium 576753
- Windows 64-bit: Chromium 576753

Download from: `https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/`

## Node.js Debugging

### Inspector Protocol

Enable Node.js inspector when initializing roHtmlWidget:

```brightscript
config = {
    url: "file:///sd:/app.html"
    nodejs_enabled: true
    inspector_server: { port: 3000 }
    brightsign_js_objects_enabled: true
}
widget = CreateObject("roHtmlWidget", r, config)
```

**Accessing Node.js Debugger:**

1. Navigate to `chrome://inspect` in Chrome
2. Add target: `<player-ip>:3000`
3. Click **Inspect** to open debugger

**Programmatic Debugging:**

```javascript
// Node.js debugging from code
const inspector = require('inspector');

// Start inspector session
inspector.open(9229, '0.0.0.0', false);

// Trigger breakpoint programmatically
debugger;

// Close inspector
inspector.close();
```

### Debugging Tools

**Breakpoints in Node.js:**

```javascript
// Conditional breakpoint
function processData(items) {
    for (let i = 0; i < items.length; i++) {
        if (items[i].id === 'debug-target') {
            debugger; // Execution pauses here
        }
        process(items[i]);
    }
}

// Exception breakpoints
process.on('uncaughtException', (error) => {
    console.error('Uncaught exception:', error.stack);
    debugger; // Pause on unhandled errors
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled rejection:', reason);
    debugger;
});
```

**Module Debugging:**

```javascript
// Debug module loading
console.log('Module paths:', module.paths);

// Trace require calls
const Module = require('module');
const originalRequire = Module.prototype.require;

Module.prototype.require = function(id) {
    console.log('Requiring:', id);
    return originalRequire.apply(this, arguments);
};
```

### Profiling

**CPU Profiling:**

```javascript
const fs = require('fs');
const inspector = require('inspector');
const session = new inspector.Session();

session.connect();

// Start CPU profiling
session.post('Profiler.enable', () => {
    session.post('Profiler.start', () => {
        // Code to profile
        performExpensiveOperation();

        // Stop and save profile
        session.post('Profiler.stop', (err, { profile }) => {
            fs.writeFileSync('/storage/sd/profile.cpuprofile',
                JSON.stringify(profile));
            session.disconnect();
        });
    });
});
```

**Memory Profiling:**

```javascript
// Heap snapshot
session.post('HeapProfiler.enable', () => {
    session.post('HeapProfiler.takeHeapSnapshot', null,
        (err, snapshot) => {
            fs.writeFileSync('/storage/sd/heap.heapsnapshot',
                JSON.stringify(snapshot));
    });
});
```

Import `.cpuprofile` and `.heapsnapshot` files into Chrome DevTools for analysis.

## Error Handling

### JavaScript Error Patterns

**Structured Error Handling:**

```javascript
// Custom error classes
class NetworkError extends Error {
    constructor(message, statusCode) {
        super(message);
        this.name = 'NetworkError';
        this.statusCode = statusCode;
    }
}

class ValidationError extends Error {
    constructor(message, field) {
        super(message);
        this.name = 'ValidationError';
        this.field = field;
    }
}

// Usage
function validateData(data) {
    if (!data.id) {
        throw new ValidationError('ID is required', 'id');
    }
    if (typeof data.value !== 'number') {
        throw new ValidationError('Value must be number', 'value');
    }
}

try {
    validateData(inputData);
} catch (error) {
    if (error instanceof ValidationError) {
        console.error(`Validation failed on ${error.field}:`, error.message);
    } else {
        console.error('Unexpected error:', error);
    }
}
```

### Exception Handling

**Global Error Handlers:**

```javascript
// Catch synchronous errors
window.addEventListener('error', (event) => {
    console.error('Global error:', {
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        error: event.error
    });

    // Log to file
    logErrorToFile(event.error);

    // Prevent default browser error handling
    event.preventDefault();
});

// Catch unhandled promise rejections
window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled rejection:', event.reason);
    logErrorToFile(event.reason);
    event.preventDefault();
});

// Node.js error handlers
if (typeof process !== 'undefined') {
    process.on('uncaughtException', (error) => {
        console.error('Uncaught exception:', error);
        logErrorToFile(error);
    });

    process.on('unhandledRejection', (reason, promise) => {
        console.error('Unhandled rejection at:', promise, 'reason:', reason);
        logErrorToFile(reason);
    });
}
```

**Error Logging Utility:**

```javascript
const fs = require('fs');

function logErrorToFile(error) {
    const timestamp = new Date().toISOString();
    const errorLog = {
        timestamp: timestamp,
        message: error.message,
        stack: error.stack,
        name: error.name
    };

    const logPath = '/storage/sd/errors.log';
    const logEntry = JSON.stringify(errorLog) + '\n';

    try {
        fs.appendFileSync(logPath, logEntry);
    } catch (writeError) {
        console.error('Failed to write error log:', writeError);
    }
}
```

### Stack Traces

**Stack Trace Analysis:**

```javascript
// Capture stack trace
function captureStack() {
    const stack = new Error().stack;
    console.log('Call stack:', stack);
    return stack;
}

// Parse stack trace
function parseStackTrace(error) {
    const stackLines = error.stack.split('\n');
    const parsed = stackLines.slice(1).map(line => {
        const match = line.match(/at\s+(.+?)\s+\((.+?):(\d+):(\d+)\)/);
        if (match) {
            return {
                function: match[1],
                file: match[2],
                line: parseInt(match[3]),
                column: parseInt(match[4])
            };
        }
        return { raw: line.trim() };
    });
    return parsed;
}

// Enhanced error reporting
function reportError(error) {
    const trace = parseStackTrace(error);
    console.error('Error details:', {
        message: error.message,
        type: error.name,
        stack: trace
    });
}

try {
    riskyOperation();
} catch (error) {
    reportError(error);
}
```

## Performance Debugging

### Rendering Bottlenecks

**Identify Paint Issues:**

```javascript
// Monitor frame rate
let lastTime = performance.now();
let frames = 0;

function measureFPS() {
    frames++;
    const currentTime = performance.now();

    if (currentTime >= lastTime + 1000) {
        const fps = Math.round((frames * 1000) / (currentTime - lastTime));
        console.log('FPS:', fps);
        frames = 0;
        lastTime = currentTime;
    }

    requestAnimationFrame(measureFPS);
}

requestAnimationFrame(measureFPS);

// Track long tasks
if (window.PerformanceObserver) {
    const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
            console.warn('Long task detected:', {
                duration: entry.duration,
                startTime: entry.startTime
            });
        }
    });

    observer.observe({ entryTypes: ['longtask'] });
}
```

**Layout Thrashing Detection:**

```javascript
// Bad: Forces multiple reflows
function badLayoutCode() {
    const element = document.getElementById('box');
    for (let i = 0; i < 100; i++) {
        element.style.width = (element.offsetWidth + 1) + 'px'; // Read-write cycle
    }
}

// Good: Batch reads and writes
function goodLayoutCode() {
    const element = document.getElementById('box');
    const width = element.offsetWidth; // Single read
    for (let i = 0; i < 100; i++) {
        element.style.width = (width + i) + 'px'; // Multiple writes
    }
}

// Detect layout thrashing
let layoutCount = 0;
const originalOffsetWidth = Object.getOwnPropertyDescriptor(
    HTMLElement.prototype, 'offsetWidth'
);

Object.defineProperty(HTMLElement.prototype, 'offsetWidth', {
    get: function() {
        layoutCount++;
        if (layoutCount > 10) {
            console.warn('Potential layout thrashing detected');
            console.trace();
        }
        return originalOffsetWidth.get.call(this);
    }
});
```

### JavaScript Profiling

**Performance API:**

```javascript
// Mark timing points
performance.mark('operation-start');
processLargeDataset();
performance.mark('operation-end');

// Measure duration
performance.measure('operation', 'operation-start', 'operation-end');

// Get measurements
const measures = performance.getEntriesByType('measure');
measures.forEach(measure => {
    console.log(`${measure.name}: ${measure.duration}ms`);
});

// User Timing API
function profileFunction(fn, name) {
    return function(...args) {
        performance.mark(`${name}-start`);
        const result = fn.apply(this, args);
        performance.mark(`${name}-end`);
        performance.measure(name, `${name}-start`, `${name}-end`);

        const measure = performance.getEntriesByName(name)[0];
        console.log(`${name} took ${measure.duration}ms`);

        return result;
    };
}

// Usage
const processData = profileFunction(function(data) {
    return data.map(item => item * 2);
}, 'processData');
```

### Memory Analysis

**Detect Memory Leaks:**

```javascript
// Track object allocation
const objectRegistry = new WeakMap();
let allocationCount = 0;

function trackAllocation(obj, identifier) {
    allocationCount++;
    objectRegistry.set(obj, {
        id: identifier,
        timestamp: Date.now(),
        allocNumber: allocationCount
    });
}

// Monitor memory usage (Node.js)
if (typeof process !== 'undefined') {
    function logMemoryUsage() {
        const usage = process.memoryUsage();
        console.log('Memory usage:', {
            heapUsed: `${Math.round(usage.heapUsed / 1024 / 1024)}MB`,
            heapTotal: `${Math.round(usage.heapTotal / 1024 / 1024)}MB`,
            rss: `${Math.round(usage.rss / 1024 / 1024)}MB`,
            external: `${Math.round(usage.external / 1024 / 1024)}MB`
        });
    }

    setInterval(logMemoryUsage, 10000); // Log every 10 seconds
}

// Heap snapshot comparison (Node.js)
const v8 = require('v8');
const fs = require('fs');

function takeHeapSnapshot(filename) {
    const snapshot = v8.writeHeapSnapshot(filename);
    console.log('Heap snapshot written to:', snapshot);
}

// Take snapshots before and after operations
takeHeapSnapshot('/storage/sd/heap-before.heapsnapshot');
performOperation();
takeHeapSnapshot('/storage/sd/heap-after.heapsnapshot');
```

**Memory Leak Patterns to Avoid:**

```javascript
// Bad: Event listener leak
function badEventListener() {
    const element = document.getElementById('button');
    element.addEventListener('click', function handler() {
        console.log('Clicked');
    });
    // Element removed but listener remains
    element.remove();
}

// Good: Clean up listeners
function goodEventListener() {
    const element = document.getElementById('button');
    const handler = function() {
        console.log('Clicked');
    };
    element.addEventListener('click', handler);

    // Clean up
    element.removeEventListener('click', handler);
    element.remove();
}

// Bad: Timer leak
function badTimer() {
    setInterval(() => {
        console.log('Running...');
    }, 1000);
    // Timer continues forever
}

// Good: Clean up timers
function goodTimer() {
    const timerId = setInterval(() => {
        console.log('Running...');
    }, 1000);

    // Clear when done
    setTimeout(() => {
        clearInterval(timerId);
    }, 10000);
}
```

## DOM Debugging

### Element Inspection

**Query and Inspect Elements:**

```javascript
// Advanced element selection
function inspectElement(selector) {
    const element = document.querySelector(selector);

    if (!element) {
        console.error('Element not found:', selector);
        return;
    }

    console.group('Element Inspection:', selector);
    console.log('Tag:', element.tagName);
    console.log('ID:', element.id);
    console.log('Classes:', [...element.classList]);
    console.log('Attributes:', Array.from(element.attributes).map(attr =>
        ({ name: attr.name, value: attr.value })
    ));
    console.log('Computed Style:', window.getComputedStyle(element));
    console.log('Bounding Box:', element.getBoundingClientRect());
    console.log('Scroll Position:', {
        top: element.scrollTop,
        left: element.scrollLeft
    });
    console.groupEnd();
}

// Monitor DOM mutations
const observer = new MutationObserver((mutations) => {
    mutations.forEach(mutation => {
        console.log('DOM mutation:', {
            type: mutation.type,
            target: mutation.target,
            addedNodes: mutation.addedNodes.length,
            removedNodes: mutation.removedNodes.length,
            attributeName: mutation.attributeName
        });
    });
});

observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeOldValue: true
});
```

### Event Troubleshooting

**Debug Event Flow:**

```javascript
// Log all events on element
function debugEvents(element) {
    const events = [
        'click', 'dblclick', 'mousedown', 'mouseup', 'mousemove',
        'touchstart', 'touchend', 'touchmove',
        'keydown', 'keyup', 'keypress',
        'focus', 'blur', 'change', 'input'
    ];

    events.forEach(eventType => {
        element.addEventListener(eventType, (e) => {
            console.log(`Event: ${eventType}`, {
                target: e.target,
                currentTarget: e.currentTarget,
                phase: e.eventPhase,
                bubbles: e.bubbles,
                cancelable: e.cancelable,
                defaultPrevented: e.defaultPrevented
            });
        }, true); // Capture phase
    });
}

// Track event propagation
function trackEventPropagation(selector, eventType) {
    const element = document.querySelector(selector);

    // Capture phase
    element.addEventListener(eventType, (e) => {
        console.log(`[CAPTURE] ${eventType} on`, e.currentTarget);
    }, true);

    // Bubble phase
    element.addEventListener(eventType, (e) => {
        console.log(`[BUBBLE] ${eventType} on`, e.currentTarget);
    }, false);
}

// Find event listeners (using Chrome DevTools protocol)
function getEventListeners(element) {
    // This function works in Chrome DevTools console
    // For programmatic access, track manually:
    const listeners = new Map();

    const original = element.addEventListener.bind(element);
    element.addEventListener = function(type, listener, options) {
        if (!listeners.has(type)) {
            listeners.set(type, []);
        }
        listeners.get(type).push({ listener, options });
        original(type, listener, options);
    };

    return listeners;
}
```

### Layout Issues

**Debug Layout Problems:**

```javascript
// Visualize element boundaries
function visualizeBoundaries(selector) {
    const elements = document.querySelectorAll(selector);

    elements.forEach((element, index) => {
        const rect = element.getBoundingClientRect();
        const overlay = document.createElement('div');

        overlay.style.cssText = `
            position: fixed;
            top: ${rect.top}px;
            left: ${rect.left}px;
            width: ${rect.width}px;
            height: ${rect.height}px;
            border: 2px solid red;
            pointer-events: none;
            z-index: 10000;
        `;

        const label = document.createElement('div');
        label.textContent = `${selector}[${index}]`;
        label.style.cssText = `
            background: red;
            color: white;
            padding: 2px 4px;
            font-size: 10px;
        `;

        overlay.appendChild(label);
        document.body.appendChild(overlay);

        setTimeout(() => overlay.remove(), 5000);
    });
}

// Check for overflow issues
function checkOverflow(element) {
    const computed = window.getComputedStyle(element);
    const hasOverflow =
        element.scrollHeight > element.clientHeight ||
        element.scrollWidth > element.clientWidth;

    console.log('Overflow check:', {
        hasOverflow: hasOverflow,
        scrollHeight: element.scrollHeight,
        clientHeight: element.clientHeight,
        scrollWidth: element.scrollWidth,
        clientWidth: element.clientWidth,
        overflow: computed.overflow,
        overflowX: computed.overflowX,
        overflowY: computed.overflowY
    });
}

// Detect layout shifting
let cumulativeLayoutShift = 0;

if (window.PerformanceObserver) {
    const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
            if (!entry.hadRecentInput) {
                cumulativeLayoutShift += entry.value;
                console.warn('Layout shift:', {
                    value: entry.value,
                    cumulative: cumulativeLayoutShift,
                    sources: entry.sources
                });
            }
        }
    });

    observer.observe({ entryTypes: ['layout-shift'] });
}
```

## Network Debugging

### AJAX Requests

**Debug XMLHttpRequest:**

```javascript
// Wrap XMLHttpRequest for debugging
const OriginalXHR = window.XMLHttpRequest;

window.XMLHttpRequest = function() {
    const xhr = new OriginalXHR();
    const id = Math.random().toString(36).substr(2, 9);

    const originalOpen = xhr.open;
    xhr.open = function(method, url, ...args) {
        console.log(`[XHR ${id}] Opening:`, method, url);
        this._debugInfo = { id, method, url, startTime: Date.now() };
        return originalOpen.apply(this, [method, url, ...args]);
    };

    xhr.addEventListener('loadstart', function() {
        console.log(`[XHR ${id}] Load started`);
    });

    xhr.addEventListener('load', function() {
        const duration = Date.now() - this._debugInfo.startTime;
        console.log(`[XHR ${id}] Completed:`, {
            status: this.status,
            statusText: this.statusText,
            duration: `${duration}ms`,
            responseSize: this.responseText.length
        });
    });

    xhr.addEventListener('error', function() {
        console.error(`[XHR ${id}] Failed:`, {
            status: this.status,
            statusText: this.statusText
        });
    });

    return xhr;
};

// Wrap Fetch API for debugging
const originalFetch = window.fetch;

window.fetch = async function(...args) {
    const [url, options = {}] = args;
    const id = Math.random().toString(36).substr(2, 9);
    const startTime = Date.now();

    console.log(`[Fetch ${id}] Requesting:`, {
        url: url,
        method: options.method || 'GET',
        headers: options.headers
    });

    try {
        const response = await originalFetch(...args);
        const duration = Date.now() - startTime;

        console.log(`[Fetch ${id}] Response:`, {
            status: response.status,
            statusText: response.statusText,
            duration: `${duration}ms`,
            headers: Object.fromEntries(response.headers.entries())
        });

        return response;
    } catch (error) {
        console.error(`[Fetch ${id}] Failed:`, error);
        throw error;
    }
};
```

### CORS Issues

**Debug CORS Problems:**

```javascript
// Test CORS configuration
async function testCORS(url) {
    console.log('Testing CORS for:', url);

    try {
        const response = await fetch(url, {
            method: 'OPTIONS',
            headers: {
                'Origin': window.location.origin,
                'Access-Control-Request-Method': 'GET'
            }
        });

        const corsHeaders = {
            'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
            'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
            'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers'),
            'Access-Control-Max-Age': response.headers.get('Access-Control-Max-Age')
        };

        console.log('CORS headers:', corsHeaders);

        if (corsHeaders['Access-Control-Allow-Origin'] === '*' ||
            corsHeaders['Access-Control-Allow-Origin'] === window.location.origin) {
            console.log('✓ CORS properly configured');
        } else {
            console.warn('✗ CORS may be blocked');
        }
    } catch (error) {
        console.error('CORS test failed:', error);
    }
}

// Disable CORS for development (BrightScript)
/*
config = {
    security_params: { websecurity: false }
    // Or use registry:
    // registry write html disable-web-security 1
}
*/
```

### API Communication

**Debug API Integration:**

```javascript
// API debugging wrapper
class DebugAPI {
    constructor(baseURL) {
        this.baseURL = baseURL;
        this.requestLog = [];
    }

    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const requestId = this.requestLog.length + 1;
        const startTime = Date.now();

        const logEntry = {
            id: requestId,
            url: url,
            method: options.method || 'GET',
            timestamp: new Date().toISOString(),
            headers: options.headers || {}
        };

        console.group(`API Request #${requestId}`);
        console.log('URL:', url);
        console.log('Method:', logEntry.method);
        console.log('Headers:', logEntry.headers);

        if (options.body) {
            console.log('Body:', options.body);
            logEntry.requestBody = options.body;
        }

        try {
            const response = await fetch(url, options);
            const duration = Date.now() - startTime;

            logEntry.status = response.status;
            logEntry.duration = duration;

            console.log('Status:', response.status);
            console.log('Duration:', `${duration}ms`);
            console.log('Response Headers:',
                Object.fromEntries(response.headers.entries()));

            const clonedResponse = response.clone();
            const responseText = await clonedResponse.text();

            try {
                logEntry.responseBody = JSON.parse(responseText);
                console.log('Response:', logEntry.responseBody);
            } catch {
                logEntry.responseBody = responseText;
                console.log('Response (text):', responseText);
            }

            console.groupEnd();
            this.requestLog.push(logEntry);

            return response;
        } catch (error) {
            logEntry.error = error.message;
            console.error('Error:', error);
            console.groupEnd();
            this.requestLog.push(logEntry);
            throw error;
        }
    }

    getLog() {
        return this.requestLog;
    }

    exportLog() {
        const json = JSON.stringify(this.requestLog, null, 2);
        console.log('Request log:', json);
        return json;
    }
}

// Usage
const api = new DebugAPI('https://api.example.com');

async function fetchData() {
    try {
        const response = await api.request('/data', {
            method: 'GET',
            headers: { 'Authorization': 'Bearer token123' }
        });
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('API call failed:', error);
    }
}
```

## Media Debugging

### HTML5 Video/Audio Issues

**Debug Media Playback:**

```javascript
// Comprehensive media event logging
function debugMediaElement(mediaElement) {
    const events = [
        'loadstart', 'progress', 'suspend', 'abort', 'error',
        'emptied', 'stalled', 'loadedmetadata', 'loadeddata',
        'canplay', 'canplaythrough', 'playing', 'waiting',
        'seeking', 'seeked', 'ended', 'durationchange',
        'timeupdate', 'play', 'pause', 'ratechange',
        'volumechange'
    ];

    events.forEach(eventType => {
        mediaElement.addEventListener(eventType, (e) => {
            console.log(`[Media] ${eventType}:`, {
                currentTime: mediaElement.currentTime,
                duration: mediaElement.duration,
                paused: mediaElement.paused,
                ended: mediaElement.ended,
                readyState: mediaElement.readyState,
                networkState: mediaElement.networkState,
                buffered: mediaElement.buffered.length > 0 ?
                    `${mediaElement.buffered.start(0)}-${mediaElement.buffered.end(0)}` : 'none'
            });
        });
    });

    // Log errors with detail
    mediaElement.addEventListener('error', (e) => {
        const error = mediaElement.error;
        console.error('[Media] Error:', {
            code: error.code,
            message: error.message,
            MEDIA_ERR_ABORTED: error.code === 1,
            MEDIA_ERR_NETWORK: error.code === 2,
            MEDIA_ERR_DECODE: error.code === 3,
            MEDIA_ERR_SRC_NOT_SUPPORTED: error.code === 4
        });
    });
}

// Check media capabilities
async function checkMediaSupport(mimeType) {
    if (!window.MediaSource) {
        console.warn('MediaSource API not supported');
        return false;
    }

    const supported = MediaSource.isTypeSupported(mimeType);
    console.log(`MediaSource support for ${mimeType}:`, supported);

    // Check HTMLMediaElement support
    const video = document.createElement('video');
    const canPlay = video.canPlayType(mimeType);
    console.log(`HTMLMediaElement canPlayType ${mimeType}:`, canPlay);

    return supported || canPlay !== '';
}

// Example usage
const video = document.querySelector('video');
debugMediaElement(video);

checkMediaSupport('video/mp4; codecs="avc1.42E01E"');
checkMediaSupport('video/webm; codecs="vp8"');
```

### Codec Problems

**Identify Codec Issues:**

```javascript
// Detect supported codecs
function detectSupportedCodecs() {
    const video = document.createElement('video');
    const audio = document.createElement('audio');

    const videoCodecs = [
        { mime: 'video/mp4; codecs="avc1.42E01E"', name: 'H.264 Baseline' },
        { mime: 'video/mp4; codecs="avc1.4D401E"', name: 'H.264 Main' },
        { mime: 'video/mp4; codecs="avc1.64001E"', name: 'H.264 High' },
        { mime: 'video/mp4; codecs="hev1.1.6.L93.B0"', name: 'H.265/HEVC' },
        { mime: 'video/webm; codecs="vp8"', name: 'VP8' },
        { mime: 'video/webm; codecs="vp9"', name: 'VP9' },
        { mime: 'video/webm; codecs="av1"', name: 'AV1' }
    ];

    const audioCodecs = [
        { mime: 'audio/mpeg', name: 'MP3' },
        { mime: 'audio/mp4; codecs="mp4a.40.2"', name: 'AAC' },
        { mime: 'audio/webm; codecs="opus"', name: 'Opus' },
        { mime: 'audio/ogg; codecs="vorbis"', name: 'Vorbis' },
        { mime: 'audio/flac', name: 'FLAC' }
    ];

    console.group('Supported Video Codecs');
    videoCodecs.forEach(codec => {
        const support = video.canPlayType(codec.mime);
        console.log(`${codec.name}: ${support || 'no'}`);
    });
    console.groupEnd();

    console.group('Supported Audio Codecs');
    audioCodecs.forEach(codec => {
        const support = audio.canPlayType(codec.mime);
        console.log(`${codec.name}: ${support || 'no'}`);
    });
    console.groupEnd();
}

detectSupportedCodecs();
```

### Synchronization

**Debug A/V Sync:**

```javascript
// Monitor audio/video synchronization
function monitorAVSync(videoElement) {
    const audioContext = new AudioContext();
    const source = audioContext.createMediaElementSource(videoElement);
    const analyser = audioContext.createAnalyser();

    source.connect(analyser);
    analyser.connect(audioContext.destination);

    let lastVideoTime = 0;
    let lastAudioTime = 0;

    function checkSync() {
        const videoTime = videoElement.currentTime;
        const audioTime = audioContext.currentTime;

        const videoDelta = videoTime - lastVideoTime;
        const audioDelta = audioTime - lastAudioTime;
        const drift = Math.abs(videoDelta - audioDelta);

        if (drift > 0.1) { // More than 100ms drift
            console.warn('A/V sync drift detected:', {
                drift: `${(drift * 1000).toFixed(2)}ms`,
                videoTime: videoTime,
                audioTime: audioTime
            });
        }

        lastVideoTime = videoTime;
        lastAudioTime = audioTime;

        requestAnimationFrame(checkSync);
    }

    videoElement.addEventListener('play', () => {
        audioContext.resume();
        requestAnimationFrame(checkSync);
    });
}

// Usage
const video = document.querySelector('video');
monitorAVSync(video);
```

## Cross-Platform Issues

### Browser Compatibility

**Detect BrightSign Environment:**

```javascript
// Identify BrightSign player
function detectBrightSign() {
    const userAgent = navigator.userAgent;
    const isBrightSign = /BrightSign/.test(userAgent);

    if (isBrightSign) {
        const match = userAgent.match(/BrightSign\/(\d+\.\d+\.\d+)/);
        const version = match ? match[1] : 'unknown';

        console.log('Running on BrightSign:', {
            version: version,
            userAgent: userAgent
        });

        return { isBrightSign: true, version: version };
    }

    return { isBrightSign: false };
}

const platform = detectBrightSign();

// Feature detection
function checkFeatures() {
    const features = {
        'Promise': typeof Promise !== 'undefined',
        'Fetch': typeof fetch !== 'undefined',
        'Arrow Functions': (() => true)(),
        'Async/Await': (async () => true)().constructor.name === 'AsyncFunction',
        'WeakMap': typeof WeakMap !== 'undefined',
        'Proxy': typeof Proxy !== 'undefined',
        'SharedArrayBuffer': typeof SharedArrayBuffer !== 'undefined',
        'WebAssembly': typeof WebAssembly !== 'undefined',
        'Intl': typeof Intl !== 'undefined',
        'ResizeObserver': typeof ResizeObserver !== 'undefined',
        'IntersectionObserver': typeof IntersectionObserver !== 'undefined'
    };

    console.table(features);
    return features;
}

checkFeatures();
```

### BrightSign-Specific Behaviors

**Debug BrightSign APIs:**

```javascript
// Check for BrightSign JavaScript objects
function checkBrightSignAPIs() {
    const apis = [
        'BSDeviceInfo',
        'BSSystemTime',
        'BSControlPort',
        'BSSerialPort',
        'BSDatagramSocket',
        'BSMessagePort'
    ];

    console.group('BrightSign API Availability');
    apis.forEach(api => {
        const available = typeof window[api] !== 'undefined';
        console.log(`${api}: ${available ? '✓' : '✗'}`);

        if (available) {
            try {
                const instance = new window[api]();
                console.log(`  Can instantiate: ✓`);
            } catch (error) {
                console.log(`  Can instantiate: ✗`, error.message);
            }
        }
    });
    console.groupEnd();
}

// Check for @brightsign modules (Node.js)
async function checkBrightSignModules() {
    const modules = [
        '@brightsign/deviceinfo',
        '@brightsign/system',
        '@brightsign/registry',
        '@brightsign/networkstatus',
        '@brightsign/storage'
    ];

    console.group('BrightSign Node Modules');
    for (const moduleName of modules) {
        try {
            const module = require(moduleName);
            console.log(`${moduleName}: ✓`, Object.keys(module));
        } catch (error) {
            console.log(`${moduleName}: ✗`, error.message);
        }
    }
    console.groupEnd();
}

checkBrightSignAPIs();
if (typeof require !== 'undefined') {
    checkBrightSignModules();
}
```

## Integration Debugging

### JavaScript-BrightScript Communication

**Debug Message Passing:**

```javascript
// JavaScript side
class BrightScriptBridge {
    constructor() {
        this.messagePort = null;
        this.handlers = new Map();
        this.messageId = 0;

        this.initMessagePort();
    }

    initMessagePort() {
        if (typeof BSMessagePort === 'undefined') {
            console.error('BSMessagePort not available');
            return;
        }

        try {
            this.messagePort = new BSMessagePort();
            this.messagePort.onmessage = (e) => this.handleMessage(e);
            console.log('Message port initialized');
        } catch (error) {
            console.error('Failed to initialize message port:', error);
        }
    }

    handleMessage(event) {
        console.log('Received from BrightScript:', event.data);

        try {
            const message = JSON.parse(event.data);
            const handler = this.handlers.get(message.type);

            if (handler) {
                handler(message.payload);
            } else {
                console.warn('No handler for message type:', message.type);
            }
        } catch (error) {
            console.error('Error handling message:', error);
        }
    }

    on(type, handler) {
        this.handlers.set(type, handler);
    }

    send(type, payload) {
        const message = {
            id: ++this.messageId,
            type: type,
            payload: payload,
            timestamp: Date.now()
        };

        console.log('Sending to BrightScript:', message);

        try {
            this.messagePort.postMessage(JSON.stringify(message));
        } catch (error) {
            console.error('Failed to send message:', error);
        }
    }
}

// Usage
const bridge = new BrightScriptBridge();

bridge.on('response', (data) => {
    console.log('Got response:', data);
});

bridge.send('request', { action: 'getData', params: { id: 123 } });
```

**BrightScript Side:**

```brightscript
' BrightScript message handler
function SetupMessagePort(htmlWidget as Object) as Object
    port = CreateObject("roMessagePort")
    htmlWidget.SetPort(port)

    ' Send message to JavaScript
    msgToJS = {
        type: "response"
        payload: { status: "ok", data: [1, 2, 3] }
    }
    htmlWidget.PostJSMessage(FormatJson(msgToJS))

    return port
end function

' Main event loop
sub Main()
    htmlWidget = CreateWidget()
    port = SetupMessagePort(htmlWidget)

    while true
        msg = wait(0, port)

        if type(msg) = "roHtmlWidgetEvent" then
            eventData = msg.GetData()
            print "Received from JavaScript: "; eventData

            ' Parse and handle
            parsed = ParseJson(eventData)
            if parsed <> invalid then
                print "Message type: "; parsed.type
                print "Payload: "; FormatJson(parsed.payload)
            end if
        end if
    end while
end sub
```

## Security Debugging

### CSP Violations

**Monitor Content Security Policy:**

```javascript
// Listen for CSP violations
document.addEventListener('securitypolicyviolation', (e) => {
    console.error('CSP Violation:', {
        blockedURI: e.blockedURI,
        violatedDirective: e.violatedDirective,
        originalPolicy: e.originalPolicy,
        sourceFile: e.sourceFile,
        lineNumber: e.lineNumber,
        columnNumber: e.columnNumber,
        sample: e.sample
    });

    // Log to file for analysis
    logSecurityViolation(e);
});

function logSecurityViolation(event) {
    const violation = {
        timestamp: new Date().toISOString(),
        type: 'csp-violation',
        details: {
            blocked: event.blockedURI,
            directive: event.violatedDirective,
            source: event.sourceFile,
            line: event.lineNumber
        }
    };

    // Send to logging endpoint or save locally
    fetch('/api/log-security', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(violation)
    }).catch(err => console.error('Failed to log violation:', err));
}

// Test CSP configuration
function testCSP() {
    // Try to inline script (blocked if CSP active)
    try {
        eval('console.log("Eval allowed")');
        console.warn('CSP not blocking eval');
    } catch (e) {
        console.log('CSP blocking eval: ✓');
    }

    // Try to load external script
    const script = document.createElement('script');
    script.src = 'https://external.com/script.js';
    script.onerror = () => console.log('CSP blocked external script: ✓');
    script.onload = () => console.warn('CSP allowed external script');
    document.head.appendChild(script);
}
```

### Sandboxing Issues

**Debug Iframe Sandbox:**

```javascript
// Check iframe sandbox restrictions
function checkIframeSandbox(iframe) {
    const sandbox = iframe.getAttribute('sandbox');

    console.group('Iframe Sandbox Analysis');
    console.log('Sandbox attribute:', sandbox || 'none');

    if (sandbox) {
        const permissions = sandbox.split(' ');
        const checks = {
            'allow-scripts': permissions.includes('allow-scripts'),
            'allow-same-origin': permissions.includes('allow-same-origin'),
            'allow-forms': permissions.includes('allow-forms'),
            'allow-popups': permissions.includes('allow-popups'),
            'allow-top-navigation': permissions.includes('allow-top-navigation')
        };

        console.table(checks);
    } else {
        console.log('No sandbox restrictions');
    }
    console.groupEnd();
}

// Test cross-origin restrictions
function testCrossOrigin() {
    try {
        const iframe = document.createElement('iframe');
        iframe.src = 'https://example.com';
        document.body.appendChild(iframe);

        iframe.onload = () => {
            try {
                const doc = iframe.contentDocument;
                console.log('Cross-origin access: ✓ (same-origin or CORS)');
            } catch (e) {
                console.log('Cross-origin access: ✗ (blocked)', e.message);
            }
        };
    } catch (error) {
        console.error('Failed to create iframe:', error);
    }
}
```

### Permission Errors

**Debug Permission Issues:**

```javascript
// Check API permissions
async function checkPermissions() {
    const permissions = [
        'geolocation',
        'notifications',
        'camera',
        'microphone'
    ];

    console.group('Permission Status');

    for (const name of permissions) {
        try {
            if (navigator.permissions) {
                const result = await navigator.permissions.query({ name: name });
                console.log(`${name}:`, result.state);

                result.addEventListener('change', () => {
                    console.log(`${name} permission changed to:`, result.state);
                });
            } else {
                console.log(`${name}: Permissions API not available`);
            }
        } catch (error) {
            console.log(`${name}: ${error.message}`);
        }
    }

    console.groupEnd();
}

// Test camera access (if enabled in security_params)
async function testCameraAccess() {
    try {
        const stream = await navigator.mediaDevices.getUserMedia({
            video: true
        });

        console.log('Camera access: ✓', {
            videoTracks: stream.getVideoTracks().length,
            settings: stream.getVideoTracks()[0].getSettings()
        });

        stream.getTracks().forEach(track => track.stop());
    } catch (error) {
        console.error('Camera access: ✗', error.name, error.message);
    }
}

checkPermissions();
```

## Trace Events

### Chromium TraceEvent System

**Enable TraceEvents (BrightScript):**

```brightscript
' Enable trace events via registry
sub EnableTraceEvents()
    reg = CreateObject("roRegistrySection", "html")

    ' Set trace categories
    categories = "toplevel,blink_gc,disabled-by-default-memory-infra,"
    categories = categories + "disabled-by-default-blink_gc,"
    categories = categories + "disabled-by-default.skia.gpu.cache"

    reg.Write("tracecategories", categories)
    reg.Write("tracemaxsnapshots", "25")
    reg.Write("tracemonitorinterval", "60")
    reg.Flush()

    print "Trace events enabled"
end sub
```

**Using TraceEvents:**

1. Create directory: `/storage/sd/brightsign-webinspector/`
2. Enable via registry (see above)
3. Reboot player to activate
4. Trace files written to directory every 60 seconds
5. Transfer `.json` files to development machine
6. Import into `chrome://tracing`

**Common Trace Categories:**

- `toplevel` - Top-level events
- `blink_gc` - Garbage collection
- `disabled-by-default-memory-infra` - Memory instrumentation
- `disabled-by-default-blink_gc` - Detailed GC events
- `v8` - V8 JavaScript engine events
- `renderer` - Rendering events

## Diagnostic Web Server

### Local DWS Access

**Access Player Diagnostics:**

```javascript
// Fetch player logs via DWS
async function fetchPlayerLogs(playerIP, username, password) {
    const auth = btoa(`${username}:${password}`);
    const baseURL = `http://${playerIP}`;

    try {
        // Get system log
        const logResponse = await fetch(`${baseURL}/api/v1/logs/system`, {
            headers: {
                'Authorization': `Basic ${auth}`
            }
        });

        const logs = await logResponse.text();
        console.log('System logs:', logs);

        // Get player status
        const statusResponse = await fetch(`${baseURL}/api/v1/status`, {
            headers: {
                'Authorization': `Basic ${auth}`
            }
        });

        const status = await statusResponse.json();
        console.log('Player status:', status);

        return { logs, status };
    } catch (error) {
        console.error('Failed to fetch diagnostics:', error);
    }
}

// Usage
fetchPlayerLogs('192.168.1.100', 'admin', 'password');
```

## Best Practices

### Development Workflow

**Debug Configuration Management:**

```javascript
// Environment-aware debugging
const DEBUG_CONFIG = {
    isDevelopment: window.location.hostname === 'localhost' ||
                    /^192\.168\./.test(window.location.hostname),

    enableLogging: true,
    enableRemoteInspector: true,
    enableTraceEvents: false,
    logLevel: 'debug' // 'error', 'warn', 'info', 'debug'
};

// Conditional logging
function log(level, ...args) {
    const levels = ['error', 'warn', 'info', 'debug'];
    const currentLevelIndex = levels.indexOf(DEBUG_CONFIG.logLevel);
    const messageLevelIndex = levels.indexOf(level);

    if (messageLevelIndex <= currentLevelIndex) {
        console[level](...args);
    }
}

// Usage
log('debug', 'Detailed debug info');
log('info', 'Important information');
log('error', 'Critical error');

// Disable debugging for production
if (!DEBUG_CONFIG.isDevelopment) {
    console.log = () => {};
    console.debug = () => {};
    console.info = () => {};
}
```

### Error Recovery Strategies

**Automatic Error Recovery:**

```javascript
// Watchdog timer for hung applications
class Watchdog {
    constructor(timeout = 30000) {
        this.timeout = timeout;
        this.timerId = null;
        this.lastPing = Date.now();
    }

    start() {
        this.timerId = setInterval(() => {
            const elapsed = Date.now() - this.lastPing;

            if (elapsed > this.timeout) {
                console.error('Application hung, attempting recovery');
                this.recover();
            }
        }, 5000);
    }

    ping() {
        this.lastPing = Date.now();
    }

    recover() {
        // Log error state
        console.error('Watchdog timeout - reloading application');

        // Attempt graceful cleanup
        try {
            this.cleanup();
        } catch (error) {
            console.error('Cleanup failed:', error);
        }

        // Reload page
        window.location.reload();
    }

    cleanup() {
        // Close connections, clear timers, etc.
        clearInterval(this.timerId);
    }
}

// Usage
const watchdog = new Watchdog(30000);
watchdog.start();

// Ping watchdog in main loop
setInterval(() => {
    watchdog.ping();
}, 1000);
```

## Troubleshooting Guide

### Common Issues and Solutions

**Memory Crashes:**
- Symptom: Player reboots unexpectedly
- Debug: Enable heap snapshots, monitor memory usage
- Solution: Identify and fix memory leaks, reduce allocation

**Slow Performance:**
- Symptom: Laggy UI, dropped frames
- Debug: Use Performance API, check long tasks
- Solution: Optimize rendering, reduce JavaScript execution

**Network Failures:**
- Symptom: Failed requests, timeouts
- Debug: Monitor network tab, log requests
- Solution: Check CORS, verify connectivity, add retry logic

**Media Playback Issues:**
- Symptom: Video won't play, audio sync problems
- Debug: Log media events, check codec support
- Solution: Use supported codecs, verify file integrity

**Integration Failures:**
- Symptom: BrightScript communication broken
- Debug: Log message passing, verify message port
- Solution: Check message format, ensure port configured

## Summary

Effective JavaScript debugging on BrightSign requires:

1. **Remote DevTools**: Essential for browser debugging
2. **Node.js Inspector**: Critical for server-side JavaScript
3. **Comprehensive Logging**: Track execution flow and errors
4. **Performance Monitoring**: Identify bottlenecks early
5. **Error Handling**: Graceful failure recovery
6. **Security Awareness**: Monitor CSP and permissions
7. **Platform Knowledge**: Understand BrightSign-specific behaviors

Always disable debugging features in production deployments to prevent memory leaks and security vulnerabilities.

## Next Steps

Continue to [Chapter 9: Writing Extensions](../chapter09-writing-extensions/) to learn how to extend BrightSign functionality with custom modules and integrations.


---

[← Previous](02-javascript-node-programs.md) | [↑ Part 3: JavaScript Development](README.md)
