# Implementing Live Data Feeds

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers displaying real-time information on BrightSign players. Live data feeds keep your digital signage current with continuously updating information like news, social media, stock prices, transit schedules, or custom business data.

### What You'll Learn

- Choosing the right update mechanism (polling, WebSockets, SSE)
- Implementing polling-based updates
- Using WebSockets for real-time data
- Server-Sent Events (SSE) for push updates
- Building common feed types (news, tickers, dashboards)
- Smooth data transitions and animations
- Handling disconnections gracefully

### Live Data Use Cases

| Use Case | Update Frequency | Best Method |
|----------|-----------------|-------------|
| News headlines | 5-15 minutes | Polling |
| Stock prices | 1-5 seconds | WebSocket |
| Social media | 30-60 seconds | Polling |
| Transit arrivals | 30 seconds | Polling or SSE |
| Emergency alerts | Instant | WebSocket |
| Sports scores | 10-30 seconds | WebSocket or Polling |
| Weather | 15-30 minutes | Polling |

---

## Prerequisites

- Completed [Integrating with REST APIs](09-integrating-rest-apis.md) guide
- BrightSign player with network connectivity
- Understanding of asynchronous programming
- Access to a data source or API

---

## Polling vs WebSockets vs SSE

### Comparison

| Feature | Polling | WebSocket | SSE |
|---------|---------|-----------|-----|
| Connection | New per request | Persistent | Persistent |
| Direction | Client → Server | Bidirectional | Server → Client |
| Latency | Higher | Low | Low |
| Battery/Power | Higher | Lower | Lower |
| Complexity | Simple | Moderate | Simple |
| Browser Support | Universal | Universal | Good |
| Firewall Friendly | Yes | Usually | Yes |

### When to Use Each

**Polling**: Best for data that updates infrequently (minutes) or when you need simplicity.

**WebSockets**: Best for real-time bidirectional communication, high-frequency updates, or interactive applications.

**SSE**: Best for server-push scenarios where client doesn't need to send data, simpler than WebSockets.

---

## Part 1: Polling-Based Updates

The simplest approach - periodically request fresh data.

### BrightScript: Timer-Based Polling

```brightscript
Sub Main()
    ' Configuration
    apiUrl = "https://api.example.com/v1/data"
    pollInterval = 60  ' seconds

    ' Set up video mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Create HTML widget for display
    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
    htmlWidget = CreateObject("roHtmlWidget", rect, {
        url: "file:///sd:/display/index.html"
    })
    htmlWidget.Show()

    ' Create message port
    msgPort = CreateObject("roMessagePort")
    htmlWidget.SetPort(msgPort)

    ' Create polling timer
    pollTimer = CreateObject("roTimer")
    pollTimer.SetPort(msgPort)
    pollTimer.SetElapsed(pollInterval, 0)

    ' Initial data fetch
    FetchAndDisplayData(apiUrl, htmlWidget)
    pollTimer.Start()

    ' Main event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTimerEvent" then
            print "Poll timer fired - fetching data"
            FetchAndDisplayData(apiUrl, htmlWidget)
            pollTimer.Start()  ' Restart timer
        end if
    end while
End Sub

Sub FetchAndDisplayData(url as String, widget as Object)
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(url)
    urlTransfer.SetTimeout(30000)
    urlTransfer.AddHeader("Accept", "application/json")

    response = urlTransfer.GetToString()

    if response <> "" then
        data = ParseJson(response)
        if data <> invalid then
            ' Send to HTML widget
            widget.PostJSMessage({type: "data", payload: data})
            print "Data updated successfully"
        end if
    else
        print "Fetch failed: "; urlTransfer.GetResponseCode()
    end if
End Sub
```

### JavaScript: Polling with Error Recovery

```javascript
class PollingFeed {
    constructor(url, intervalMs, onData, onError) {
        this.url = url;
        this.intervalMs = intervalMs;
        this.onData = onData;
        this.onError = onError;
        this.timer = null;
        this.consecutiveErrors = 0;
        this.maxErrors = 5;
    }

    async fetch() {
        try {
            const response = await fetch(this.url, {
                headers: { 'Accept': 'application/json' },
                signal: AbortSignal.timeout(30000)
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const data = await response.json();
            this.consecutiveErrors = 0;
            this.onData(data);

        } catch (error) {
            this.consecutiveErrors++;
            console.error(`Poll error (${this.consecutiveErrors}):`, error);

            if (this.onError) {
                this.onError(error, this.consecutiveErrors);
            }

            // Increase interval after consecutive errors
            if (this.consecutiveErrors >= this.maxErrors) {
                console.warn('Too many errors, increasing poll interval');
                this.stop();
                this.intervalMs = Math.min(this.intervalMs * 2, 300000);
                this.start();
            }
        }
    }

    start() {
        if (this.timer) return;

        // Immediate first fetch
        this.fetch();

        // Then poll at interval
        this.timer = setInterval(() => this.fetch(), this.intervalMs);
        console.log(`Polling started: ${this.intervalMs}ms interval`);
    }

    stop() {
        if (this.timer) {
            clearInterval(this.timer);
            this.timer = null;
            console.log('Polling stopped');
        }
    }
}

// Usage
const newsFeed = new PollingFeed(
    'https://api.example.com/news',
    60000,  // 1 minute
    (data) => updateNewsDisplay(data),
    (error, count) => showErrorIndicator(count)
);

newsFeed.start();
```

---

## Part 2: WebSocket Connections

For real-time, low-latency updates.

### JavaScript: WebSocket Client

```javascript
class LiveDataSocket {
    constructor(url, onMessage, options = {}) {
        this.url = url;
        this.onMessage = onMessage;
        this.reconnectDelay = options.reconnectDelay || 3000;
        this.maxReconnectDelay = options.maxReconnectDelay || 30000;
        this.heartbeatInterval = options.heartbeatInterval || 30000;

        this.socket = null;
        this.heartbeatTimer = null;
        this.reconnectAttempts = 0;
        this.isConnected = false;
    }

    connect() {
        console.log('WebSocket connecting to:', this.url);

        this.socket = new WebSocket(this.url);

        this.socket.onopen = () => {
            console.log('WebSocket connected');
            this.isConnected = true;
            this.reconnectAttempts = 0;
            this.startHeartbeat();
            this.onConnectionChange(true);
        };

        this.socket.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);

                // Handle ping/pong
                if (data.type === 'pong') {
                    return;
                }

                this.onMessage(data);
            } catch (error) {
                console.error('Message parse error:', error);
            }
        };

        this.socket.onclose = (event) => {
            console.log('WebSocket closed:', event.code, event.reason);
            this.isConnected = false;
            this.stopHeartbeat();
            this.onConnectionChange(false);
            this.scheduleReconnect();
        };

        this.socket.onerror = (error) => {
            console.error('WebSocket error:', error);
        };
    }

    send(data) {
        if (this.isConnected && this.socket) {
            this.socket.send(JSON.stringify(data));
        }
    }

    startHeartbeat() {
        this.heartbeatTimer = setInterval(() => {
            if (this.isConnected) {
                this.send({ type: 'ping' });
            }
        }, this.heartbeatInterval);
    }

    stopHeartbeat() {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
    }

    scheduleReconnect() {
        this.reconnectAttempts++;

        // Exponential backoff
        const delay = Math.min(
            this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1),
            this.maxReconnectDelay
        );

        console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

        setTimeout(() => {
            this.connect();
        }, delay);
    }

    onConnectionChange(connected) {
        // Override in subclass or set callback
        const indicator = document.getElementById('connection-status');
        if (indicator) {
            indicator.className = connected ? 'connected' : 'disconnected';
            indicator.textContent = connected ? 'Live' : 'Reconnecting...';
        }
    }

    close() {
        this.stopHeartbeat();
        if (this.socket) {
            this.socket.close();
        }
    }
}

// Usage: Stock ticker
const stockSocket = new LiveDataSocket(
    'wss://stream.example.com/stocks',
    (data) => {
        if (data.type === 'quote') {
            updateStockPrice(data.symbol, data.price, data.change);
        }
    }
);

stockSocket.connect();

function updateStockPrice(symbol, price, change) {
    const element = document.getElementById(`stock-${symbol}`);
    if (element) {
        element.querySelector('.price').textContent = price.toFixed(2);
        element.querySelector('.change').textContent =
            (change >= 0 ? '+' : '') + change.toFixed(2);
        element.className = change >= 0 ? 'stock up' : 'stock down';

        // Flash animation
        element.classList.add('updated');
        setTimeout(() => element.classList.remove('updated'), 500);
    }
}
```

### BrightScript: WebSocket Client

```brightscript
Sub Main()
    msgPort = CreateObject("roMessagePort")

    ' Create WebSocket connection
    ws = CreateObject("roWebSocket")
    ws.SetPort(msgPort)

    ' Configure URL
    ws.Open("wss://stream.example.com/data")

    ' Create HTML widget for display
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)
    htmlWidget = CreateObject("roHtmlWidget", rect, {
        url: "file:///sd:/ticker/index.html"
    })
    htmlWidget.Show()
    htmlWidget.SetPort(msgPort)

    ' Heartbeat timer
    heartbeatTimer = CreateObject("roTimer")
    heartbeatTimer.SetPort(msgPort)
    heartbeatTimer.SetElapsed(30, 0)

    connected = false
    reconnectAttempts = 0

    while true
        msg = wait(5000, msgPort)

        if msg = invalid then
            ' Timeout - check connection
            if not connected then
                Reconnect(ws, reconnectAttempts)
                reconnectAttempts = reconnectAttempts + 1
            end if

        else if type(msg) = "roWebSocketEvent" then
            eventType = msg.Event()

            if eventType = "N" then  ' Connected
                print "WebSocket connected"
                connected = true
                reconnectAttempts = 0
                heartbeatTimer.Start()

                ' Subscribe to data
                ws.Send(formatJson({type: "subscribe", channels: ["quotes", "news"]}))

            else if eventType = "D" then  ' Data received
                data = ParseJson(msg.Data())
                if data <> invalid then
                    ' Forward to HTML widget
                    htmlWidget.PostJSMessage({type: "stream", payload: data})
                end if

            else if eventType = "C" then  ' Closed
                print "WebSocket closed: "; msg.Code()
                connected = false
                heartbeatTimer.Stop()

            else if eventType = "F" then  ' Failed
                print "WebSocket failed: "; msg.Message()
                connected = false
            end if

        else if type(msg) = "roTimerEvent" then
            ' Send heartbeat
            if connected then
                ws.Send(formatJson({type: "ping"}))
            end if
            heartbeatTimer.Start()
        end if
    end while
End Sub

Sub Reconnect(ws as Object, attempts as Integer)
    ' Exponential backoff (3s, 6s, 12s, 24s, max 30s)
    delay = 3000 * (2 ^ attempts)
    if delay > 30000 then delay = 30000

    print "Reconnecting in "; delay; "ms"
    sleep(delay)
    ws.Open("wss://stream.example.com/data")
End Sub
```

---

## Part 3: Server-Sent Events (SSE)

Simpler than WebSockets for one-way server-to-client streams.

### JavaScript: SSE Client

```javascript
class EventStreamFeed {
    constructor(url, handlers) {
        this.url = url;
        this.handlers = handlers;
        this.eventSource = null;
        this.reconnectDelay = 3000;
    }

    connect() {
        console.log('SSE connecting to:', this.url);

        this.eventSource = new EventSource(this.url);

        this.eventSource.onopen = () => {
            console.log('SSE connected');
            if (this.handlers.onConnect) {
                this.handlers.onConnect();
            }
        };

        this.eventSource.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                if (this.handlers.onMessage) {
                    this.handlers.onMessage(data);
                }
            } catch (error) {
                console.error('SSE parse error:', error);
            }
        };

        // Handle named events
        if (this.handlers.events) {
            for (const [eventName, handler] of Object.entries(this.handlers.events)) {
                this.eventSource.addEventListener(eventName, (event) => {
                    try {
                        const data = JSON.parse(event.data);
                        handler(data);
                    } catch (error) {
                        console.error(`SSE ${eventName} error:`, error);
                    }
                });
            }
        }

        this.eventSource.onerror = (error) => {
            console.error('SSE error:', error);
            if (this.handlers.onError) {
                this.handlers.onError(error);
            }
            // EventSource auto-reconnects
        };
    }

    close() {
        if (this.eventSource) {
            this.eventSource.close();
            this.eventSource = null;
        }
    }
}

// Usage: News feed with SSE
const newsStream = new EventStreamFeed('https://stream.example.com/news/events', {
    onConnect: () => {
        showStatus('Connected');
    },
    onMessage: (data) => {
        // Default event
        console.log('Message:', data);
    },
    events: {
        'breaking': (data) => {
            showBreakingNews(data);
        },
        'update': (data) => {
            updateHeadline(data);
        },
        'alert': (data) => {
            showAlert(data);
        }
    },
    onError: (error) => {
        showStatus('Reconnecting...');
    }
});

newsStream.connect();
```

---

## Part 4: Building Common Feed Types

### News Ticker

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            width: 1920px;
            height: 100px;
            background: #1a1a2e;
            font-family: Arial, sans-serif;
            overflow: hidden;
        }

        .ticker-container {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            background: linear-gradient(90deg, #e63946, #1d3557);
        }

        .ticker-label {
            background: #e63946;
            color: white;
            padding: 0 30px;
            height: 100%;
            display: flex;
            align-items: center;
            font-weight: bold;
            font-size: 24px;
            text-transform: uppercase;
            flex-shrink: 0;
        }

        .ticker-track {
            flex: 1;
            overflow: hidden;
            height: 100%;
            display: flex;
            align-items: center;
        }

        .ticker-content {
            display: flex;
            animation: scroll 30s linear infinite;
            white-space: nowrap;
        }

        .ticker-item {
            color: white;
            font-size: 28px;
            padding: 0 50px;
            display: flex;
            align-items: center;
        }

        .ticker-item::after {
            content: '•';
            margin-left: 50px;
            opacity: 0.5;
        }

        @keyframes scroll {
            from { transform: translateX(0); }
            to { transform: translateX(-50%); }
        }

        .ticker-content.paused {
            animation-play-state: paused;
        }
    </style>
</head>
<body>
    <div class="ticker-container">
        <div class="ticker-label">Breaking News</div>
        <div class="ticker-track">
            <div class="ticker-content" id="ticker">
                <!-- Headlines inserted here -->
            </div>
        </div>
    </div>

    <script>
        let headlines = [];

        // Listen for BrightScript messages
        window.addEventListener('bsmessage', (event) => {
            const message = event.data;

            if (message.type === 'headlines') {
                headlines = message.payload;
                updateTicker();
            } else if (message.type === 'addHeadline') {
                headlines.unshift(message.payload);
                if (headlines.length > 20) headlines.pop();
                updateTicker();
            }
        });

        function updateTicker() {
            const ticker = document.getElementById('ticker');

            // Create duplicate content for seamless loop
            const content = headlines.map(h =>
                `<div class="ticker-item">${escapeHtml(h.title)}</div>`
            ).join('');

            ticker.innerHTML = content + content;

            // Adjust animation duration based on content length
            const width = ticker.scrollWidth / 2;
            const duration = width / 100;  // 100px per second
            ticker.style.animationDuration = `${duration}s`;
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        // Pause on hover (for touch screens)
        document.querySelector('.ticker-content').addEventListener('mouseenter', function() {
            this.classList.add('paused');
        });

        document.querySelector('.ticker-content').addEventListener('mouseleave', function() {
            this.classList.remove('paused');
        });
    </script>
</body>
</html>
```

### Stock Ticker Dashboard

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            width: 1920px;
            height: 1080px;
            background: #0a0a0a;
            font-family: 'Roboto Mono', monospace;
            color: white;
        }

        .dashboard {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            padding: 40px;
            height: 100%;
        }

        .stock-card {
            background: #1a1a1a;
            border-radius: 12px;
            padding: 30px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            transition: transform 0.3s;
        }

        .stock-card.up { border-left: 4px solid #00c853; }
        .stock-card.down { border-left: 4px solid #ff1744; }

        .stock-card.updated {
            animation: flash 0.5s ease;
        }

        @keyframes flash {
            0%, 100% { background: #1a1a1a; }
            50% { background: #2a2a2a; }
        }

        .symbol {
            font-size: 36px;
            font-weight: bold;
            margin-bottom: 10px;
        }

        .company {
            font-size: 18px;
            opacity: 0.6;
            margin-bottom: 20px;
        }

        .price {
            font-size: 48px;
            font-weight: 300;
        }

        .change {
            font-size: 24px;
            margin-top: 10px;
        }

        .up .change { color: #00c853; }
        .down .change { color: #ff1744; }

        .last-update {
            position: fixed;
            bottom: 20px;
            right: 40px;
            opacity: 0.5;
            font-size: 16px;
        }

        .connection-status {
            position: fixed;
            top: 20px;
            right: 40px;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
        }

        .connection-status.connected {
            background: #00c853;
            color: black;
        }

        .connection-status.disconnected {
            background: #ff1744;
            color: white;
        }
    </style>
</head>
<body>
    <div class="connection-status connected" id="connection-status">Live</div>

    <div class="dashboard" id="dashboard">
        <!-- Stock cards generated dynamically -->
    </div>

    <div class="last-update">Last update: <span id="last-update">--:--:--</span></div>

    <script>
        const stocks = new Map();

        // Initialize with default stocks
        const defaultStocks = [
            { symbol: 'AAPL', company: 'Apple Inc.', price: 0, change: 0 },
            { symbol: 'GOOGL', company: 'Alphabet Inc.', price: 0, change: 0 },
            { symbol: 'MSFT', company: 'Microsoft Corp.', price: 0, change: 0 },
            { symbol: 'AMZN', company: 'Amazon.com Inc.', price: 0, change: 0 },
            { symbol: 'TSLA', company: 'Tesla Inc.', price: 0, change: 0 },
            { symbol: 'META', company: 'Meta Platforms', price: 0, change: 0 },
            { symbol: 'NVDA', company: 'NVIDIA Corp.', price: 0, change: 0 },
            { symbol: 'JPM', company: 'JPMorgan Chase', price: 0, change: 0 }
        ];

        defaultStocks.forEach(stock => {
            stocks.set(stock.symbol, stock);
        });

        renderDashboard();

        // Listen for data from BrightScript
        window.addEventListener('bsmessage', (event) => {
            const message = event.data;

            if (message.type === 'stream' && message.payload.type === 'quote') {
                updateStock(message.payload);
            } else if (message.type === 'batch') {
                message.payload.forEach(quote => updateStock(quote));
            }
        });

        function updateStock(quote) {
            const stock = stocks.get(quote.symbol);
            if (!stock) return;

            stock.price = quote.price;
            stock.change = quote.change;
            stock.changePercent = quote.changePercent;

            updateStockCard(stock);
            updateLastUpdate();
        }

        function renderDashboard() {
            const dashboard = document.getElementById('dashboard');
            dashboard.innerHTML = '';

            stocks.forEach((stock, symbol) => {
                const card = document.createElement('div');
                card.className = 'stock-card';
                card.id = `stock-${symbol}`;
                card.innerHTML = `
                    <div class="symbol">${symbol}</div>
                    <div class="company">${escapeHtml(stock.company)}</div>
                    <div class="price">$<span class="price-value">--</span></div>
                    <div class="change">--</div>
                `;
                dashboard.appendChild(card);
            });
        }

        function updateStockCard(stock) {
            const card = document.getElementById(`stock-${stock.symbol}`);
            if (!card) return;

            const priceEl = card.querySelector('.price-value');
            const changeEl = card.querySelector('.change');

            priceEl.textContent = stock.price.toFixed(2);

            const changeSign = stock.change >= 0 ? '+' : '';
            changeEl.textContent = `${changeSign}${stock.change.toFixed(2)} (${changeSign}${stock.changePercent.toFixed(2)}%)`;

            card.className = `stock-card ${stock.change >= 0 ? 'up' : 'down'}`;

            // Flash animation
            card.classList.add('updated');
            setTimeout(() => card.classList.remove('updated'), 500);
        }

        function updateLastUpdate() {
            const now = new Date();
            document.getElementById('last-update').textContent =
                now.toLocaleTimeString();
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
</body>
</html>
```

### Transit Arrivals Display

```javascript
// transit-display.js

class TransitDisplay {
    constructor(stopId, containerId) {
        this.stopId = stopId;
        this.container = document.getElementById(containerId);
        this.arrivals = [];
        this.pollInterval = 30000;  // 30 seconds
    }

    async start() {
        await this.fetchArrivals();
        setInterval(() => this.fetchArrivals(), this.pollInterval);

        // Update countdown every second
        setInterval(() => this.updateCountdowns(), 1000);
    }

    async fetchArrivals() {
        try {
            const response = await fetch(
                `https://api.transit.example.com/arrivals?stop=${this.stopId}`
            );

            if (!response.ok) throw new Error('API error');

            this.arrivals = await response.json();
            this.render();

        } catch (error) {
            console.error('Transit API error:', error);
            this.showError();
        }
    }

    render() {
        this.container.innerHTML = this.arrivals.slice(0, 8).map(arrival => `
            <div class="arrival-row">
                <div class="route" style="background: ${arrival.routeColor}">
                    ${arrival.routeName}
                </div>
                <div class="destination">${escapeHtml(arrival.destination)}</div>
                <div class="time" data-arrival="${arrival.expectedTime}">
                    ${this.formatTime(arrival.expectedTime)}
                </div>
            </div>
        `).join('');
    }

    updateCountdowns() {
        const timeElements = this.container.querySelectorAll('.time');
        const now = Date.now();

        timeElements.forEach(el => {
            const arrivalTime = parseInt(el.dataset.arrival);
            const minutes = Math.floor((arrivalTime - now) / 60000);

            if (minutes <= 0) {
                el.textContent = 'Now';
                el.classList.add('arriving');
            } else if (minutes === 1) {
                el.textContent = '1 min';
            } else {
                el.textContent = `${minutes} min`;
            }
        });
    }

    formatTime(timestamp) {
        const minutes = Math.floor((timestamp - Date.now()) / 60000);
        if (minutes <= 0) return 'Now';
        if (minutes === 1) return '1 min';
        return `${minutes} min`;
    }

    showError() {
        this.container.innerHTML = `
            <div class="error-message">
                Unable to load arrivals. Retrying...
            </div>
        `;
    }
}

// Initialize
const display = new TransitDisplay('STOP_123', 'arrivals-container');
display.start();
```

---

## Part 5: Smooth Data Transitions

### CSS Transitions for Updates

```css
.data-item {
    transition: all 0.3s ease;
}

.data-item.updating {
    opacity: 0.5;
    transform: scale(0.98);
}

.data-item.new {
    animation: slideIn 0.5s ease;
}

@keyframes slideIn {
    from {
        opacity: 0;
        transform: translateY(-20px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.data-item.removed {
    animation: slideOut 0.3s ease forwards;
}

@keyframes slideOut {
    to {
        opacity: 0;
        transform: translateX(100px);
    }
}
```

### JavaScript: Animated List Updates

```javascript
function updateList(newItems, container) {
    const existingIds = new Set(
        [...container.children].map(el => el.dataset.id)
    );
    const newIds = new Set(newItems.map(item => item.id));

    // Remove items no longer present
    [...container.children].forEach(el => {
        if (!newIds.has(el.dataset.id)) {
            el.classList.add('removed');
            setTimeout(() => el.remove(), 300);
        }
    });

    // Add or update items
    newItems.forEach((item, index) => {
        let element = container.querySelector(`[data-id="${item.id}"]`);

        if (!element) {
            // New item
            element = createItemElement(item);
            element.classList.add('new');

            const insertBefore = container.children[index];
            if (insertBefore) {
                container.insertBefore(element, insertBefore);
            } else {
                container.appendChild(element);
            }

            setTimeout(() => element.classList.remove('new'), 500);

        } else {
            // Update existing
            updateItemElement(element, item);
        }
    });
}
```

---

## Part 6: Handling Disconnections

### Offline Fallback Strategy

```javascript
class ResilientFeed {
    constructor(url, options = {}) {
        this.url = url;
        this.cacheKey = options.cacheKey || 'feed-cache';
        this.staleCacheMaxAge = options.staleCacheMaxAge || 3600000;  // 1 hour
        this.onData = options.onData;
        this.onStatus = options.onStatus;
    }

    async fetch() {
        try {
            this.onStatus?.('fetching');

            const response = await fetch(this.url, {
                signal: AbortSignal.timeout(30000)
            });

            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const data = await response.json();

            // Cache successful response
            this.cacheData(data);

            this.onStatus?.('live');
            this.onData?.(data, { source: 'live' });

            return data;

        } catch (error) {
            console.error('Fetch error:', error);

            // Try cached data
            const cached = this.getCachedData();

            if (cached) {
                const age = Date.now() - cached.timestamp;
                const isStale = age > this.staleCacheMaxAge;

                this.onStatus?.(isStale ? 'stale' : 'cached');
                this.onData?.(cached.data, {
                    source: 'cache',
                    age: age,
                    stale: isStale
                });

                return cached.data;
            }

            this.onStatus?.('offline');
            throw error;
        }
    }

    cacheData(data) {
        try {
            localStorage.setItem(this.cacheKey, JSON.stringify({
                data: data,
                timestamp: Date.now()
            }));
        } catch (error) {
            console.warn('Cache write failed:', error);
        }
    }

    getCachedData() {
        try {
            const cached = localStorage.getItem(this.cacheKey);
            return cached ? JSON.parse(cached) : null;
        } catch (error) {
            return null;
        }
    }
}

// Usage
const feed = new ResilientFeed('https://api.example.com/data', {
    cacheKey: 'news-feed',
    staleCacheMaxAge: 1800000,  // 30 minutes
    onData: (data, meta) => {
        updateDisplay(data);
        if (meta.stale) {
            showWarning('Showing cached data - unable to reach server');
        }
    },
    onStatus: (status) => {
        updateConnectionIndicator(status);
    }
});
```

---

## Best Practices

### Do

- **Choose appropriate update frequency** - match business needs
- **Implement exponential backoff** for reconnection attempts
- **Cache data locally** for offline resilience
- **Show connection status** to indicate live vs cached data
- **Use smooth transitions** when updating displayed data
- **Handle errors gracefully** - never show broken UI
- **Validate incoming data** before displaying
- **Compress WebSocket messages** for high-frequency data

### Don't

- **Don't poll too frequently** - respect API rate limits
- **Don't ignore connection state** - users should know if data is stale
- **Don't block UI** on network operations
- **Don't trust all incoming data** - sanitize for XSS
- **Don't keep stale connections** - implement heartbeats

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Data stops updating | Connection lost | Implement auto-reconnect |
| WebSocket closes immediately | Server/proxy timeout | Send heartbeat pings |
| High latency | Network congestion | Check connection, reduce frequency |
| Memory leak | Event listeners not cleaned | Clean up on disconnect |
| Flickering display | Too many updates | Batch/throttle updates |

---

## Exercises

1. **News Ticker**: Build a scrolling news ticker that updates from an RSS feed every 5 minutes

2. **Stock Dashboard**: Create a real-time stock price display using WebSockets with offline fallback

3. **Transit Board**: Build a transit arrivals display with countdown timers and API polling

4. **Social Wall**: Create a social media feed aggregating multiple sources with smooth animations

---

## Next Steps

- [Fetching Remote Content](08-fetching-remote-content.md) - Download and cache content
- [Integrating with REST APIs](09-integrating-rest-apis.md) - Consume external APIs
- [Setting Up BSN.cloud](10-setting-up-bsn-cloud.md) - Connect to cloud management

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
