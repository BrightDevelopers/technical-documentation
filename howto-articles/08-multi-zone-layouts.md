# Multi-Zone Layouts

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers creating complex screen layouts with multiple content zones displaying video, images, HTML, text, and other content simultaneously.

### Zone Capabilities

| Zone Type | Object | Content |
|-----------|--------|---------|
| Video | `roVideoPlayer` | Video files, streams |
| Image | `roImagePlayer` | Static images |
| HTML | `roHtmlWidget` | Web content, interactive UI |
| Text | `roTextField` | Static or scrolling text |
| Clock | `roClockWidget` | Time display |
| Canvas | `roCanvasWidget` | Custom graphics |

### Zone Limits by Player

| Series | Max Video Zones | Max Total Zones |
|--------|-----------------|-----------------|
| Series 5 | 2-4 (model dependent) | Many |
| Series 4 | 2 | Many |
| LS Series | 1 | Limited |

---

## Enabling Zone Support

Zone support is enabled by default in firmware 6.0 and later.

```brightscript
' For older firmware, enable explicitly
EnableZoneSupport(true)
```

---

## Basic Two-Zone Layout

### Video + Image Sidebar

```brightscript
Sub Main()
    ' Video zone (left 75%)
    videoRect = CreateObject("roRectangle", 0, 0, 1440, 1080)
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetRectangle(videoRect)
    videoPlayer.SetLoopMode(true)

    ' Image zone (right 25%)
    imageRect = CreateObject("roRectangle", 1440, 0, 480, 1080)
    imagePlayer = CreateObject("roImagePlayer")
    imagePlayer.SetRectangle(imageRect)

    ' Start content
    videoPlayer.PlayFile("main_content.mp4")
    imagePlayer.DisplayFile("sidebar.jpg")

    ' Event loop
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    while true
        msg = wait(0, msgPort)
    end while
End Sub
```

### Video + HTML Ticker

```brightscript
Sub Main()
    msgPort = CreateObject("roMessagePort")

    ' Video zone (main area)
    videoRect = CreateObject("roRectangle", 0, 0, 1920, 880)
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetRectangle(videoRect)
    videoPlayer.SetPort(msgPort)
    videoPlayer.SetLoopMode(true)

    ' HTML ticker zone (bottom strip)
    tickerRect = CreateObject("roRectangle", 0, 880, 1920, 200)
    tickerConfig = {
        url: "file:///sd:/ticker.html",
        mouse_enabled: false
    }
    tickerWidget = CreateObject("roHtmlWidget", tickerRect, tickerConfig)

    ' Start content
    videoPlayer.PlayFile("content.mp4")
    tickerWidget.Show()

    while true
        msg = wait(0, msgPort)
    end while
End Sub
```

---

## Common Layout Templates

### L-Bar Layout

Classic broadcast-style layout with main content and L-shaped information bar.

```brightscript
Sub LBarLayout()
    msgPort = CreateObject("roMessagePort")

    ' Main video (top-left)
    mainRect = CreateObject("roRectangle", 0, 0, 1440, 810)
    mainVideo = CreateObject("roVideoPlayer")
    mainVideo.SetRectangle(mainRect)
    mainVideo.SetPort(msgPort)
    mainVideo.SetLoopMode(true)

    ' Right sidebar
    sidebarRect = CreateObject("roRectangle", 1440, 0, 480, 1080)
    sidebar = CreateObject("roHtmlWidget", sidebarRect, {
        url: "file:///sd:/sidebar.html"
    })

    ' Bottom bar
    bottomRect = CreateObject("roRectangle", 0, 810, 1440, 270)
    bottomBar = CreateObject("roHtmlWidget", bottomRect, {
        url: "file:///sd:/bottom-bar.html"
    })

    ' Start content
    mainVideo.PlayFile("main.mp4")
    sidebar.Show()
    bottomBar.Show()

    while true
        msg = wait(0, msgPort)
    end while
End Sub
```

### Menu Board (3-Column)

```brightscript
Sub MenuBoardLayout()
    ' Column 1
    col1Rect = CreateObject("roRectangle", 0, 0, 640, 1080)
    col1 = CreateObject("roHtmlWidget", col1Rect, {
        url: "file:///sd:/menu-column1.html"
    })

    ' Column 2
    col2Rect = CreateObject("roRectangle", 640, 0, 640, 1080)
    col2 = CreateObject("roHtmlWidget", col2Rect, {
        url: "file:///sd:/menu-column2.html"
    })

    ' Column 3
    col3Rect = CreateObject("roRectangle", 1280, 0, 640, 1080)
    col3 = CreateObject("roHtmlWidget", col3Rect, {
        url: "file:///sd:/menu-column3.html"
    })

    ' Show all columns
    col1.Show()
    col2.Show()
    col3.Show()

    ' Keep running
    msgPort = CreateObject("roMessagePort")
    while true
        msg = wait(0, msgPort)
    end while
End Sub
```

### Picture-in-Picture

```brightscript
Sub PictureInPicture()
    msgPort = CreateObject("roMessagePort")

    ' Main video (full screen)
    mainRect = CreateObject("roRectangle", 0, 0, 1920, 1080)
    mainVideo = CreateObject("roVideoPlayer")
    mainVideo.SetRectangle(mainRect)
    mainVideo.SetPort(msgPort)
    mainVideo.SetLoopMode(true)

    ' PIP video (corner - 360x202 at 16:9)
    pipRect = CreateObject("roRectangle", 1520, 40, 360, 202)
    pipVideo = CreateObject("roVideoPlayer")
    pipVideo.SetRectangle(pipRect)
    pipVideo.SetPort(msgPort)
    pipVideo.SetLoopMode(true)

    ' Set z-order (PIP in front)
    mainVideo.ToBack()
    pipVideo.ToFront()

    ' Start both videos
    mainVideo.PlayFile("main_content.mp4")
    pipVideo.PlayFile("pip_content.mp4")

    while true
        msg = wait(0, msgPort)
    end while
End Sub
```

---

## Z-Order Control

Manage layering of zones.

### Graphics Z-Order

```brightscript
videoMode = CreateObject("roVideoMode")

' Place graphics layer in front of all video
videoMode.SetGraphicsZOrder("front")

' Place graphics between two video layers
videoMode.SetGraphicsZOrder("middle")

' Place graphics behind all video
videoMode.SetGraphicsZOrder("back")
```

### Video Z-Order

```brightscript
' Bring video to front
videoPlayer.ToFront()

' Send video to back
videoPlayer.ToBack()
```

### Zone Visibility

```brightscript
' Hide zone
videoPlayer.Hide()
htmlWidget.Hide()
imagePlayer.StopDisplay()

' Show zone
videoPlayer.Show()
htmlWidget.Show()
imagePlayer.DisplayFile("image.jpg")
```

---

## HTML-Based Layouts

Use HTML/CSS for flexible layouts:

### Grid Layout

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            width: 1920px;
            height: 1080px;
            display: grid;
            grid-template-columns: 3fr 1fr;
            grid-template-rows: auto 1fr auto;
            background: #1a1a2e;
            color: white;
            font-family: sans-serif;
        }

        .header {
            grid-column: 1 / -1;
            background: #16213e;
            padding: 20px 40px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .main-content {
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .main-content video {
            max-width: 100%;
            max-height: 100%;
        }

        .sidebar {
            background: #0f3460;
            padding: 20px;
        }

        .footer {
            grid-column: 1 / -1;
            background: #16213e;
            padding: 15px 40px;
        }

        .ticker {
            white-space: nowrap;
            animation: scroll 30s linear infinite;
        }

        @keyframes scroll {
            from { transform: translateX(100%); }
            to { transform: translateX(-100%); }
        }
    </style>
</head>
<body>
    <header class="header">
        <img src="logo.png" alt="Logo" height="60">
        <div id="clock"></div>
    </header>

    <main class="main-content">
        <video src="content.mp4" hwz="z-index:-1" autoplay loop></video>
    </main>

    <aside class="sidebar">
        <h2>Updates</h2>
        <div id="feed"></div>
    </aside>

    <footer class="footer">
        <div class="ticker" id="ticker">
            Breaking news and updates scroll here...
        </div>
    </footer>

    <script>
        // Update clock
        function updateClock() {
            const now = new Date();
            document.getElementById('clock').textContent =
                now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
        }
        setInterval(updateClock, 1000);
        updateClock();
    </script>
</body>
</html>
```

### Flexbox Layout

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            width: 1920px;
            height: 1080px;
            margin: 0;
            display: flex;
            flex-direction: column;
            background: #000;
        }

        .top-row {
            flex: 3;
            display: flex;
        }

        .main-video {
            flex: 3;
            position: relative;
        }

        .main-video video {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .info-panel {
            flex: 1;
            background: #1e3a5f;
            padding: 30px;
            color: white;
        }

        .bottom-bar {
            flex: 1;
            background: #0d2137;
            display: flex;
            align-items: center;
            padding: 0 40px;
            color: white;
        }
    </style>
</head>
<body>
    <div class="top-row">
        <div class="main-video">
            <video src="video.mp4" hwz="z-index:-1" autoplay loop></video>
        </div>
        <div class="info-panel">
            <h2>Information</h2>
            <p>Content here...</p>
        </div>
    </div>
    <div class="bottom-bar">
        <marquee>Scrolling message ticker...</marquee>
    </div>
</body>
</html>
```

---

## Mosaic Mode (Multiple Videos)

Display multiple video streams using a single decoder in mosaic mode.

### 2x2 Video Grid

```brightscript
Sub VideoMosaic()
    msgPort = CreateObject("roMessagePort")

    ' Configure decoder for mosaic mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")
    videoMode.SetDecoderMode("mosaic", "4k")

    ' Create 4 video players in a 2x2 grid
    video1 = CreateObject("roVideoPlayer")
    video1.SetRectangle(CreateObject("roRectangle", 0, 0, 960, 540))
    video1.SetPort(msgPort)
    video1.SetLoopMode(true)

    video2 = CreateObject("roVideoPlayer")
    video2.SetRectangle(CreateObject("roRectangle", 960, 0, 960, 540))
    video2.SetPort(msgPort)
    video2.SetLoopMode(true)

    video3 = CreateObject("roVideoPlayer")
    video3.SetRectangle(CreateObject("roRectangle", 0, 540, 960, 540))
    video3.SetPort(msgPort)
    video3.SetLoopMode(true)

    video4 = CreateObject("roVideoPlayer")
    video4.SetRectangle(CreateObject("roRectangle", 960, 540, 960, 540))
    video4.SetPort(msgPort)
    video4.SetLoopMode(true)

    ' Start all videos
    video1.PlayFile("stream1.ts")
    video2.PlayFile("stream2.ts")
    video3.PlayFile("stream3.ts")
    video4.PlayFile("stream4.ts")

    while true
        msg = wait(0, msgPort)
    end while
End Sub
```

---

## Video Wall Configuration

Configure for multi-screen video wall displays.

### Single Player in Video Wall

```brightscript
Sub VideoWallPlayer()
    videoPlayer = CreateObject("roVideoPlayer")
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)
    videoPlayer.SetLoopMode(true)

    ' Configure for 3x2 video wall
    ' This player is at position (0, 0) - top left
    params = {
        filename: "wall_content.mp4",
        MultiscreenWidth: 3,   ' 3 screens wide
        MultiscreenHeight: 2,  ' 2 screens tall
        MultiscreenX: 0,       ' X position (0, 1, or 2)
        MultiscreenY: 0        ' Y position (0 or 1)
    }

    videoPlayer.PlayFile(params)

    while true
        msg = wait(0, msgPort)
    end while
End Sub
```

### Configuration per Screen

| Position | MultiscreenX | MultiscreenY |
|----------|--------------|--------------|
| Top-left | 0 | 0 |
| Top-center | 1 | 0 |
| Top-right | 2 | 0 |
| Bottom-left | 0 | 1 |
| Bottom-center | 1 | 1 |
| Bottom-right | 2 | 1 |

---

## Dynamic Zone Management

### Zone Manager Class

```brightscript
Function CreateZoneManager() as Object
    return {
        zones: {},
        msgPort: CreateObject("roMessagePort"),

        AddVideoZone: Function(name as String, rect as Object) as Object
            player = CreateObject("roVideoPlayer")
            player.SetRectangle(rect)
            player.SetPort(m.msgPort)
            m.zones[name] = {type: "video", player: player, rect: rect}
            return player
        End Function,

        AddImageZone: Function(name as String, rect as Object) as Object
            player = CreateObject("roImagePlayer")
            player.SetRectangle(rect)
            m.zones[name] = {type: "image", player: player, rect: rect}
            return player
        End Function,

        AddHtmlZone: Function(name as String, rect as Object, url as String) as Object
            widget = CreateObject("roHtmlWidget", rect, {url: url})
            widget.SetPort(m.msgPort)
            m.zones[name] = {type: "html", player: widget, rect: rect}
            return widget
        End Function,

        ShowZone: Function(name as String)
            if m.zones[name] <> invalid then
                zone = m.zones[name]
                if zone.type = "html" then
                    zone.player.Show()
                end if
            end if
        End Function,

        HideZone: Function(name as String)
            if m.zones[name] <> invalid then
                zone = m.zones[name]
                if zone.type = "video" then
                    zone.player.Stop()
                    zone.player.Hide()
                else if zone.type = "image" then
                    zone.player.StopDisplay()
                else if zone.type = "html" then
                    zone.player.Hide()
                end if
            end if
        End Function,

        ResizeZone: Function(name as String, newRect as Object)
            if m.zones[name] <> invalid then
                zone = m.zones[name]
                zone.player.SetRectangle(newRect)
                zone.rect = newRect
            end if
        End Function,

        GetMessagePort: Function() as Object
            return m.msgPort
        End Function
    }
End Function

' Usage
Sub Main()
    zm = CreateZoneManager()

    ' Create zones
    mainVideo = zm.AddVideoZone("main", CreateObject("roRectangle", 0, 0, 1440, 810))
    sidebar = zm.AddHtmlZone("sidebar", CreateObject("roRectangle", 1440, 0, 480, 1080), "file:///sd:/sidebar.html")
    ticker = zm.AddHtmlZone("ticker", CreateObject("roRectangle", 0, 810, 1440, 270), "file:///sd:/ticker.html")

    ' Start content
    mainVideo.SetLoopMode(true)
    mainVideo.PlayFile("content.mp4")
    zm.ShowZone("sidebar")
    zm.ShowZone("ticker")

    ' Event loop
    while true
        msg = wait(0, zm.GetMessagePort())
    end while
End Sub
```

---

## Text Zones

### Simple Text Display

```brightscript
Sub TextZone()
    ' Create text field
    textRect = CreateObject("roRectangle", 50, 900, 800, 100)
    textField = CreateObject("roTextField", textRect)

    ' Configure appearance
    textField.SetForegroundColor(&hFFFFFF)  ' White text
    textField.SetBackgroundColor(&h000000AA)  ' Semi-transparent black
    textField.SetFont("FreeSans", 36, 0, 0)

    ' Display text
    textField.DisplayText("Welcome to our store!", 1)
    textField.Show()

    ' Keep running
    while true
        sleep(1000)
    end while
End Sub
```

### Scrolling Text Ticker

```brightscript
Sub ScrollingTicker()
    textRect = CreateObject("roRectangle", 0, 1000, 1920, 80)
    textField = CreateObject("roTextField", textRect)

    textField.SetForegroundColor(&hFFFFFF)
    textField.SetBackgroundColor(&h1a1a2e)
    textField.SetFont("FreeSans", 32, 0, 0)

    ' Enable scrolling
    message = "Breaking News: Important update coming soon! Stay tuned for more information. "
    ' Repeat message for continuous scroll
    scrollText = message + message + message

    textField.DisplayText(scrollText, 1)
    textField.Show()

    ' Note: For smooth scrolling, use HTML/CSS instead
End Sub
```

---

## Clock Widget

```brightscript
Sub ClockZone()
    clockRect = CreateObject("roRectangle", 1700, 20, 200, 60)
    clockWidget = CreateObject("roClockWidget", clockRect)

    ' Configure appearance
    clockWidget.SetForegroundColor(&hFFFFFF)
    clockWidget.SetBackgroundColor(&h00000000)  ' Transparent
    clockWidget.SetFont("FreeSans", 36, 0, 0)

    ' Set time format (strftime format)
    clockWidget.SetFormat("%H:%M:%S")  ' 24-hour with seconds
    ' clockWidget.SetFormat("%I:%M %p")  ' 12-hour with AM/PM

    clockWidget.Show()
End Sub
```

---

## Complete Example: Digital Signage Layout

```brightscript
' autorun.brs - Multi-Zone Digital Signage

Sub Main()
    app = CreateSignageApp()
    app.Run()
End Sub

Function CreateSignageApp() as Object
    return {
        videoPlayer: invalid,
        imagePlayer: invalid,
        tickerWidget: invalid,
        clockWidget: invalid,
        msgPort: invalid,
        imageTimer: invalid,
        images: [],
        currentImageIndex: 0,

        Run: Sub()
            m.Initialize()
            m.CreateZones()
            m.LoadContent()
            m.StartContent()
            m.EventLoop()
        End Sub,

        Initialize: Sub()
            m.msgPort = CreateObject("roMessagePort")

            ' Set video mode
            videoMode = CreateObject("roVideoMode")
            videoMode.SetMode("1920x1080x60p")

            ' Graphics in front of video
            videoMode.SetGraphicsZOrder("front")

            print "Signage app initialized"
        End Sub,

        CreateZones: Sub()
            ' Main video zone (left side, upper area)
            videoRect = CreateObject("roRectangle", 0, 0, 1440, 810)
            m.videoPlayer = CreateObject("roVideoPlayer")
            m.videoPlayer.SetRectangle(videoRect)
            m.videoPlayer.SetPort(m.msgPort)
            m.videoPlayer.SetLoopMode(true)

            ' Image slideshow zone (right sidebar)
            imageRect = CreateObject("roRectangle", 1440, 0, 480, 810)
            m.imagePlayer = CreateObject("roImagePlayer")
            m.imagePlayer.SetRectangle(imageRect)
            m.imagePlayer.SetDefaultMode(2)  ' Fill and crop
            m.imagePlayer.SetDefaultTransition(15)  ' Cross-fade
            m.imagePlayer.SetTransitionDuration(500)

            ' HTML ticker zone (bottom)
            tickerRect = CreateObject("roRectangle", 0, 810, 1920, 270)
            m.tickerWidget = CreateObject("roHtmlWidget", tickerRect, {
                url: "file:///sd:/ticker.html",
                mouse_enabled: false
            })
            m.tickerWidget.SetPort(m.msgPort)

            ' Clock widget (overlay on video)
            clockRect = CreateObject("roRectangle", 1300, 20, 120, 40)
            m.clockWidget = CreateObject("roClockWidget", clockRect)
            m.clockWidget.SetForegroundColor(&hFFFFFF)
            m.clockWidget.SetBackgroundColor(&h00000080)
            m.clockWidget.SetFont("FreeSans", 28, 0, 0)
            m.clockWidget.SetFormat("%H:%M")

            ' Image rotation timer
            m.imageTimer = CreateObject("roTimer")
            m.imageTimer.SetPort(m.msgPort)
            m.imageTimer.SetElapsed(8, 0)  ' 8 seconds per image

            print "Zones created"
        End Sub,

        LoadContent: Sub()
            ' Load images from /images folder
            files = ListDir("/images")
            for each file in files
                ext = LCase(Right(file, 4))
                if ext = ".jpg" or ext = ".png" then
                    m.images.Push("/images/" + file)
                end if
            end for
            m.images.Sort()

            print "Loaded "; m.images.Count(); " images"
        End Sub,

        StartContent: Sub()
            ' Start video
            m.videoPlayer.PlayFile("main_content.mp4")

            ' Start image slideshow
            if m.images.Count() > 0 then
                m.imagePlayer.PreloadFile(m.images[0])
                m.imagePlayer.DisplayPreload()

                if m.images.Count() > 1 then
                    m.imagePlayer.PreloadFile(m.images[1])
                end if

                m.imageTimer.Start()
            end if

            ' Show widgets
            m.tickerWidget.Show()
            m.clockWidget.Show()

            print "Content started"
        End Sub,

        AdvanceImage: Sub()
            ' Display preloaded image
            m.imagePlayer.DisplayPreload()

            ' Update index
            m.currentImageIndex = (m.currentImageIndex + 1) mod m.images.Count()

            ' Preload next image
            nextIndex = (m.currentImageIndex + 1) mod m.images.Count()
            m.imagePlayer.PreloadFile(m.images[nextIndex])

            ' Restart timer
            m.imageTimer.Start()
        End Sub,

        EventLoop: Sub()
            while true
                msg = wait(0, m.msgPort)

                if type(msg) = "roVideoEvent" then
                    if msg.GetInt() = 8 then  ' MediaEnded (shouldn't happen with loop)
                        m.videoPlayer.PlayFile("main_content.mp4")
                    else if msg.GetInt() = 15 then  ' Error
                        print "Video error: "; msg.GetData()
                    end if

                else if type(msg) = "roTimerEvent" then
                    if msg.GetSourceIdentity() = m.imageTimer.GetIdentity() then
                        m.AdvanceImage()
                    end if

                else if type(msg) = "roHtmlWidgetEvent" then
                    eventData = msg.GetData()
                    if eventData.reason = "load-error" then
                        print "HTML load error: "; eventData.message
                    end if
                end if
            end while
        End Sub
    }
End Function
```

### Ticker HTML (ticker.html)

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        * { margin: 0; padding: 0; }
        body {
            width: 1920px;
            height: 270px;
            background: linear-gradient(to bottom, #1a1a2e, #16213e);
            display: flex;
            flex-direction: column;
            justify-content: center;
            font-family: sans-serif;
            color: white;
            overflow: hidden;
        }
        .ticker-container {
            background: rgba(0,0,0,0.3);
            padding: 15px 0;
        }
        .ticker {
            display: flex;
            animation: scroll 40s linear infinite;
        }
        .ticker-item {
            white-space: nowrap;
            padding: 0 50px;
            font-size: 28px;
        }
        @keyframes scroll {
            from { transform: translateX(0); }
            to { transform: translateX(-50%); }
        }
        .info-bar {
            display: flex;
            justify-content: space-around;
            padding: 20px;
            font-size: 24px;
        }
    </style>
</head>
<body>
    <div class="ticker-container">
        <div class="ticker">
            <span class="ticker-item">Welcome to our digital signage display</span>
            <span class="ticker-item">Today's special offers available now</span>
            <span class="ticker-item">Follow us on social media @company</span>
            <span class="ticker-item">Welcome to our digital signage display</span>
            <span class="ticker-item">Today's special offers available now</span>
            <span class="ticker-item">Follow us on social media @company</span>
        </div>
    </div>
    <div class="info-bar">
        <span>Open Hours: 9 AM - 9 PM</span>
        <span>Customer Service: 1-800-EXAMPLE</span>
        <span>www.example.com</span>
    </div>
</body>
</html>
```

---

## Troubleshooting

### Zones Not Displaying

1. **Check zone support**: Ensure `EnableZoneSupport(true)` for older firmware
2. **Check rectangles**: Verify coordinates are within screen bounds
3. **Check z-order**: Use `ToFront()` / `ToBack()` as needed
4. **Check visibility**: Call `Show()` for HTML widgets

### Video Zones Overlapping

1. **Check rectangles**: Ensure no overlap unless intended
2. **Set z-order**: Use `SetGraphicsZOrder()` and `ToFront()`/`ToBack()`
3. **Check decoder limits**: Mosaic mode may be needed for multiple videos

### Performance Issues

1. **Reduce zone count**: Fewer zones = better performance
2. **Optimize HTML**: Use CSS transforms for animations
3. **Check video resolution**: Lower resolution for zones
4. **Use preloading**: Preload images for smooth transitions

### Memory Issues

1. **Limit HTML widgets**: Each widget uses memory
2. **Optimize images**: Match to zone size
3. **Avoid large DOM**: Keep HTML simple

---

## Next Steps

- [Playing Video Content](05-playing-video-content.md) - Detailed video playback
- [Creating an Image Slideshow](06-creating-image-slideshow.md) - Image transitions
- [Audio Playback and Control](07-audio-playback-control.md) - Add audio to layouts
- [roVideoMode Reference](https://docs.brightsign.biz/developers/rovideomode) - Complete API documentation

---

[← Previous: Audio Playback and Control](07-audio-playback-control.md) | [Back to How-To Articles](README.md)
