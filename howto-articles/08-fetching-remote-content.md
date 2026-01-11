# Fetching Remote Content

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers downloading and caching content from web servers on BrightSign players. Remote content fetching is essential for digital signage applications that need to display up-to-date images, videos, data files, or configuration from a central server.

### Why Fetch Remote Content?

- **Dynamic Updates**: Change displayed content without physical access to players
- **Centralized Management**: Store content on web servers, CDNs, or cloud storage
- **Bandwidth Efficiency**: Download content during off-hours, cache locally
- **Content Freshness**: Keep displays current with latest assets

### Fetching Approaches

| Approach | Best For | Key Object/API |
|----------|----------|----------------|
| **BrightScript** | Background downloads, large files | `roUrlTransfer` |
| **HTML5 JavaScript** | Web apps, JSON data, small assets | `fetch()` API |
| **Hybrid** | Large downloads + web UI | BrightScript download + HTML display |

---

## Prerequisites

- BrightSign player connected to network (Ethernet or WiFi)
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))
- Basic knowledge of BrightScript or JavaScript ([see HTML5 guide](03-first-html5-application.md))
- Web server or CDN hosting your content

---

## BrightScript: Using roUrlTransfer

`roUrlTransfer` is the primary object for HTTP operations in BrightScript. It handles downloads, uploads, and API calls.

### Basic File Download

```brightscript
Sub Main()
    ' Create URL transfer object
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl("https://example.com/content/image.jpg")

    ' Download to local storage
    destination = "SD:/downloaded/image.jpg"
    success = urlTransfer.GetToFile(destination)

    if success = 200 then
        print "Download successful: "; destination
    else
        print "Download failed with code: "; success
    end if
End Sub
```

### Asynchronous Downloads (Recommended)

For responsive applications, use asynchronous downloads with a message port:

```brightscript
Sub Main()
    ' Create message port for events
    msgPort = CreateObject("roMessagePort")

    ' Create and configure URL transfer
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetPort(msgPort)
    urlTransfer.SetUrl("https://example.com/content/video.mp4")

    ' Start asynchronous download
    destination = "SD:/downloaded/video.mp4"
    if urlTransfer.AsyncGetToFile(destination) then
        print "Download started..."
    else
        print "Failed to start download"
        return
    end if

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roUrlEvent" then
            responseCode = msg.GetResponseCode()

            if responseCode = 200 then
                print "Download complete!"
                print "File size: "; msg.GetTargetBody().Count(); " bytes"
                ' Process the downloaded file
                exit while
            else if responseCode < 0 then
                print "Network error: "; msg.GetFailureReason()
            else
                print "HTTP error: "; responseCode
            end if
        end if
    end while
End Sub
```

### Download with Progress Monitoring

Track download progress for large files:

```brightscript
Sub DownloadWithProgress(url as String, destination as String)
    msgPort = CreateObject("roMessagePort")

    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetPort(msgPort)
    urlTransfer.SetUrl(url)

    ' Enable progress events
    urlTransfer.EnableProgressEvents(true)

    if not urlTransfer.AsyncGetToFile(destination) then
        print "Failed to start download"
        return
    end if

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roUrlEvent" then
            eventType = msg.GetSourceIdentity()

            if msg.GetResponseCode() = 200 then
                print "Download complete!"
                exit while
            else if msg.GetResponseCode() < 0 then
                print "Error: "; msg.GetFailureReason()
                exit while
            end if

        else if type(msg) = "roUrlTransferProgressEvent" then
            ' Progress update
            current = msg.GetCurrentBytesTransferred()
            total = msg.GetTotalBytesToTransfer()

            if total > 0 then
                percent = Int((current / total) * 100)
                print "Progress: "; percent; "%"
            else
                print "Downloaded: "; current; " bytes"
            end if
        end if
    end while
End Sub
```

### Configuring HTTP Options

```brightscript
Sub ConfiguredDownload()
    urlTransfer = CreateObject("roUrlTransfer")

    ' Set URL
    urlTransfer.SetUrl("https://api.example.com/content")

    ' Set timeout (milliseconds)
    urlTransfer.SetTimeout(30000)  ' 30 seconds

    ' Add custom headers
    urlTransfer.AddHeader("Authorization", "Bearer your-token-here")
    urlTransfer.AddHeader("Accept", "application/json")
    urlTransfer.AddHeader("User-Agent", "BrightSign/1.0")

    ' Enable HTTPS certificate verification (recommended for production)
    urlTransfer.EnablePeerVerification(true)
    urlTransfer.EnableHostVerification(true)

    ' Set certificate authority file if needed
    ' urlTransfer.SetCertificatesFile("SD:/certs/ca-bundle.crt")

    ' Make request
    response = urlTransfer.GetToString()
    print response
End Sub
```

---

## HTML5 JavaScript: Using fetch()

For HTML5 applications, the standard `fetch()` API provides a modern, promise-based approach.

### Basic Fetch

```javascript
async function fetchContent() {
    try {
        const response = await fetch('https://example.com/data.json');

        if (!response.ok) {
            throw new Error(`HTTP error: ${response.status}`);
        }

        const data = await response.json();
        console.log('Fetched data:', data);
        return data;

    } catch (error) {
        console.error('Fetch failed:', error);
        return null;
    }
}
```

### Fetching Images

```javascript
async function loadImage(url, imgElement) {
    try {
        const response = await fetch(url);

        if (!response.ok) {
            throw new Error(`Failed to fetch image: ${response.status}`);
        }

        const blob = await response.blob();
        const objectUrl = URL.createObjectURL(blob);

        imgElement.src = objectUrl;

        // Clean up object URL after image loads
        imgElement.onload = () => {
            URL.revokeObjectURL(objectUrl);
        };

    } catch (error) {
        console.error('Image load failed:', error);
        imgElement.src = 'fallback.jpg';
    }
}

// Usage
const img = document.getElementById('dynamic-image');
loadImage('https://example.com/images/banner.jpg', img);
```

### Fetching with Headers and Options

```javascript
async function fetchWithAuth(url) {
    const options = {
        method: 'GET',
        headers: {
            'Authorization': 'Bearer your-token-here',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache'
        },
        // Timeout using AbortController
        signal: AbortSignal.timeout(30000)
    };

    try {
        const response = await fetch(url, options);

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        return await response.json();

    } catch (error) {
        if (error.name === 'TimeoutError') {
            console.error('Request timed out');
        } else {
            console.error('Fetch error:', error);
        }
        return null;
    }
}
```

---

## Implementing Content Caching

Caching prevents repeated downloads and ensures content is available offline.

### BrightScript: File-Based Cache

```brightscript
Function CachedDownload(url as String, cacheDir as String, maxAgeSeconds as Integer) as String
    ' Generate cache filename from URL
    urlHash = CreateObject("roDeviceInfo").GetDeviceUniqueId() + url
    cacheFile = cacheDir + "/" + GetMD5Hash(url) + ".cache"
    metaFile = cacheFile + ".meta"

    ' Check if cached file exists and is fresh
    if IsCacheValid(metaFile, maxAgeSeconds) then
        print "Using cached file: "; cacheFile
        return cacheFile
    end if

    ' Download fresh content
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(url)

    result = urlTransfer.GetToFile(cacheFile)

    if result = 200 then
        ' Save metadata with timestamp
        SaveCacheMeta(metaFile, url)
        print "Downloaded and cached: "; cacheFile
        return cacheFile
    else
        ' Return stale cache if download fails
        if FileExists(cacheFile) then
            print "Download failed, using stale cache"
            return cacheFile
        end if
        return ""
    end if
End Function

Function IsCacheValid(metaFile as String, maxAgeSeconds as Integer) as Boolean
    if not FileExists(metaFile) then return false

    ' Read timestamp from meta file
    meta = ReadAsciiFile(metaFile)
    cachedTime = Val(meta)

    ' Get current time
    dateTime = CreateObject("roDateTime")
    currentTime = dateTime.AsSeconds()

    return (currentTime - cachedTime) < maxAgeSeconds
End Function

Function SaveCacheMeta(metaFile as String, url as String)
    dateTime = CreateObject("roDateTime")
    timestamp = dateTime.AsSeconds()
    WriteAsciiFile(metaFile, Str(timestamp))
End Function

Function FileExists(path as String) as Boolean
    fs = CreateObject("roFileSystem")
    return fs.Exists(path)
End Function

Function GetMD5Hash(input as String) as String
    ' Simple hash for cache key (use roMessageDigest for real MD5)
    digest = CreateObject("roMessageDigest")
    digest.SetAlgorithm("md5")
    digest.Update(input)
    return digest.Final()
End Function
```

### JavaScript: localStorage Cache

```javascript
class ContentCache {
    constructor(prefix = 'content_cache_') {
        this.prefix = prefix;
    }

    getCacheKey(url) {
        return this.prefix + btoa(url).replace(/[^a-zA-Z0-9]/g, '');
    }

    async get(url, maxAgeMs = 3600000) {  // 1 hour default
        const key = this.getCacheKey(url);
        const cached = localStorage.getItem(key);

        if (cached) {
            const { data, timestamp } = JSON.parse(cached);
            const age = Date.now() - timestamp;

            if (age < maxAgeMs) {
                console.log('Cache hit:', url);
                return data;
            }
        }

        // Fetch fresh data
        try {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const data = await response.json();

            // Cache the result
            localStorage.setItem(key, JSON.stringify({
                data: data,
                timestamp: Date.now()
            }));

            console.log('Cache miss, fetched:', url);
            return data;

        } catch (error) {
            // Return stale cache on error
            if (cached) {
                console.warn('Fetch failed, using stale cache');
                return JSON.parse(cached).data;
            }
            throw error;
        }
    }

    invalidate(url) {
        localStorage.removeItem(this.getCacheKey(url));
    }

    clear() {
        const keys = Object.keys(localStorage);
        keys.filter(k => k.startsWith(this.prefix))
            .forEach(k => localStorage.removeItem(k));
    }
}

// Usage
const cache = new ContentCache();
const data = await cache.get('https://api.example.com/playlist.json', 300000);  // 5 min cache
```

---

## Handling Network Errors

Robust error handling is critical for deployed signage.

### BrightScript Error Handling

```brightscript
Function SafeDownload(url as String, destination as String, retries as Integer) as Boolean
    attempt = 0

    while attempt < retries
        attempt = attempt + 1
        print "Download attempt "; attempt; " of "; retries

        urlTransfer = CreateObject("roUrlTransfer")
        urlTransfer.SetUrl(url)
        urlTransfer.SetTimeout(30000)

        result = urlTransfer.GetToFile(destination)

        if result = 200 then
            print "Download successful"
            return true
        else if result = -1 then
            print "Network unreachable"
        else if result = -2 then
            print "Timeout"
        else if result = -3 then
            print "Connection refused"
        else if result >= 400 and result < 500 then
            print "Client error: "; result
            return false  ' Don't retry client errors
        else if result >= 500 then
            print "Server error: "; result
        else
            print "Unknown error: "; result
        end if

        ' Wait before retry (exponential backoff)
        sleep(1000 * attempt)
    end while

    print "All download attempts failed"
    return false
End Function
```

### JavaScript Error Handling with Retry

```javascript
async function fetchWithRetry(url, options = {}, maxRetries = 3) {
    let lastError;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            console.log(`Fetch attempt ${attempt}/${maxRetries}`);

            const response = await fetch(url, {
                ...options,
                signal: AbortSignal.timeout(30000)
            });

            if (!response.ok) {
                // Don't retry 4xx errors
                if (response.status >= 400 && response.status < 500) {
                    throw new Error(`Client error: ${response.status}`);
                }
                throw new Error(`Server error: ${response.status}`);
            }

            return response;

        } catch (error) {
            lastError = error;
            console.error(`Attempt ${attempt} failed:`, error.message);

            // Don't retry if aborted or client error
            if (error.name === 'AbortError' ||
                error.message.startsWith('Client error')) {
                break;
            }

            // Exponential backoff
            if (attempt < maxRetries) {
                const delay = 1000 * Math.pow(2, attempt - 1);
                await new Promise(r => setTimeout(r, delay));
            }
        }
    }

    throw lastError;
}
```

---

## Content Validation

Verify downloaded content integrity before use.

### BrightScript: Checksum Validation

```brightscript
Function ValidateDownload(url as String, destination as String, expectedMd5 as String) as Boolean
    ' Download the file
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(url)

    if urlTransfer.GetToFile(destination) <> 200 then
        print "Download failed"
        return false
    end if

    ' Calculate MD5 of downloaded file
    digest = CreateObject("roMessageDigest")
    digest.SetAlgorithm("md5")

    fs = CreateObject("roFileSystem")
    file = fs.OpenInputFile(destination)

    if file = invalid then
        print "Cannot open file for validation"
        return false
    end if

    ' Read and hash file in chunks
    while true
        chunk = file.Read(65536)  ' 64KB chunks
        if chunk.Count() = 0 then exit while
        digest.Update(chunk)
    end while

    actualMd5 = LCase(digest.Final())
    expectedMd5 = LCase(expectedMd5)

    if actualMd5 = expectedMd5 then
        print "Checksum valid"
        return true
    else
        print "Checksum mismatch!"
        print "Expected: "; expectedMd5
        print "Actual: "; actualMd5

        ' Delete corrupted file
        fs.Delete(destination)
        return false
    end if
End Function
```

---

## Complete Example: Content Sync Application

A full example that downloads a content manifest and syncs files:

```brightscript
Sub Main()
    ' Configuration
    manifestUrl = "https://content.example.com/manifest.json"
    contentDir = "SD:/content"
    syncInterval = 300  ' 5 minutes

    ' Ensure content directory exists
    fs = CreateObject("roFileSystem")
    fs.CreateDirectory(contentDir)

    ' Create message port for timer
    msgPort = CreateObject("roMessagePort")
    timer = CreateObject("roTimer")
    timer.SetPort(msgPort)

    ' Initial sync
    SyncContent(manifestUrl, contentDir)

    ' Schedule periodic sync
    timer.SetElapsed(syncInterval, 0)
    timer.Start()

    ' Main loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTimerEvent" then
            print "Sync timer fired"
            SyncContent(manifestUrl, contentDir)
            timer.Start()  ' Restart timer
        end if
    end while
End Sub

Sub SyncContent(manifestUrl as String, contentDir as String)
    print "Starting content sync..."

    ' Download manifest
    urlTransfer = CreateObject("roUrlTransfer")
    urlTransfer.SetUrl(manifestUrl)

    manifestJson = urlTransfer.GetToString()

    if manifestJson = "" then
        print "Failed to fetch manifest"
        return
    end if

    ' Parse manifest
    manifest = ParseJson(manifestJson)

    if manifest = invalid then
        print "Invalid manifest JSON"
        return
    end if

    ' Sync each file
    fs = CreateObject("roFileSystem")

    for each item in manifest.files
        filename = item.name
        remoteUrl = item.url
        expectedSize = item.size

        localPath = contentDir + "/" + filename

        ' Check if file needs update
        if fs.Exists(localPath) then
            stat = fs.Stat(localPath)
            if stat.size = expectedSize then
                print "Skipping (up to date): "; filename
                continue for
            end if
        end if

        ' Download file
        print "Downloading: "; filename
        urlTransfer.SetUrl(remoteUrl)
        result = urlTransfer.GetToFile(localPath)

        if result = 200 then
            print "Downloaded: "; filename
        else
            print "Failed to download: "; filename; " ("; result; ")"
        end if
    end for

    print "Content sync complete"
End Sub
```

---

## Best Practices

### Do

- **Use asynchronous downloads** for large files to keep UI responsive
- **Implement caching** to reduce bandwidth and improve offline reliability
- **Add retry logic** with exponential backoff for transient failures
- **Validate content** with checksums for critical files
- **Set reasonable timeouts** (30 seconds is typical)
- **Download during off-peak hours** when possible
- **Log download activity** for troubleshooting

### Don't

- **Don't block the main thread** with synchronous downloads of large files
- **Don't ignore errors** - always handle failure cases
- **Don't download unnecessary content** - check if files are already cached
- **Don't hardcode URLs** - use configuration files for flexibility
- **Don't disable certificate verification** in production

---

## Troubleshooting

### Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "Network unreachable" | No network connection | Check Ethernet/WiFi, verify DHCP |
| "Timeout" | Server slow or unreachable | Increase timeout, check firewall |
| "Certificate error" | Invalid or expired SSL cert | Update CA certificates, check server |
| "404 Not Found" | File doesn't exist | Verify URL, check server configuration |
| Corrupt downloads | Network instability | Add checksum validation, retry |

### Diagnostic Tools

Use network diagnostics endpoints to verify connectivity:

```brightscript
Sub TestNetworkConnectivity()
    urlTransfer = CreateObject("roUrlTransfer")

    ' Test BrightSign network diagnostic endpoint
    urlTransfer.SetUrl("http://services.brightsignnetwork.com/bs/networkdiagnostic.ashx")
    response = urlTransfer.GetToString()

    if response = "BrightSign Network" then
        print "Network connectivity: OK"
    else
        print "Network connectivity: FAILED"
    end if
End Sub
```

---

## Exercises

1. **Basic Download**: Create a script that downloads an image from a URL and displays it using `roImagePlayer`

2. **Cached Playlist**: Build a system that downloads a JSON playlist, caches it locally, and falls back to the cache when offline

3. **Progress Display**: Create an HTML5 download manager that shows progress bars for multiple concurrent downloads

4. **Content Validator**: Implement a complete content sync system with MD5 validation and automatic retry for failed downloads

---

## Next Steps

- [Integrating with REST APIs](09-integrating-rest-apis.md) - Consume external APIs in your applications
- [Setting Up BSN.cloud](10-setting-up-bsn-cloud.md) - Connect players to BrightSign's cloud platform
- [Implementing Live Data Feeds](11-implementing-live-data-feeds.md) - Display real-time information

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
