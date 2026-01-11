# Performance Optimization

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers optimizing BrightSign applications for smooth, reliable performance. While BrightSign players are purpose-built for digital signage, understanding resource constraints and optimization techniques ensures your content plays flawlessly in production deployments.

### What You'll Learn

- Memory management best practices
- Video playback optimization
- HTML5/Chromium performance tuning
- JavaScript and BrightScript optimization
- Resource loading strategies
- Design patterns for performance
- Profiling and benchmarking techniques

### Performance Goals

| Metric | Target | Critical |
|--------|--------|----------|
| **Video FPS** | 30/60fps sustained | <20fps visible stutter |
| **Memory Usage** | <80% capacity | >90% risk of crash |
| **Boot Time** | <30 seconds | >60s poor UX |
| **UI Response** | <100ms | >300ms feels laggy |
| **Content Load** | <3 seconds | >10s unacceptable |

---

## Prerequisites

- Deployed BrightSign application
- Understanding of player architecture
- Access to player for testing
- Profiling tools (Chrome DevTools for HTML5)
- Development environment set up ([see setup guide](01-setting-up-development-environment.md))

---

## Part 1: Memory Management

### Critical Memory Issue: Video Elements

**The number one cause of memory issues:** Not releasing video elements properly.

**Problem:**

```brightscript
' WRONG: Old video still using memory
videoPlayer.PlayFile("video1.mp4")
sleep(10000)
videoPlayer.PlayFile("video2.mp4")  ' video1 still in memory!
```

**Solution:**

```brightscript
' CORRECT: Release video before playing new one
videoPlayer.Stop()
videoPlayer.SetUrl("")  ' CRITICAL: Frees memory
videoPlayer.PlayFile("video2.mp4")
```

**Complete video cleanup:**

```brightscript
Function CleanupVideoPlayer(player as Object) as Void
    ' Stop playback
    player.Stop()

    ' Reset source to free memory
    player.SetUrl("")

    ' Clear any pending events
    player.SetPort(invalid)

    ' Invalidate object
    player = invalid
End Function

' Usage
CleanupVideoPlayer(videoPlayer)
videoPlayer = CreateObject("roVideoPlayer")
```

### Image Memory Management

**Images are NOT automatically resized:**

```html
<!-- WRONG: 4K image in 200px container -->
<img src="4096x2160.jpg" style="width: 200px;">
<!-- Consumes full 4K memory! -->

<!-- CORRECT: Pre-resize images -->
<img src="thumbnail-200x112.jpg" style="width: 200px;">
```

**Image optimization checklist:**
- Resize images to display size before deployment
- Use appropriate compression (JPEG 80-90% quality)
- Convert to WebP for better compression
- Lazy load images below the fold
- Unload images no longer visible

### JavaScript Memory Leaks

**Common leak: Event listeners:**

```javascript
// WRONG: Leaks memory
function setupButton() {
    const button = document.getElementById('btn');
    button.addEventListener('click', () => {
        // Handler keeps reference to button
    });
}

// Call repeatedly
setInterval(setupButton, 1000);  // Creates new listener each time!

// CORRECT: Remove old listeners
let currentButton = null;

function setupButton() {
    if (currentButton) {
        currentButton.removeEventListener('click', handleClick);
    }

    currentButton = document.getElementById('btn');
    currentButton.addEventListener('click', handleClick);
}

function handleClick(event) {
    // Handle click
}
```

**Monitor memory usage:**

```javascript
// Log memory every minute
setInterval(() => {
    const usage = process.memoryUsage();

    console.log('Memory:', {
        rss: `${Math.round(usage.rss / 1024 / 1024)}MB`,
        heapUsed: `${Math.round(usage.heapUsed / 1024 / 1024)}MB`,
        heapTotal: `${Math.round(usage.heapTotal / 1024 / 1024)}MB`,
        external: `${Math.round(usage.external / 1024 / 1024)}MB`
    });

    // Alert if memory exceeds threshold
    if (usage.heapUsed > 300 * 1024 * 1024) {  // 300MB
        console.warn('HIGH MEMORY USAGE!');
    }
}, 60000);
```

---

## Part 2: Video Playback Optimization

### Use Hardware Acceleration (HWZ)

**Always use HWZ for hardware decoding:**

```html
<!-- CORRECT: Hardware-accelerated -->
<video hwz src="video.mp4" autoplay></video>

<!-- WRONG: Software decoding (CPU intensive) -->
<video src="video.mp4" autoplay></video>
```

**BrightScript automatically uses hardware:**

```brightscript
' Hardware decoding by default
videoPlayer = CreateObject("roVideoPlayer")
videoPlayer.PlayFile("video.mp4")
```

### Codec Selection

**Recommended codecs:**

| Codec | Container | Use Case | Player Support |
|-------|-----------|----------|----------------|
| **H.264** | MP4, TS | Universal, efficient | All players |
| **H.265** | MP4, TS | 4K content, lower bitrate | Series 4+ |
| **VP9** | WebM | Web video | Series 5+ (limited) |

**Encoding guidelines:**
- **1080p:** H.264, 5-10 Mbps, High profile
- **4K:** H.265, 15-25 Mbps, Main profile
- **Frame rate:** Match display (30 or 60fps)
- **Keyframe interval:** 2 seconds (60 frames @ 30fps)

### Multi-Zone Video Coordination

**Synchronize zones to reduce memory:**

```brightscript
Sub CreateMultiZoneLayout()
    ' Video zone 1 (main)
    rect1 = CreateObject("roRectangle", 0, 0, 1280, 1080)
    videoPlayer1 = CreateObject("roVideoPlayer")
    videoPlayer1.SetRectangle(rect1)

    ' Video zone 2 (sidebar)
    rect2 = CreateObject("roRectangle", 1280, 0, 640, 1080)
    videoPlayer2 = CreateObject("roVideoPlayer")
    videoPlayer2.SetRectangle(rect2)

    ' IMPORTANT: Stagger start times to reduce peak memory
    videoPlayer1.PlayFile("main.mp4")
    sleep(500)  ' Brief delay
    videoPlayer2.PlayFile("sidebar.mp4")
End Sub
```

---

## Part 3: HTML5/Chromium Optimization

### DOM Manipulation Efficiency

**Minimize reflows and repaints:**

```javascript
// WRONG: Multiple reflows
for (let i = 0; i < 100; i++) {
    const div = document.createElement('div');
    div.textContent = `Item ${i}`;
    document.body.appendChild(div);  // Reflow on each append!
}

// CORRECT: Single reflow
const fragment = document.createDocumentFragment();
for (let i = 0; i < 100; i++) {
    const div = document.createElement('div');
    div.textContent = `Item ${i}`;
    fragment.appendChild(div);
}
document.body.appendChild(fragment);  // Single reflow
```

### CSS Animations vs JavaScript

**Prefer CSS for animations:**

```css
/* CORRECT: Hardware-accelerated */
.slide {
    transform: translateX(0);
    transition: transform 0.3s ease;
}

.slide.active {
    transform: translateX(100px);
}
```

```javascript
// WRONG: JavaScript animation (CPU intensive)
let pos = 0;
function animate() {
    pos += 1;
    element.style.left = pos + 'px';
    if (pos < 100) requestAnimationFrame(animate);
}
```

**Use transform and opacity for best performance:**

```css
/* FAST: Composited properties */
.fast-animation {
    transform: translateX(100px) scale(1.2);
    opacity: 0.5;
}

/* SLOW: Layout/paint properties */
.slow-animation {
    left: 100px;
    width: 120%;
    background-color: red;
}
```

### Debouncing and Throttling

**Throttle high-frequency events:**

```javascript
// Throttle: Execute at most once per interval
function throttle(func, delay) {
    let lastCall = 0;

    return function(...args) {
        const now = Date.now();

        if (now - lastCall >= delay) {
            lastCall = now;
            func.apply(this, args);
        }
    };
}

// Usage: Limit scroll handler
window.addEventListener('scroll', throttle(() => {
    updateScrollPosition();
}, 100));  // Max once per 100ms

// Debounce: Execute after silence period
function debounce(func, delay) {
    let timeout;

    return function(...args) {
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(this, args), delay);
    };
}

// Usage: Search input
searchInput.addEventListener('input', debounce(() => {
    performSearch(searchInput.value);
}, 300));  // Wait 300ms after typing stops
```

---

## Part 4: BrightScript Optimization

### Array Performance

**Associative arrays (AA) vs indexed arrays:**

```brightscript
' FAST: Associative array lookup O(1)
lookup = {
    "item1": "value1",
    "item2": "value2",
    "item3": "value3"
}
value = lookup["item2"]  ' O(1)

' SLOW: Array search O(n)
items = ["item1", "item2", "item3"]
for each item in items
    if item = "item2" then
        ' Found
        exit for
    end if
end for
```

### String Concatenation

**Use array join for many concatenations:**

```brightscript
' WRONG: O(n²) complexity
result = ""
for i = 1 to 1000
    result = result + "item" + Str(i) + ","  ' Creates new string each time
end for

' CORRECT: O(n) complexity
parts = []
for i = 1 to 1000
    parts.Push("item" + Str(i))
end for
result = parts.Join(",")
```

### Object Pooling

**Reuse objects instead of creating new ones:**

```brightscript
' Object pool for frequent allocations
Function CreateObjectPool(objectType as String, size as Integer) as Object
    pool = {
        objects: [],
        available: [],
        type: objectType
    }

    ' Pre-allocate objects
    for i = 1 to size
        obj = CreateObject(objectType)
        pool.objects.Push(obj)
        pool.available.Push(i - 1)
    end for

    pool.acquire = Function() as Object
        if m.available.Count() > 0 then
            index = m.available.Pop()
            return m.objects[index]
        else
            ' Pool exhausted, create new
            obj = CreateObject(m.type)
            m.objects.Push(obj)
            return obj
        end if
    End Function

    pool.release = Function(obj as Object) as Void
        ' Find object index and mark available
        for i = 0 to m.objects.Count() - 1
            if m.objects[i] = obj then
                m.available.Push(i)
                exit for
            end if
        end for
    End Function

    return pool
End Function

' Usage
byteArrayPool = CreateObjectPool("roByteArray", 10)

' Acquire from pool
buffer = byteArrayPool.acquire()
' Use buffer...
' Release back to pool
byteArrayPool.release(buffer)
```

---

## Part 5: Resource Loading Strategies

### Lazy Loading

**Load resources only when needed:**

```javascript
// Lazy load images
const images = document.querySelectorAll('img[data-src]');

const imageObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const img = entry.target;
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
            imageObserver.unobserve(img);
        }
    });
});

images.forEach(img => imageObserver.observe(img));
```

### Preloading Critical Content

**Preload next content while current plays:**

```brightscript
Sub PreloadNextVideo(videoPlayer as Object, nextVideo as String)
    ' Start preloading while current video plays
    videoPlayer.PreloadFile(nextVideo)
    print "Preloading: "; nextVideo
End Sub

Sub PlayVideoSequence(playlist as Object)
    videoPlayer = CreateObject("roVideoPlayer")
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    currentIndex = 0
    videoPlayer.PlayFile(playlist[currentIndex])

    ' Preload next
    if playlist.Count() > 1 then
        PreloadNextVideo(videoPlayer, playlist[1])
    end if

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            if msg.GetInt() = 8 then  ' Video ended
                currentIndex = currentIndex + 1

                if currentIndex < playlist.Count() then
                    videoPlayer.PlayFile(playlist[currentIndex])

                    ' Preload next
                    if currentIndex + 1 < playlist.Count() then
                        PreloadNextVideo(videoPlayer, playlist[currentIndex + 1])
                    end if
                else
                    ' Playlist complete
                    exit while
                end if
            end if
        end if
    end while
End Sub
```

### Content Caching

**Cache API responses:**

```javascript
class CacheManager {
    constructor(maxAge = 3600000) {  // 1 hour default
        this.cache = new Map();
        this.maxAge = maxAge;
    }

    get(key) {
        const cached = this.cache.get(key);

        if (!cached) return null;

        // Check expiry
        if (Date.now() - cached.timestamp > this.maxAge) {
            this.cache.delete(key);
            return null;
        }

        return cached.data;
    }

    set(key, data) {
        this.cache.set(key, {
            data: data,
            timestamp: Date.now()
        });
    }

    clear() {
        this.cache.clear();
    }
}

// Usage
const cache = new CacheManager(600000);  // 10 minutes

async function fetchWithCache(url) {
    // Check cache first
    const cached = cache.get(url);
    if (cached) {
        console.log('Cache hit:', url);
        return cached;
    }

    // Fetch from network
    const response = await fetch(url);
    const data = await response.json();

    // Store in cache
    cache.set(url, data);

    return data;
}
```

---

## Part 6: Design Patterns for Performance

### Singleton Pattern (Resource Management)

```brightscript
Function GetVideoPlayerManager() as Object
    ' Singleton instance stored in global
    if m.global = invalid then m.global = {}

    if m.global.videoPlayerManager = invalid then
        m.global.videoPlayerManager = CreateVideoPlayerManager()
    end if

    return m.global.videoPlayerManager
End Function

Function CreateVideoPlayerManager() as Object
    manager = {
        players: []
    }

    manager.getPlayer = Function() as Object
        ' Reuse existing player if available
        for each player in m.players
            if not player.isPlaying then
                return player
            end if
        end for

        ' Create new player
        player = CreateObject("roVideoPlayer")
        player.isPlaying = false
        m.players.Push(player)

        return player
    End Function

    return manager
End Function
```

### Event Delegation (Reduce Listeners)

```javascript
// WRONG: Many event listeners
document.querySelectorAll('.button').forEach(button => {
    button.addEventListener('click', handleClick);
});

// CORRECT: Single delegated listener
document.getElementById('container').addEventListener('click', (event) => {
    if (event.target.classList.contains('button')) {
        handleClick(event);
    }
});
```

---

## Part 7: Profiling and Benchmarking

### JavaScript Performance Timing

```javascript
// Measure operation time
console.time('loadContent');
await loadContent();
console.timeEnd('loadContent');

// Performance API
const start = performance.now();
await complexOperation();
const end = performance.now();
console.log(`Operation took ${end - start}ms`);

// Mark and measure
performance.mark('start-render');
renderContent();
performance.mark('end-render');
performance.measure('render-time', 'start-render', 'end-render');

const measure = performance.getEntriesByName('render-time')[0];
console.log(`Render time: ${measure.duration}ms`);
```

### FPS Monitoring

```javascript
class FPSMonitor {
    constructor() {
        this.frames = 0;
        this.lastTime = performance.now();
        this.fps = 0;
    }

    update() {
        this.frames++;

        const now = performance.now();
        const delta = now - this.lastTime;

        if (delta >= 1000) {
            this.fps = Math.round(this.frames / (delta / 1000));
            console.log(`FPS: ${this.fps}`);

            this.frames = 0;
            this.lastTime = now;

            if (this.fps < 20) {
                console.warn('LOW FPS DETECTED!');
            }
        }

        requestAnimationFrame(() => this.update());
    }

    start() {
        this.update();
    }
}

// Usage
const fpsMonitor = new FPSMonitor();
fpsMonitor.start();
```

### BrightScript Performance Measurement

```brightscript
Function MeasurePerformance(label as String, operation as Function) as Integer
    startTime = CreateObject("roTimespan")
    startTime.Mark()

    ' Execute operation
    operation()

    elapsed = startTime.TotalMilliseconds()
    print label; " took "; elapsed; "ms"

    return elapsed
End Function

' Usage
MeasurePerformance("Video load", Function() as Void
    videoPlayer.PlayFile("video.mp4")
End Function)
```

---

## Complete Example: Optimized Multi-Zone Player

```brightscript
Sub Main()
    ' Set video mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Create message port
    msgPort = CreateObject("roMessagePort")

    ' Main video zone
    mainRect = CreateObject("roRectangle", 0, 0, 1280, 1080)
    mainPlayer = CreateObject("roVideoPlayer")
    mainPlayer.SetRectangle(mainRect)
    mainPlayer.SetPort(msgPort)

    ' Sidebar zone
    sideRect = CreateObject("roRectangle", 1280, 0, 640, 1080)
    sidePlayer = CreateObject("roVideoPlayer")
    sidePlayer.SetRectangle(sideRect)
    sidePlayer.SetPort(msgPort)

    ' Playlists
    mainPlaylist = ["main1.mp4", "main2.mp4", "main3.mp4"]
    sidePlaylist = ["side1.mp4", "side2.mp4"]

    mainIndex = 0
    sideIndex = 0

    ' Start first videos
    mainPlayer.PlayFile(mainPlaylist[mainIndex])

    ' Stagger start to reduce peak memory
    sleep(500)
    sidePlayer.PlayFile(sidePlaylist[sideIndex])

    ' Preload next videos
    if mainIndex + 1 < mainPlaylist.Count() then
        mainPlayer.PreloadFile(mainPlaylist[mainIndex + 1])
    end if
    if sideIndex + 1 < sidePlaylist.Count() then
        sidePlayer.PreloadFile(sidePlaylist[sideIndex + 1])
    end if

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            player = msg.GetSourceIdentity()
            eventCode = msg.GetInt()

            if eventCode = 8 then  ' Video ended
                ' Determine which player
                if player = mainPlayer.GetIdentity() then
                    ' Cleanup
                    mainPlayer.SetUrl("")

                    ' Next video
                    mainIndex = (mainIndex + 1) mod mainPlaylist.Count()
                    mainPlayer.PlayFile(mainPlaylist[mainIndex])

                    ' Preload next
                    nextIndex = (mainIndex + 1) mod mainPlaylist.Count()
                    mainPlayer.PreloadFile(mainPlaylist[nextIndex])

                else if player = sidePlayer.GetIdentity() then
                    ' Cleanup
                    sidePlayer.SetUrl("")

                    ' Next video
                    sideIndex = (sideIndex + 1) mod sidePlaylist.Count()
                    sidePlayer.PlayFile(sidePlaylist[sideIndex])

                    ' Preload next
                    nextIndex = (sideIndex + 1) mod sidePlaylist.Count()
                    sidePlayer.PreloadFile(sidePlaylist[nextIndex])
                end if
            end if
        end if
    end while
End Sub
```

---

## Performance Checklist

### Pre-Deployment

- [ ] Video elements properly cleaned up (SetUrl(""))
- [ ] Images resized to display dimensions
- [ ] Hardware acceleration enabled (HWZ)
- [ ] Event listeners removed when not needed
- [ ] Memory usage monitored and under threshold
- [ ] Lazy loading implemented for off-screen content
- [ ] Critical content preloaded
- [ ] CSS animations used instead of JavaScript
- [ ] Network requests cached appropriately
- [ ] FPS maintained above 20fps minimum

### Post-Deployment Monitoring

- [ ] Memory usage tracked over time
- [ ] FPS monitored continuously
- [ ] Load times measured
- [ ] Error rates tracked
- [ ] Reboot frequency analyzed

---

## Best Practices

### Do

- **Profile before optimizing** - Measure first
- **Clean up video elements** - SetUrl("") after use
- **Resize images** - Match display size
- **Use hardware acceleration** - HWZ attribute
- **Implement lazy loading** - Load on demand
- **Cache API responses** - Reduce network calls
- **Monitor memory** - Log usage regularly
- **Test on target hardware** - Not just development machine

### Don't

- **Don't premature optimize** - Profile first
- **Don't ignore memory warnings** - Address immediately
- **Don't use software decoding** - Always use HWZ
- **Don't create unnecessary objects** - Reuse when possible
- **Don't block UI thread** - Use async operations
- **Don't forget cleanup** - Release resources

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Player reboots | Out of memory | Clean up video elements, resize images |
| Low FPS | CPU overload | Use CSS animations, hardware acceleration |
| Slow load times | Large assets | Optimize images, lazy load |
| Memory leak | Event listeners | Remove listeners, use delegation |
| Stuttering video | Wrong codec | Use H.264, check bitrate |

---

## Exercises

1. **Memory Audit**: Profile application and identify memory leaks

2. **FPS Monitor**: Implement FPS tracking and alert on low performance

3. **Image Optimizer**: Build script to resize images to display dimensions

4. **Cache Manager**: Implement smart caching for API responses

5. **Performance Dashboard**: Create monitoring dashboard showing key metrics

---

## Next Steps

- [Debugging Production Issues](17-debugging-production-issues.md) - Diagnose performance problems
- [Secure Deployment Practices](19-secure-deployment-practices.md) - Optimize securely
- [Building Custom Extensions](16-building-custom-extensions.md) - Performance-critical extensions

---

## Additional Resources

- [Technical Best Practices](https://docs.brightsign.biz/partners/technical-best-practices)
- Chrome DevTools Performance Profiling
- Web Performance Working Group: w3.org/webperf

---

<div align="center">

<img src="../documentation/part-7-assets/brand/brightsign-logo-square.png" alt="BrightSign" width="60">

**Brought to Life by BrightSign**

</div>
