# Integrating with REST APIs

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers consuming external REST APIs in your BrightSign applications. REST API integration enables your digital signage to display dynamic data like weather, news, social media feeds, inventory levels, or any custom data from your backend systems.

### What You'll Learn

- Making GET, POST, PUT, and DELETE requests
- Working with JSON data
- Implementing authentication (API keys, OAuth, Bearer tokens)
- Error handling and retry strategies
- Best practices for API integration in signage

### Common API Use Cases

| Use Case | Example APIs |
|----------|--------------|
| Weather | OpenWeatherMap, Weather.gov |
| News/RSS | News API, custom RSS feeds |
| Social Media | Twitter/X, Instagram (via graph API) |
| Business Data | Custom REST APIs, inventory systems |
| Transportation | Transit APIs, flight information |
| Financial | Stock quotes, currency exchange |

---

## Prerequisites

- Completed [Fetching Remote Content](08-fetching-remote-content.md) guide
- BrightSign player with network connectivity
- API key or credentials for your target API
- Understanding of JSON data format

---

## Making GET Requests

### BrightScript: Basic GET

```brightscript
Sub Main()
    ' Create URL transfer object
    urlTransfer = CreateObject("roUrlTransfer")

    ' Set the API endpoint
    urlTransfer.SetUrl("https://api.example.com/v1/data")

    ' Add API key header (common authentication method)
    urlTransfer.AddHeader("X-API-Key", "your-api-key-here")
    urlTransfer.AddHeader("Accept", "application/json")

    ' Make the request
    response = urlTransfer.GetToString()

    if response <> "" then
        ' Parse JSON response
        data = ParseJson(response)

        if data <> invalid then
            print "API Response:"
            print formatJson(data)
        else
            print "Failed to parse JSON"
        end if
    else
        print "Request failed: "; urlTransfer.GetResponseCode()
    end if
End Sub
```

### BrightScript: Asynchronous GET

```brightscript
Sub Main()
    msgPort = CreateObject("roMessagePort")

    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetPort(msgPort)
    urlTransfer.SetUrl("https://api.example.com/v1/items")
    urlTransfer.AddHeader("Authorization", "Bearer your-token")
    urlTransfer.AddHeader("Accept", "application/json")

    ' Start async request
    if urlTransfer.AsyncGetToString() then
        print "Request started..."
    else
        print "Failed to start request"
        return
    end if

    ' Wait for response
    while true
        msg = wait(30000, msgPort)  ' 30 second timeout

        if msg = invalid then
            print "Request timed out"
            urlTransfer.AsyncCancel()
            exit while
        end if

        if type(msg) = "roUrlEvent" then
            responseCode = msg.GetResponseCode()

            if responseCode = 200 then
                response = msg.GetString()
                data = ParseJson(response)
                ProcessApiData(data)
            else
                print "API error: "; responseCode
                print "Details: "; msg.GetFailureReason()
            end if

            exit while
        end if
    end while
End Sub

Sub ProcessApiData(data as Object)
    if data = invalid then return

    ' Process your API data here
    print "Received "; data.items.Count(); " items"

    for each item in data.items
        print "- "; item.name; ": "; item.value
    end for
End Sub
```

### JavaScript: Using fetch()

```javascript
async function getApiData() {
    const url = 'https://api.example.com/v1/data';

    const response = await fetch(url, {
        method: 'GET',
        headers: {
            'Accept': 'application/json',
            'X-API-Key': 'your-api-key-here'
        }
    });

    if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
    }

    const data = await response.json();
    console.log('API response:', data);
    return data;
}
```

---

## Making POST Requests

### BrightScript: POST with JSON Body

```brightscript
Function PostToApi(endpoint as String, payload as Object) as Object
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(endpoint)

    ' Set headers for JSON
    urlTransfer.AddHeader("Content-Type", "application/json")
    urlTransfer.AddHeader("Accept", "application/json")
    urlTransfer.AddHeader("Authorization", "Bearer your-token")

    ' Convert payload to JSON string
    jsonBody = formatJson(payload)

    ' Make POST request
    response = urlTransfer.PostFromString(jsonBody)

    if response <> "" then
        return ParseJson(response)
    else
        print "POST failed: "; urlTransfer.GetResponseCode()
        return invalid
    end if
End Function

Sub Main()
    ' Example: Log player event to API
    payload = {
        playerId: GetPlayerId(),
        event: "startup",
        timestamp: GetCurrentTimestamp(),
        data: {
            firmwareVersion: GetFirmwareVersion(),
            ipAddress: GetIPAddress()
        }
    }

    result = PostToApi("https://api.example.com/v1/events", payload)

    if result <> invalid then
        print "Event logged, ID: "; result.eventId
    end if
End Sub

Function GetPlayerId() as String
    deviceInfo = CreateObject("roDeviceInfo")
    return deviceInfo.GetDeviceUniqueId()
End Function

Function GetCurrentTimestamp() as String
    dateTime = CreateObject("roDateTime")
    dateTime.ToLocalTime()
    return dateTime.ToISOString()
End Function

Function GetFirmwareVersion() as String
    deviceInfo = CreateObject("roDeviceInfo")
    return deviceInfo.GetVersion()
End Function

Function GetIPAddress() as String
    nc = CreateObject("roNetworkConfiguration", 0)
    return nc.GetCurrentConfig().ip4_address
End Function
```

### JavaScript: POST Request

```javascript
async function postEvent(eventType, eventData) {
    const url = 'https://api.example.com/v1/events';

    const payload = {
        playerId: await getDeviceId(),
        event: eventType,
        timestamp: new Date().toISOString(),
        data: eventData
    };

    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer your-token'
        },
        body: JSON.stringify(payload)
    });

    if (!response.ok) {
        throw new Error(`POST failed: ${response.status}`);
    }

    return await response.json();
}

async function getDeviceId() {
    // Using BrightSign JavaScript API
    const deviceInfo = new BSDeviceInfo();
    return deviceInfo.deviceUniqueId;
}
```

---

## PUT and DELETE Requests

### BrightScript: PUT Request

```brightscript
Function UpdateResource(endpoint as String, data as Object) as Boolean
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(endpoint)
    urlTransfer.AddHeader("Content-Type", "application/json")
    urlTransfer.AddHeader("Authorization", "Bearer your-token")

    ' Use SetRequest for PUT
    urlTransfer.SetRequest("PUT")

    jsonBody = formatJson(data)
    response = urlTransfer.PostFromString(jsonBody)

    responseCode = urlTransfer.GetResponseCode()
    return (responseCode >= 200 and responseCode < 300)
End Function
```

### BrightScript: DELETE Request

```brightscript
Function DeleteResource(endpoint as String) as Boolean
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(endpoint)
    urlTransfer.AddHeader("Authorization", "Bearer your-token")

    ' Use SetRequest for DELETE
    urlTransfer.SetRequest("DELETE")

    ' Send empty body
    response = urlTransfer.PostFromString("")

    responseCode = urlTransfer.GetResponseCode()
    return (responseCode >= 200 and responseCode < 300)
End Function
```

### JavaScript: PUT and DELETE

```javascript
async function updateResource(id, data) {
    const response = await fetch(`https://api.example.com/v1/items/${id}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer your-token'
        },
        body: JSON.stringify(data)
    });

    return response.ok;
}

async function deleteResource(id) {
    const response = await fetch(`https://api.example.com/v1/items/${id}`, {
        method: 'DELETE',
        headers: {
            'Authorization': 'Bearer your-token'
        }
    });

    return response.ok;
}
```

---

## Working with JSON Data

### Parsing Complex JSON

```brightscript
Sub ProcessComplexJson()
    jsonString = `{
        "status": "success",
        "data": {
            "items": [
                {"id": 1, "name": "Product A", "price": 29.99},
                {"id": 2, "name": "Product B", "price": 49.99}
            ],
            "pagination": {
                "page": 1,
                "total": 100,
                "perPage": 10
            }
        },
        "metadata": {
            "timestamp": "2024-01-15T10:30:00Z",
            "version": "1.0"
        }
    }`

    data = ParseJson(jsonString)

    if data = invalid then
        print "JSON parse error"
        return
    end if

    ' Access nested objects
    print "Status: "; data.status
    print "Timestamp: "; data.metadata.timestamp

    ' Iterate arrays
    for each item in data.data.items
        print item.name; " - $"; item.price
    end for

    ' Access pagination
    print "Page "; data.data.pagination.page; " of "; data.data.pagination.total
End Sub
```

### JavaScript JSON Handling

```javascript
function processApiResponse(response) {
    const { status, data, metadata } = response;

    if (status !== 'success') {
        console.error('API returned error status');
        return;
    }

    // Destructure nested data
    const { items, pagination } = data;

    // Process items
    items.forEach(item => {
        console.log(`${item.name}: $${item.price.toFixed(2)}`);
        displayProduct(item);
    });

    // Update pagination UI
    updatePagination(pagination);
}

function displayProduct(product) {
    const container = document.getElementById('products');
    const element = document.createElement('div');
    element.className = 'product';
    element.innerHTML = `
        <h3>${escapeHtml(product.name)}</h3>
        <p class="price">$${product.price.toFixed(2)}</p>
    `;
    container.appendChild(element);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
```

---

## Authentication Methods

### API Key Authentication

```brightscript
' Header-based API key
urlTransfer.AddHeader("X-API-Key", "your-api-key")

' Query parameter API key
url = "https://api.example.com/data?api_key=your-api-key"
urlTransfer.SetUrl(url)
```

### Bearer Token Authentication

```brightscript
Function MakeAuthenticatedRequest(url as String, token as String) as Object
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(url)
    urlTransfer.AddHeader("Authorization", "Bearer " + token)
    urlTransfer.AddHeader("Accept", "application/json")

    response = urlTransfer.GetToString()
    return ParseJson(response)
End Function
```

### OAuth 2.0 Client Credentials Flow

```brightscript
Function GetOAuthToken(clientId as String, clientSecret as String, tokenUrl as String) as String
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(tokenUrl)
    urlTransfer.AddHeader("Content-Type", "application/x-www-form-urlencoded")

    ' Build form data
    formData = "grant_type=client_credentials"
    formData = formData + "&client_id=" + UrlEncode(clientId)
    formData = formData + "&client_secret=" + UrlEncode(clientSecret)

    response = urlTransfer.PostFromString(formData)

    if response <> "" then
        tokenData = ParseJson(response)
        if tokenData <> invalid and tokenData.access_token <> invalid then
            return tokenData.access_token
        end if
    end if

    return ""
End Function

Function UrlEncode(str as String) as String
    urlTransfer = CreateObject("roUrlTransfer")
    return urlTransfer.Escape(str)
End Function

' Usage
Sub Main()
    token = GetOAuthToken("my-client-id", "my-client-secret", "https://auth.example.com/oauth/token")

    if token <> "" then
        ' Use token for API calls
        data = MakeAuthenticatedRequest("https://api.example.com/data", token)
    end if
End Sub
```

### JavaScript OAuth Implementation

```javascript
class ApiClient {
    constructor(clientId, clientSecret, tokenUrl, baseUrl) {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.tokenUrl = tokenUrl;
        this.baseUrl = baseUrl;
        this.accessToken = null;
        this.tokenExpiry = null;
    }

    async getToken() {
        // Return cached token if still valid
        if (this.accessToken && this.tokenExpiry > Date.now()) {
            return this.accessToken;
        }

        const response = await fetch(this.tokenUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({
                grant_type: 'client_credentials',
                client_id: this.clientId,
                client_secret: this.clientSecret
            })
        });

        if (!response.ok) {
            throw new Error('Failed to obtain token');
        }

        const data = await response.json();
        this.accessToken = data.access_token;
        // Set expiry with 5 minute buffer
        this.tokenExpiry = Date.now() + (data.expires_in - 300) * 1000;

        return this.accessToken;
    }

    async request(endpoint, options = {}) {
        const token = await this.getToken();

        const response = await fetch(`${this.baseUrl}${endpoint}`, {
            ...options,
            headers: {
                'Authorization': `Bearer ${token}`,
                'Accept': 'application/json',
                ...options.headers
            }
        });

        if (response.status === 401) {
            // Token expired, clear and retry once
            this.accessToken = null;
            return this.request(endpoint, options);
        }

        return response;
    }

    async get(endpoint) {
        const response = await this.request(endpoint);
        return response.json();
    }

    async post(endpoint, data) {
        const response = await this.request(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        return response.json();
    }
}

// Usage
const api = new ApiClient(
    'client-id',
    'client-secret',
    'https://auth.example.com/oauth/token',
    'https://api.example.com/v1'
);

const data = await api.get('/items');
```

---

## Error Handling and Retry

### Robust API Client (BrightScript)

```brightscript
Function ApiRequest(method as String, url as String, body = "" as String, maxRetries = 3 as Integer) as Object
    result = {
        success: false,
        statusCode: 0,
        data: invalid,
        error: ""
    }

    for attempt = 1 to maxRetries
        urlTransfer = CreateObject("roUrlTransfer")
        urlTransfer.SetUrl(url)
        urlTransfer.SetTimeout(30000)
        urlTransfer.AddHeader("Accept", "application/json")
        urlTransfer.AddHeader("Authorization", "Bearer " + GetStoredToken())

        if method = "GET" then
            response = urlTransfer.GetToString()
        else
            urlTransfer.AddHeader("Content-Type", "application/json")
            if method <> "POST" then
                urlTransfer.SetRequest(method)
            end if
            response = urlTransfer.PostFromString(body)
        end if

        result.statusCode = urlTransfer.GetResponseCode()

        ' Success
        if result.statusCode >= 200 and result.statusCode < 300 then
            result.success = true
            if response <> "" then
                result.data = ParseJson(response)
            end if
            return result
        end if

        ' Client errors - don't retry
        if result.statusCode >= 400 and result.statusCode < 500 then
            result.error = "Client error: " + Str(result.statusCode)
            return result
        end if

        ' Server errors or network issues - retry
        print "Attempt "; attempt; " failed: "; result.statusCode

        if attempt < maxRetries then
            ' Exponential backoff
            sleep(1000 * (2 ^ (attempt - 1)))
        end if
    end for

    result.error = "Max retries exceeded"
    return result
End Function

' Usage
Sub FetchData()
    result = ApiRequest("GET", "https://api.example.com/v1/data")

    if result.success then
        ProcessData(result.data)
    else
        print "API call failed: "; result.error
        ShowErrorMessage("Unable to load data")
    end if
End Sub
```

### JavaScript Retry Logic

```javascript
async function apiRequestWithRetry(url, options = {}, maxRetries = 3) {
    let lastError;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const response = await fetch(url, {
                ...options,
                signal: AbortSignal.timeout(30000)
            });

            // Success
            if (response.ok) {
                return {
                    success: true,
                    status: response.status,
                    data: await response.json()
                };
            }

            // Client error - don't retry
            if (response.status >= 400 && response.status < 500) {
                return {
                    success: false,
                    status: response.status,
                    error: `Client error: ${response.status}`
                };
            }

            // Server error - will retry
            lastError = new Error(`Server error: ${response.status}`);

        } catch (error) {
            lastError = error;
        }

        console.log(`Attempt ${attempt} failed, retrying...`);

        if (attempt < maxRetries) {
            await new Promise(r => setTimeout(r, 1000 * Math.pow(2, attempt - 1)));
        }
    }

    return {
        success: false,
        status: 0,
        error: lastError.message
    };
}
```

---

## Caching API Responses

```brightscript
Function CachedApiRequest(url as String, cacheKey as String, maxAgeSeconds as Integer) as Object
    cacheDir = "SD:/api_cache"
    cacheFile = cacheDir + "/" + cacheKey + ".json"
    metaFile = cacheFile + ".meta"

    fs = CreateObject("roFileSystem")
    fs.CreateDirectory(cacheDir)

    ' Check cache
    if fs.Exists(cacheFile) and fs.Exists(metaFile) then
        meta = ReadAsciiFile(metaFile)
        cachedTime = Val(meta)

        dateTime = CreateObject("roDateTime")
        currentTime = dateTime.AsSeconds()

        if (currentTime - cachedTime) < maxAgeSeconds then
            ' Cache hit
            cachedData = ReadAsciiFile(cacheFile)
            return ParseJson(cachedData)
        end if
    end if

    ' Cache miss - fetch from API
    result = ApiRequest("GET", url)

    if result.success then
        ' Save to cache
        WriteAsciiFile(cacheFile, formatJson(result.data))

        dateTime = CreateObject("roDateTime")
        WriteAsciiFile(metaFile, Str(dateTime.AsSeconds()))
    else
        ' Try stale cache on error
        if fs.Exists(cacheFile) then
            print "API failed, using stale cache"
            cachedData = ReadAsciiFile(cacheFile)
            return ParseJson(cachedData)
        end if
    end if

    return result.data
End Function
```

---

## Complete Example: Weather Dashboard

A full example integrating with a weather API:

### autorun.brs

```brightscript
Sub Main()
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    rect = CreateObject("roRectangle", 0, 0, 1920, 1080)

    config = {
        url: "file:///sd:/weather/index.html",
        mouse_enabled: false,
        storage_path: "SD:/html-storage",
        storage_quota: 10485760
    }

    htmlWidget = CreateObject("roHtmlWidget", rect, config)
    htmlWidget.Show()

    msgPort = CreateObject("roMessagePort")
    htmlWidget.SetPort(msgPort)

    ' Update timer - refresh every 15 minutes
    updateTimer = CreateObject("roTimer")
    updateTimer.SetPort(msgPort)
    updateTimer.SetElapsed(900, 0)

    ' Initial data fetch
    weatherData = FetchWeatherData()
    if weatherData <> invalid then
        htmlWidget.PostJSMessage({type: "weather", data: weatherData})
    end if

    updateTimer.Start()

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTimerEvent" then
            weatherData = FetchWeatherData()
            if weatherData <> invalid then
                htmlWidget.PostJSMessage({type: "weather", data: weatherData})
            end if
            updateTimer.Start()

        else if type(msg) = "roHtmlWidgetEvent" then
            eventData = msg.GetData()
            if eventData.reason = "message" then
                HandleJsMessage(eventData.message, htmlWidget)
            end if
        end if
    end while
End Sub

Function FetchWeatherData() as Object
    ' OpenWeatherMap API example
    apiKey = "your-openweathermap-api-key"
    city = "Seattle"
    url = "https://api.openweathermap.org/data/2.5/weather?q=" + city + "&appid=" + apiKey + "&units=imperial"

    result = ApiRequest("GET", url)

    if result.success then
        return result.data
    end if

    return invalid
End Function

Sub HandleJsMessage(message as Object, widget as Object)
    if message.action = "refresh" then
        weatherData = FetchWeatherData()
        if weatherData <> invalid then
            widget.PostJSMessage({type: "weather", data: weatherData})
        end if
    end if
End Sub
```

### weather/index.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=1920, height=1080">
    <title>Weather Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            width: 1920px;
            height: 1080px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            color: white;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }

        .weather-container {
            text-align: center;
            padding: 60px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 30px;
            backdrop-filter: blur(10px);
        }

        .city { font-size: 48px; margin-bottom: 20px; opacity: 0.9; }
        .temperature { font-size: 180px; font-weight: 200; line-height: 1; }
        .description { font-size: 36px; text-transform: capitalize; opacity: 0.8; }
        .details { display: flex; gap: 60px; margin-top: 40px; font-size: 24px; }
        .detail-item { text-align: center; }
        .detail-label { opacity: 0.6; margin-bottom: 8px; }
        .detail-value { font-size: 32px; }
        .updated { position: absolute; bottom: 40px; opacity: 0.5; font-size: 20px; }
        .loading { font-size: 36px; opacity: 0.7; }
    </style>
</head>
<body>
    <div class="weather-container">
        <div id="content" class="loading">Loading weather data...</div>
    </div>
    <div class="updated" id="updated"></div>

    <script>
        // Listen for messages from BrightScript
        window.addEventListener('bsmessage', (event) => {
            const message = event.data;

            if (message.type === 'weather') {
                updateWeatherDisplay(message.data);
            }
        });

        function updateWeatherDisplay(data) {
            const content = document.getElementById('content');
            const updated = document.getElementById('updated');

            content.innerHTML = `
                <div class="city">${escapeHtml(data.name)}</div>
                <div class="temperature">${Math.round(data.main.temp)}&deg;</div>
                <div class="description">${escapeHtml(data.weather[0].description)}</div>
                <div class="details">
                    <div class="detail-item">
                        <div class="detail-label">Humidity</div>
                        <div class="detail-value">${data.main.humidity}%</div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Wind</div>
                        <div class="detail-value">${Math.round(data.wind.speed)} mph</div>
                    </div>
                    <div class="detail-item">
                        <div class="detail-label">Feels Like</div>
                        <div class="detail-value">${Math.round(data.main.feels_like)}&deg;</div>
                    </div>
                </div>
            `;

            updated.textContent = `Updated: ${new Date().toLocaleTimeString()}`;
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        // Request refresh on click (for testing)
        document.body.addEventListener('click', () => {
            window.bsMessage({ action: 'refresh' });
        });
    </script>
</body>
</html>
```

---

## Best Practices

### Do

- **Cache responses** to reduce API calls and handle offline scenarios
- **Use async requests** to keep UI responsive
- **Implement retry logic** with exponential backoff
- **Validate API responses** before using data
- **Store credentials securely** - use encrypted storage or secure provisioning
- **Handle rate limits** gracefully - check response headers
- **Log API activity** for debugging production issues
- **Set appropriate timeouts** (15-30 seconds typical)

### Don't

- **Don't hardcode credentials** in source files
- **Don't ignore errors** - always have fallback behavior
- **Don't call APIs too frequently** - respect rate limits
- **Don't trust API data** without validation
- **Don't block the main thread** with synchronous requests
- **Don't expose sensitive data** in logs

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| 401 Unauthorized | Invalid or expired token | Check credentials, refresh token |
| 403 Forbidden | Missing permissions | Verify API key has required scopes |
| 429 Too Many Requests | Rate limit exceeded | Implement backoff, cache responses |
| CORS error (HTML5) | Cross-origin blocked | Use BrightScript for API calls, proxy |
| JSON parse error | Invalid response | Log raw response, validate JSON |
| Timeout | Slow network/server | Increase timeout, add retry logic |

---

## Exercises

1. **Weather Widget**: Build a weather display that fetches and caches weather data from OpenWeatherMap API

2. **News Feed**: Create a scrolling news ticker that pulls headlines from a news API

3. **Inventory Display**: Build a product availability board that syncs with a REST API every 5 minutes

4. **Multi-API Dashboard**: Create a dashboard combining weather, news, and custom API data

---

## Next Steps

- [Setting Up BSN.cloud](10-setting-up-bsn-cloud.md) - Connect players to BrightSign's cloud platform
- [Implementing Live Data Feeds](11-implementing-live-data-feeds.md) - Display real-time information

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
