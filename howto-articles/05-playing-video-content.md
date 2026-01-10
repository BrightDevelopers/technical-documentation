# Playing Video Content

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers everything you need to know about video playback on BrightSign players, from basic file playback to streaming protocols, zones, and advanced features like keying and transforms.

### Video Playback Options

| Approach | Best For | Key Object |
|----------|----------|------------|
| **BrightScript** | Maximum control, hardware features | `roVideoPlayer` |
| **HTML5 Video** | Web developers, UI integration | `<video>` element |
| **HTML5 + HWZ** | Performance with HTML UI | `<video hwz>` attribute |

### Supported Formats

| Codec | Container | Notes |
|-------|-----------|-------|
| H.264 (AVC) | MP4, MOV, TS | Most common, all players |
| H.265 (HEVC) | MP4, MOV, TS | Series 4+, 4K capable |
| MPEG-2 | TS, VOB | Legacy content |
| VP9 | WebM | Series 5 |
| MJPEG | AVI | USB cameras |

---

## Basic Video Playback

### Minimal Example

```brightscript
Sub Main()
    ' Set video output mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Create video player
    videoPlayer = CreateObject("roVideoPlayer")

    ' Create message port for events
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    ' Play video file
    videoPlayer.PlayFile("video.mp4")

    ' Event loop - required to keep application running
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            eventCode = msg.GetInt()

            if eventCode = 8 then
                print "Video finished"
            end if
        end if
    end while
End Sub
```

### Video Events

Handle events to respond to playback state changes:

| Event Code | Name | Description |
|------------|------|-------------|
| 3 | Playing | Playback started |
| 8 | MediaEnded | File finished playing |
| 12 | TimeHit | Timecode from AddEvent() reached |
| 13 | Timecode | Position update (if enabled) |
| 14 | Paused | Playback paused |
| 15 | PlaybackFailure | Error occurred |

```brightscript
while true
    msg = wait(0, msgPort)

    if type(msg) = "roVideoEvent" then
        eventCode = msg.GetInt()

        if eventCode = 3 then
            print "Video started playing"

        else if eventCode = 8 then
            print "Video ended"
            ' Play next video or loop
            videoPlayer.PlayFile("video.mp4")

        else if eventCode = 14 then
            print "Video paused"

        else if eventCode = 15 then
            errorInfo = msg.GetData()
            print "Playback error: "; errorInfo
        end if
    end if
end while
```

---

## Playback Controls

### Basic Controls

```brightscript
' Start playback
videoPlayer.PlayFile("video.mp4")

' Pause and resume
videoPlayer.Pause()
videoPlayer.Resume()

' Stop playback
videoPlayer.Stop()
```

### Seeking

Seeking works with MP4 and MOV containers:

```brightscript
' Seek to position in milliseconds
videoPlayer.Seek(30000)  ' Jump to 30 seconds

' Get current position
position = videoPlayer.GetPlaybackPosition()
print "Current position: "; position; "ms"

' Get total duration
duration = videoPlayer.GetDuration()
print "Duration: "; duration; "ms"
```

### Playback Speed

```brightscript
' Normal speed
videoPlayer.SetPlaybackSpeed(1.0)

' Fast forward (2x)
videoPlayer.SetPlaybackSpeed(2.0)

' Slow motion (half speed)
videoPlayer.SetPlaybackSpeed(0.5)

' Rewind
videoPlayer.SetPlaybackSpeed(-1.0)
```

### Volume Control

```brightscript
' Set volume (0-100)
videoPlayer.SetVolume(75)

' Mute
videoPlayer.SetVolume(0)

' Set volume in decibels
videoPlayer.SetVolume({db: -6})
```

---

## Looping

### Loop Modes

```brightscript
' Always loop
videoPlayer.SetLoopMode(true)

' Never loop
videoPlayer.SetLoopMode(false)

' Loop mode options (string values)
videoPlayer.SetLoopMode("alwaysloop")           ' Always loop
videoPlayer.SetLoopMode("noloop")               ' Never loop
videoPlayer.SetLoopMode("seamlessloopornotatall") ' Seamless or don't play
videoPlayer.SetLoopMode("loopbutnotseamless")   ' Loop with brief gap
```

### Seamless Looping Requirements

For seamless looping without gaps:
- Use MP4 or MOV container
- Ensure consistent GOP (Group of Pictures) structure
- First and last frames should match visually
- Audio and video tracks must be same duration

---

## Video Zones (Windowed Playback)

Display video in a specific screen region instead of full-screen.

### Basic Zone Setup

```brightscript
Sub VideoInZone()
    ' Zone support is enabled by default in OS 6.0+
    ' For older firmware: EnableZoneSupport(true)

    ' Create video player
    videoPlayer = CreateObject("roVideoPlayer")

    ' Define zone rectangle: x, y, width, height
    rect = CreateObject("roRectangle", 100, 100, 800, 450)
    videoPlayer.SetRectangle(rect)

    ' Play video in zone
    videoPlayer.PlayFile("video.mp4")

    ' Event loop...
End Sub
```

### View Modes

Control how video scales within the zone:

```brightscript
' Scale to fit, maintaining aspect ratio (letterbox/pillarbox)
videoPlayer.SetViewMode("LetterboxedAndCentered")

' Scale to fill zone (may crop)
videoPlayer.SetViewMode("FillScreenAndCentered")

' Scale to fit zone exactly (may distort)
videoPlayer.SetViewMode("ScaleToFit")

' No scaling, centered (may crop or show borders)
videoPlayer.SetViewMode("Centered")
```

### Multiple Video Zones

```brightscript
Sub TwoVideoZones()
    msgPort = CreateObject("roMessagePort")

    ' First video (left half)
    video1 = CreateObject("roVideoPlayer")
    video1.SetRectangle(CreateObject("roRectangle", 0, 0, 960, 1080))
    video1.SetPort(msgPort)
    video1.SetLoopMode(true)

    ' Second video (right half)
    video2 = CreateObject("roVideoPlayer")
    video2.SetRectangle(CreateObject("roRectangle", 960, 0, 960, 1080))
    video2.SetPort(msgPort)
    video2.SetLoopMode(true)

    ' Start both
    video1.PlayFile("video1.mp4")
    video2.PlayFile("video2.mp4")

    ' Event loop
    while true
        msg = wait(0, msgPort)
    end while
End Sub
```

---

## Streaming Protocols

### HLS (HTTP Live Streaming)

```brightscript
' Basic HLS playback
videoPlayer.PlayFile("https://example.com/stream/playlist.m3u8")

' With parameters
params = {
    filename: "https://example.com/stream/playlist.m3u8",
    StreamTimeout: 10000,  ' 10 second timeout
    StreamMaxBitrate: 5000000  ' Limit to 5 Mbps
}
videoPlayer.PlayFile(params)
```

### RTSP Streaming

```brightscript
' RTSP from IP camera
videoPlayer.PlayFile("rtsp://192.168.1.100/stream")

' Low latency mode for live feeds
params = {
    filename: "rtsp://camera.local/stream",
    StreamLowLatency: true,
    StreamLatency: -500  ' Reduce latency by 500ms
}
videoPlayer.PlayFile(params)
```

### UDP Multicast

```brightscript
' UDP multicast stream
videoPlayer.PlayFile("udp://239.192.1.1:5004")

' With timeout and jitter handling
params = {
    filename: "udp://239.192.1.1:5004",
    StreamTimeout: 5000,
    StreamJitter: 100
}
videoPlayer.PlayFile(params)
```

### Streaming Parameters

| Parameter | Description |
|-----------|-------------|
| `StreamTimeout` | Connection timeout in milliseconds |
| `StreamLowLatency` | Enable low-latency mode (boolean) |
| `StreamLatency` | Adjust latency (negative = reduce) |
| `StreamMaxBitrate` | Limit adaptive bitrate selection |
| `StreamJitter` | Buffer for network jitter |
| `StreamBufferSize` | Custom buffer size |

---

## HTML5 Video Playback

For HTML/JavaScript applications, use the standard `<video>` element with BrightSign enhancements.

### Basic HTML5 Video

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { margin: 0; background: #000; }
        video { width: 1920px; height: 1080px; }
    </style>
</head>
<body>
    <video id="player" autoplay loop>
        <source src="video.mp4" type="video/mp4">
    </video>

    <script>
        const video = document.getElementById('player');

        video.addEventListener('ended', () => {
            console.log('Video ended');
        });

        video.addEventListener('error', (e) => {
            console.error('Video error:', e);
        });
    </script>
</body>
</html>
```

### HWZ (Hardware Video Zone)

Use HWZ for better performance by routing video directly to the hardware compositor:

```html
<!-- Video behind HTML graphics -->
<video src="video.mp4" hwz="z-index:-1" autoplay loop></video>

<!-- Video in front of HTML graphics -->
<video src="video.mp4" hwz="z-index:1" autoplay loop></video>

<!-- With rotation -->
<video src="video.mp4" hwz="z-index:-1; transform:rot90;" autoplay></video>
```

### BrightSign-Specific Attributes

```html
<video src="stream.m3u8"
       x-bs-stream-timeout="5000"
       x-bs-stream-low-latency="1"
       x-bs-intrinsic-width="1920"
       x-bs-intrinsic-height="1080"
       pcmaudio="hdmi"
       autoplay>
</video>
```

### JavaScript Video Control

```javascript
const video = document.getElementById('player');

// Playback control
video.play();
video.pause();
video.currentTime = 30;  // Seek to 30 seconds

// Properties
console.log('Duration:', video.duration);
console.log('Current time:', video.currentTime);
console.log('Paused:', video.paused);

// Volume
video.volume = 0.75;  // 0.0 to 1.0
video.muted = true;

// Events
video.addEventListener('loadedmetadata', () => {
    console.log('Video dimensions:', video.videoWidth, 'x', video.videoHeight);
});

video.addEventListener('timeupdate', () => {
    const percent = (video.currentTime / video.duration) * 100;
    console.log('Progress:', percent.toFixed(1) + '%');
});
```

---

## Audio Routing

Route video audio to specific outputs:

```brightscript
' Create audio outputs
hdmiOut = CreateObject("roAudioOutput", "hdmi")
analogOut = CreateObject("roAudioOutput", "analog")
spdifOut = CreateObject("roAudioOutput", "spdif")

' Route PCM audio to HDMI
videoPlayer.SetPcmAudioOutputs(hdmiOut)

' Route to multiple outputs
videoPlayer.SetPcmAudioOutputs([hdmiOut, analogOut])

' Route compressed audio (Dolby passthrough)
videoPlayer.SetCompressedAudioOutputs(spdifOut)
```

### Select Audio Track

For multi-track videos:

```brightscript
' Select by language
videoPlayer.SetPreferredAudio("lang=eng")

' Select by codec
videoPlayer.SetPreferredAudio("codec=aac")

' Multiple preferences (fallback order)
videoPlayer.SetPreferredAudio("lang=eng,codec=aac;lang=spa;")
```

---

## Advanced Features

### Video Transforms

Apply rotation or mirroring:

```brightscript
' Rotate 90 degrees clockwise
videoPlayer.SetTransform("rot90")

' Rotate 180 degrees
videoPlayer.SetTransform("rot180")

' Rotate 270 degrees (90 counter-clockwise)
videoPlayer.SetTransform("rot270")

' Mirror horizontally
videoPlayer.SetTransform("mirror")

' Mirror and rotate
videoPlayer.SetTransform("mirror_rot90")

' Reset to normal
videoPlayer.SetTransform("identity")
```

**Note:** Transform takes effect on next `PlayFile()` call.

### Color Adjustment

```brightscript
' Adjust video colors (-1000 to 1000, 0 = default)
videoPlayer.AdjustVideoColor({
    brightness: 100,   ' Increase brightness
    contrast: 50,      ' Increase contrast
    saturation: -200,  ' Reduce saturation
    hue: 0             ' No hue shift
})
```

### Opacity

```brightscript
' Set video opacity (0 = transparent, 255 = opaque)
videoPlayer.SetOpacity(128)  ' 50% transparent
```

### Chroma/Luma Keying

Make specific colors transparent for overlay effects:

```brightscript
' Chroma key (green screen)
videoPlayer.SetKeyingValue({
    cr: {min: 0, max: 128},    ' Red chrominance
    cb: {min: 128, max: 255}   ' Blue chrominance
})

' Luma key (brightness-based)
videoPlayer.SetKeyingValue({
    luma: {min: 0, max: 50}  ' Make dark areas transparent
})

' Disable keying
videoPlayer.SetKeyingValue({})
```

### Timecode Events

Trigger events at specific points in the video:

```brightscript
' Add timecode triggers
videoPlayer.AddEvent(1, 5000)   ' Event ID 1 at 5 seconds
videoPlayer.AddEvent(2, 10000)  ' Event ID 2 at 10 seconds
videoPlayer.AddEvent(3, 15000)  ' Event ID 3 at 15 seconds

videoPlayer.PlayFile("video.mp4")

' Handle timecode events
while true
    msg = wait(0, msgPort)

    if type(msg) = "roVideoEvent" then
        if msg.GetInt() = 12 then  ' TimeHit event
            eventId = msg.GetData()
            print "Timecode event: "; eventId

            if eventId = 1 then
                ' Show overlay at 5 seconds
            else if eventId = 2 then
                ' Change graphic at 10 seconds
            end if
        end if
    end if
end while

' Clear all timecode events
videoPlayer.ClearEvents()
```

---

## File Validation

Check if a file can be played before attempting playback:

```brightscript
' Check playability
playability = videoPlayer.GetFilePlayability("video.mp4")

print "Video: "; playability.video    ' "playable", "unplayable", "unknown"
print "Audio: "; playability.audio
print "File: "; playability.file

if playability.video = "playable" then
    videoPlayer.PlayFile("video.mp4")
else
    print "Cannot play video"
end if
```

### Get Stream Information

```brightscript
' Start playback first
videoPlayer.PlayFile("video.mp4")

' Get detailed stream info
info = videoPlayer.GetStreamInfo()

print "Duration: "; info.duration; "ms"
print "Video format: "; info.videoFormat
print "Audio format: "; info.audioFormat
print "Resolution: "; info.width; "x"; info.height
print "Aspect ratio: "; info.aspectRatio
```

### Stream Statistics

Monitor playback health:

```brightscript
stats = videoPlayer.GetStreamStatistics()

print "Bitrate: "; stats.bitrate
print "Frames decoded: "; stats.framesDecoded
print "Frames dropped: "; stats.framesDropped
print "Decode errors: "; stats.decodeErrors
print "Underflows: "; stats.underflows
```

---

## Preloading

Prepare video for instant playback:

```brightscript
' Preload video
videoPlayer.PreloadFile({filename: "next_video.mp4"})

' ... do other things ...

' Start preloaded video instantly
videoPlayer.Play()
```

### Fade Transitions

```brightscript
' Fade out current video over 500ms
videoPlayer.SetFade({fadeoutlength: 500})

' Play next video with fade in
videoPlayer.PlayFile({
    filename: "video.mp4",
    FadeInLength: 500
})
```

---

## Video Wall (Multiscreen)

Configure for video wall displays:

```brightscript
' Configure for a 3x2 video wall
' This player is position (0,0) - top left
params = {
    filename: "wall_content.mp4",
    MultiscreenWidth: 3,   ' 3 screens wide
    MultiscreenHeight: 2,  ' 2 screens tall
    MultiscreenX: 0,       ' This screen's X (0, 1, or 2)
    MultiscreenY: 0        ' This screen's Y (0 or 1)
}

videoPlayer.PlayFile(params)
```

---

## Complete Example: Production Video Player

```brightscript
' autorun.brs - Production Video Player with Playlist

Sub Main()
    app = CreateVideoPlayerApp()
    app.Run()
End Sub

Function CreateVideoPlayerApp() as Object
    return {
        videoPlayer: invalid,
        msgPort: invalid,
        playlist: [],
        currentIndex: 0,
        isPlaying: false,

        Run: Sub()
            m.Initialize()
            m.LoadPlaylist()
            m.PlayCurrent()
            m.EventLoop()
        End Sub,

        Initialize: Sub()
            ' Set video mode
            videoMode = CreateObject("roVideoMode")
            videoMode.SetMode("1920x1080x60p")

            ' Create player and message port
            m.videoPlayer = CreateObject("roVideoPlayer")
            m.msgPort = CreateObject("roMessagePort")
            m.videoPlayer.SetPort(m.msgPort)

            ' Configure player
            m.videoPlayer.SetVolume(80)

            print "Video player initialized"
        End Sub,

        LoadPlaylist: Sub()
            ' Scan for video files
            files = ListDir("/")
            for each file in files
                ext = LCase(Right(file, 4))
                if ext = ".mp4" or ext = ".mov" or ext = ".ts" then
                    m.playlist.Push(file)
                end if
            end for

            ' Sort alphabetically
            m.playlist.Sort()

            print "Found "; m.playlist.Count(); " videos"
        End Sub,

        PlayCurrent: Sub()
            if m.playlist.Count() = 0 then
                print "No videos in playlist"
                return
            end if

            filename = m.playlist[m.currentIndex]

            ' Validate before playing
            playability = m.videoPlayer.GetFilePlayability(filename)
            if playability.video <> "playable" then
                print "Cannot play: "; filename
                m.PlayNext()
                return
            end if

            print "Playing: "; filename
            m.videoPlayer.PlayFile(filename)
            m.isPlaying = true
        End Sub,

        PlayNext: Sub()
            m.currentIndex = (m.currentIndex + 1) mod m.playlist.Count()
            m.PlayCurrent()
        End Sub,

        PlayPrevious: Sub()
            m.currentIndex = m.currentIndex - 1
            if m.currentIndex < 0 then
                m.currentIndex = m.playlist.Count() - 1
            end if
            m.PlayCurrent()
        End Sub,

        EventLoop: Sub()
            while true
                msg = wait(0, m.msgPort)

                if type(msg) = "roVideoEvent" then
                    m.HandleVideoEvent(msg)

                else if type(msg) = "roKeyboardPress" then
                    m.HandleKeyPress(msg)
                end if
            end while
        End Sub,

        HandleVideoEvent: Sub(msg as Object)
            eventCode = msg.GetInt()

            if eventCode = 8 then  ' MediaEnded
                print "Video finished"
                m.PlayNext()

            else if eventCode = 15 then  ' PlaybackFailure
                print "Playback error: "; msg.GetData()
                m.PlayNext()

            else if eventCode = 3 then  ' Playing
                print "Playback started"
            end if
        End Sub,

        HandleKeyPress: Sub(msg as Object)
            key = msg.GetInt()

            if key = 32 then  ' Space - pause/resume
                if m.isPlaying then
                    m.videoPlayer.Pause()
                    m.isPlaying = false
                else
                    m.videoPlayer.Resume()
                    m.isPlaying = true
                end if

            else if key = 110 or key = 78 then  ' N - next
                m.videoPlayer.Stop()
                m.PlayNext()

            else if key = 112 or key = 80 then  ' P - previous
                m.videoPlayer.Stop()
                m.PlayPrevious()
            end if
        End Sub
    }
End Function
```

---

## Troubleshooting

### Video Not Playing

1. **Check file format**: Use `GetFilePlayability()` to verify compatibility
2. **Check file path**: Ensure correct path (`SD:/` or `/storage/sd/`)
3. **Check video mode**: Ensure output mode is set before playback
4. **Check event loop**: Script must have event loop to keep running

### No Audio

1. **Check audio routing**: Use `SetPcmAudioOutputs()` if needed
2. **Check volume**: Ensure volume is not 0
3. **Check audio track**: Use `SetPreferredAudio()` for multi-track files
4. **Check output connection**: Verify HDMI/analog is connected

### Choppy Playback

1. **Check bitrate**: Reduce video bitrate if too high for player
2. **Check SD card**: Use Class 10 or faster
3. **Check resolution**: Ensure player supports video resolution
4. **Disable debug**: Remove print statements in tight loops

### Streaming Issues

1. **Check network**: Verify connectivity with `ping`
2. **Increase timeout**: Use `StreamTimeout` parameter
3. **Check URL**: Verify stream URL is accessible
4. **Check firewall**: Ensure required ports are open

---

## Next Steps

- [Creating an Image Slideshow](06-creating-image-slideshow.md) - Display rotating images
- [Audio Playback and Control](07-audio-playback-control.md) - Background music and audio
- [Multi-Zone Layouts](08-multi-zone-layouts.md) - Complex screen layouts
- [roVideoPlayer Reference](https://docs.brightsign.biz/developers/rovideoplayer) - Complete API documentation

---

[← Back to How-To Articles](README.md) | [Next: Creating an Image Slideshow →](06-creating-image-slideshow.md)
