# Your First BrightScript Application

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide walks you through creating and deploying your first BrightScript application on a BrightSign player. You'll build a video player with an on-screen text overlay that responds to user input.

### What is BrightScript?

BrightScript is BrightSign's proprietary scripting language designed specifically for digital signage. It provides:

- Direct hardware access (GPIO, serial, video decoders)
- Efficient media playback control
- Event-driven programming model
- Low memory footprint

### When to Use BrightScript vs JavaScript

| Use BrightScript When | Use JavaScript/HTML5 When |
|----------------------|---------------------------|
| Maximum performance needed | Rich UI/animations required |
| Direct hardware control | Web developers on team |
| Simple media playback | Complex data visualization |
| GPIO/serial integration | Touch-heavy interfaces |

---

## Prerequisites

Before starting, ensure you have:

- BrightSign player connected to a display
- SD card (formatted FAT32 or exFAT)
- Development environment set up ([see previous guide](01-setting-up-development-environment.md))
- A sample video file (MP4 with H.264 video, AAC audio)

---

## Understanding autorun.brs

Every BrightSign application starts with `autorun.brs`. This file:

1. Executes automatically when the player boots
2. Must be in the root directory of the storage device
3. Contains the `Main()` or `RunUserInterface()` function
4. Typically runs an event loop to keep the application alive

### Basic Structure

```brightscript
Sub Main()
    ' Initialize objects
    ' Set up event handling
    ' Main event loop
End Sub
```

---

## Step 1: Hello World - Console Output

Let's start with the simplest possible BrightScript program.

Create `autorun.brs`:

```brightscript
Sub Main()
    print "Hello, BrightSign!"
    print "Player is running..."

    ' Get device information
    deviceInfo = CreateObject("roDeviceInfo")
    print "Model: "; deviceInfo.GetModel()
    print "Serial: "; deviceInfo.GetDeviceUniqueId()
    print "Firmware: "; deviceInfo.GetVersion()

    ' Keep the script running
    while true
        sleep(1000)
    end while
End Sub
```

**Deploy and test:**

1. Copy `autorun.brs` to SD card root
2. Insert SD card into player
3. Power on (or reboot)
4. Connect via SSH or serial to see output

You should see:
```
Hello, BrightSign!
Player is running...
Model: XD235
Serial: D4A3B2C1E5F6
Firmware: 9.0.145
```

---

## Step 2: Video Playback

Now let's play a video. BrightScript uses the `roVideoPlayer` object for hardware-accelerated video playback.

Update `autorun.brs`:

```brightscript
Sub Main()
    print "Starting video player..."

    ' Set video output mode
    videoMode = CreateObject("roVideoMode")
    if videoMode.SetMode("1920x1080x60p") then
        print "Video mode set to 1080p60"
    end if

    ' Create video player
    videoPlayer = CreateObject("roVideoPlayer")

    ' Enable looping
    videoPlayer.SetLoopMode(true)

    ' Create message port for events
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    ' Start playback
    print "Playing video.mp4..."
    videoPlayer.PlayFile("video.mp4")

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            eventCode = msg.GetInt()

            if eventCode = 8 then
                print "Video playback complete"
            else if eventCode = 12 then
                print "Video started"
            else if eventCode = 14 then
                print "Video paused"
            else if eventCode = 15 then
                print "Playback error: "; msg.GetData()
            else
                print "Video event: "; eventCode
            end if
        end if
    end while
End Sub
```

**Deploy:**

1. Copy `autorun.brs` and `video.mp4` to SD card root
2. Insert and reboot
3. Video should play and loop continuously

### Video Event Codes

| Code | Event |
|------|-------|
| 8 | Media ended |
| 12 | Media started |
| 13 | Timecode hit |
| 14 | Paused |
| 15 | Playback failure |

---

## Step 3: Adding Text Overlay

Let's add an on-screen text display using `roTextField`.

```brightscript
Sub Main()
    print "Starting video with overlay..."

    ' Set video mode
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Create video player
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetLoopMode(true)

    ' Create text overlay
    ' Parameters: x, y, width, height, line count
    textRect = CreateObject("roRectangle", 50, 50, 600, 100)
    textField = CreateObject("roTextField", textRect)

    ' Configure text appearance
    textField.SetForegroundColor(&hFFFFFF)  ' White text
    textField.SetBackgroundColor(&h00000080)  ' Semi-transparent black
    textField.SetFont("FreeSans", 36, 0, 0)

    ' Display initial text
    textField.DisplayText("Now Playing: Demo Video", 1)
    textField.Show()

    ' Create message port
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    ' Start video
    videoPlayer.PlayFile("video.mp4")

    ' Timer for updating display
    timer = CreateObject("roTimer")
    timer.SetPort(msgPort)
    timer.SetElapsed(5, 0)  ' Fire every 5 seconds
    timer.Start()

    playCount = 0

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            eventCode = msg.GetInt()
            if eventCode = 8 then
                playCount = playCount + 1
                textField.DisplayText("Loop count: " + str(playCount), 1)
            end if

        else if type(msg) = "roTimerEvent" then
            ' Update with current time
            dateTime = CreateObject("roDateTime")
            dateTime.ToLocalTime()
            timeStr = dateTime.GetHours().ToStr() + ":" + Right("0" + dateTime.GetMinutes().ToStr(), 2)
            textField.DisplayText("Time: " + timeStr, 1)
            timer.Start()  ' Restart timer
        end if
    end while
End Sub
```

---

## Step 4: Handling User Input

BrightSign supports various input methods. Let's add keyboard and GPIO support.

### Keyboard Input

```brightscript
Sub Main()
    print "Video player with keyboard control..."

    ' Set up video
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetLoopMode(true)

    ' Create message port
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    ' Enable keyboard input
    keyboard = CreateObject("roKeyboard")
    keyboard.SetPort(msgPort)

    ' Status display
    textRect = CreateObject("roRectangle", 50, 950, 800, 80)
    statusText = CreateObject("roTextField", textRect)
    statusText.SetForegroundColor(&hFFFFFF)
    statusText.SetBackgroundColor(&h000000CC)
    statusText.SetFont("FreeSans", 24, 0, 0)
    statusText.DisplayText("Controls: SPACE=pause, R=restart, Q=quit", 1)
    statusText.Show()

    ' Start playback
    videoPlayer.PlayFile("video.mp4")
    isPaused = false

    print "Keyboard controls active"
    print "  SPACE - Pause/Resume"
    print "  R - Restart"
    print "  Q - Quit"

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roKeyboardPress" then
            keyCode = msg.GetInt()
            print "Key pressed: "; keyCode

            if keyCode = 32 then  ' SPACE
                if isPaused then
                    videoPlayer.Resume()
                    statusText.DisplayText("Playing...", 1)
                    isPaused = false
                else
                    videoPlayer.Pause()
                    statusText.DisplayText("Paused", 1)
                    isPaused = true
                end if

            else if keyCode = 114 or keyCode = 82 then  ' R or r
                videoPlayer.Stop()
                videoPlayer.PlayFile("video.mp4")
                statusText.DisplayText("Restarted", 1)
                isPaused = false

            else if keyCode = 113 or keyCode = 81 then  ' Q or q
                print "Quitting..."
                statusText.DisplayText("Goodbye!", 1)
                sleep(1000)
                RebootSystem()
            end if

        else if type(msg) = "roVideoEvent" then
            eventCode = msg.GetInt()
            if eventCode = 8 then
                statusText.DisplayText("Video looped", 1)
            end if
        end if
    end while
End Sub
```

### GPIO Input (Button Press)

For players with GPIO (HD, XD, XT models):

```brightscript
Sub Main()
    print "Video player with GPIO button control..."

    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetLoopMode(true)

    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    ' Set up GPIO
    gpio = CreateObject("roGpioControlPort")
    gpio.SetPort(msgPort)

    ' Configure GPIO pins as inputs with pull-up
    ' Pins 0-7 are typically available
    for i = 0 to 3
        gpio.EnableInput(i)
    end for

    print "GPIO buttons active on pins 0-3"
    print "  Pin 0 - Play video 1"
    print "  Pin 1 - Play video 2"
    print "  Pin 2 - Pause/Resume"
    print "  Pin 3 - Stop"

    videoPlayer.PlayFile("video1.mp4")

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roGpioButton" then
            buttonId = msg.GetInt()
            print "Button pressed: "; buttonId

            if buttonId = 0 then
                videoPlayer.Stop()
                videoPlayer.PlayFile("video1.mp4")
            else if buttonId = 1 then
                videoPlayer.Stop()
                videoPlayer.PlayFile("video2.mp4")
            else if buttonId = 2 then
                if videoPlayer.GetPlaybackState() = "playing" then
                    videoPlayer.Pause()
                else
                    videoPlayer.Resume()
                end if
            else if buttonId = 3 then
                videoPlayer.Stop()
            end if
        end if
    end while
End Sub
```

---

## Step 5: Multiple Videos with Playlist

Let's create a more complete application that plays multiple videos in sequence:

```brightscript
Sub Main()
    print "=== BrightSign Video Playlist ==="

    ' Configure display
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Build playlist
    playlist = [
        {file: "intro.mp4", name: "Introduction"},
        {file: "main.mp4", name: "Main Content"},
        {file: "outro.mp4", name: "Closing"}
    ]

    currentIndex = 0

    ' Create video player
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetLoopMode(false)  ' We'll handle looping manually

    ' Create status display
    statusRect = CreateObject("roRectangle", 50, 50, 500, 60)
    statusText = CreateObject("roTextField", statusRect)
    statusText.SetForegroundColor(&hFFFFFF)
    statusText.SetBackgroundColor(&h000000AA)
    statusText.SetFont("FreeSans", 28, 0, 0)
    statusText.Show()

    ' Set up events
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    ' Play first video
    PlayVideo(videoPlayer, statusText, playlist, currentIndex)

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            eventCode = msg.GetInt()

            if eventCode = 8 then  ' Media ended
                ' Move to next video
                currentIndex = currentIndex + 1
                if currentIndex >= playlist.Count() then
                    currentIndex = 0  ' Loop back to beginning
                    print "Playlist complete, restarting..."
                end if

                PlayVideo(videoPlayer, statusText, playlist, currentIndex)

            else if eventCode = 15 then  ' Playback failure
                print "Error playing: "; playlist[currentIndex].file
                print "Error details: "; msg.GetData()

                ' Skip to next video
                currentIndex = currentIndex + 1
                if currentIndex < playlist.Count() then
                    PlayVideo(videoPlayer, statusText, playlist, currentIndex)
                end if
            end if
        end if
    end while
End Sub

Sub PlayVideo(player as Object, display as Object, playlist as Object, index as Integer)
    item = playlist[index]
    print "Playing: "; item.name; " ("; item.file; ")"

    display.DisplayText(str(index + 1) + "/" + str(playlist.Count()) + ": " + item.name, 1)
    player.PlayFile(item.file)
End Sub
```

---

## Debugging Your Application

### Using Print Statements

Add print statements throughout your code:

```brightscript
Sub ProcessData(data as Object)
    print "=== ProcessData START ==="
    print "Input type: "; type(data)
    print "Input value: "; formatJson(data)

    ' Your processing logic here

    print "=== ProcessData END ==="
End Sub
```

### Using the Debugger

Add `STOP` statements to create breakpoints:

```brightscript
Sub Main()
    data = LoadConfiguration()

    STOP  ' Debugger will break here

    ProcessData(data)
End Sub
```

When connected via SSH/serial, press Ctrl-C or hit the STOP statement:

```
BrightScript Debugger> var
Local Variables:
data    roAssociativeArray

BrightScript Debugger> ? data
<Component: roAssociativeArray> =
{
    apiUrl: "https://api.example.com"
    timeout: 30
}

BrightScript Debugger> cont
```

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `Object not found` | CreateObject failed | Check object name spelling, ensure firmware supports it |
| `Invalid parameter` | Wrong argument type | Use `type()` to verify variable types |
| `Array out of bounds` | Index >= Count() | Check array bounds before access |
| `Timeout on wait()` | No events received | Verify SetPort() was called on objects |

---

## Best Practices

### 1. Always Use Event Loops

```brightscript
' CORRECT - Event-driven
msgPort = CreateObject("roMessagePort")
player.SetPort(msgPort)
while true
    msg = wait(0, msgPort)
    ' Handle events
end while

' INCORRECT - Busy waiting
while true
    sleep(100)  ' Wastes CPU
end while
```

### 2. Release Resources

```brightscript
' Release video player before creating new one
if videoPlayer <> invalid then
    videoPlayer.Stop()
    videoPlayer = invalid
end if
videoPlayer = CreateObject("roVideoPlayer")
```

### 3. Handle Errors Gracefully

```brightscript
function SafeLoadJson(filename as String) as Object
    try
        content = ReadAsciiFile(filename)
        if content <> invalid and content <> "" then
            return ParseJson(content)
        end if
    catch e
        print "Error loading "; filename; ": "; e.getMessage()
    end try
    return invalid
end function
```

### 4. Use Meaningful Variable Names

```brightscript
' GOOD
videoPlayer = CreateObject("roVideoPlayer")
messagePort = CreateObject("roMessagePort")
currentVideoIndex = 0

' BAD
v = CreateObject("roVideoPlayer")
p = CreateObject("roMessagePort")
i = 0
```

---

## Complete Example: Production Video Player

Here's a complete, production-ready video player:

```brightscript
' autorun.brs - Production Video Player
' Features: Playlist, error handling, status display, keyboard control

Sub Main()
    print "=== BrightSign Production Player ==="
    print "Version 1.0"

    ' Initialize
    InitializeDisplay()
    playlist = LoadPlaylist()

    if playlist = invalid or playlist.Count() = 0 then
        ShowError("No videos found!")
        sleep(5000)
        RebootSystem()
    end if

    ' Create player
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetLoopMode(false)

    ' Create UI
    statusDisplay = CreateStatusDisplay()

    ' Set up events
    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)

    keyboard = CreateObject("roKeyboard")
    keyboard.SetPort(msgPort)

    ' State
    currentIndex = 0
    isPaused = false

    ' Start playback
    PlayCurrentVideo(videoPlayer, statusDisplay, playlist, currentIndex)

    ' Main event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            HandleVideoEvent(msg, videoPlayer, statusDisplay, playlist, currentIndex)

        else if type(msg) = "roKeyboardPress" then
            HandleKeyPress(msg, videoPlayer, statusDisplay, playlist, currentIndex, isPaused)
        end if
    end while
End Sub

Sub InitializeDisplay()
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")
End Sub

Function LoadPlaylist() as Object
    ' Try to load from JSON file
    playlist = SafeLoadJson("playlist.json")
    if playlist <> invalid then
        return playlist.videos
    end if

    ' Fall back to scanning for MP4 files
    files = ListDir("/")
    videos = []
    for each file in files
        if LCase(Right(file, 4)) = ".mp4" then
            videos.Push({file: file, name: file})
        end if
    end for

    return videos
End Function

Function CreateStatusDisplay() as Object
    rect = CreateObject("roRectangle", 20, 20, 500, 50)
    display = CreateObject("roTextField", rect)
    display.SetForegroundColor(&hFFFFFF)
    display.SetBackgroundColor(&h00000099)
    display.SetFont("FreeSans", 24, 0, 0)
    display.Show()
    return display
End Function

Sub PlayCurrentVideo(player as Object, display as Object, playlist as Object, index as Integer)
    if index >= 0 and index < playlist.Count() then
        item = playlist[index]
        print "Playing: "; item.file
        display.DisplayText(str(index + 1) + "/" + str(playlist.Count()) + ": " + item.name, 1)
        player.PlayFile(item.file)
    end if
End Sub

Sub HandleVideoEvent(msg as Object, player as Object, display as Object, playlist as Object, currentIndex as Integer)
    eventCode = msg.GetInt()

    if eventCode = 8 then  ' Ended
        currentIndex = (currentIndex + 1) mod playlist.Count()
        PlayCurrentVideo(player, display, playlist, currentIndex)

    else if eventCode = 15 then  ' Error
        print "Playback error: "; msg.GetData()
        currentIndex = (currentIndex + 1) mod playlist.Count()
        PlayCurrentVideo(player, display, playlist, currentIndex)
    end if
End Sub

Sub HandleKeyPress(msg as Object, player as Object, display as Object, playlist as Object, currentIndex as Integer, isPaused as Boolean)
    keyCode = msg.GetInt()

    if keyCode = 32 then  ' SPACE - pause/resume
        if isPaused then
            player.Resume()
            isPaused = false
        else
            player.Pause()
            isPaused = true
        end if

    else if keyCode = 110 or keyCode = 78 then  ' N - next
        player.Stop()
        currentIndex = (currentIndex + 1) mod playlist.Count()
        PlayCurrentVideo(player, display, playlist, currentIndex)

    else if keyCode = 112 or keyCode = 80 then  ' P - previous
        player.Stop()
        currentIndex = currentIndex - 1
        if currentIndex < 0 then currentIndex = playlist.Count() - 1
        PlayCurrentVideo(player, display, playlist, currentIndex)
    end if
End Sub

Sub ShowError(message as String)
    print "ERROR: "; message
    rect = CreateObject("roRectangle", 100, 400, 1720, 200)
    errorDisplay = CreateObject("roTextField", rect)
    errorDisplay.SetForegroundColor(&hFF0000)
    errorDisplay.SetBackgroundColor(&h000000)
    errorDisplay.SetFont("FreeSans", 48, 0, 0)
    errorDisplay.DisplayText(message, 1)
    errorDisplay.Show()
End Sub

Function SafeLoadJson(filename as String) as Object
    try
        content = ReadAsciiFile(filename)
        if content <> invalid and content <> "" then
            return ParseJson(content)
        end if
    catch e
        print "JSON load error: "; e.getMessage()
    end try
    return invalid
End Function
```

---

## Exercises

1. **Modify the playlist player** to display the current video position (use `roVideoEvent` with code 13 for timecode)

2. **Add GPIO control** to skip forward/backward in the playlist

3. **Create a configuration file** (`config.json`) that controls loop behavior, display settings, and default volume

4. **Implement error logging** that writes playback errors to a log file

---

## Next Steps

- [Your First HTML5 Application](03-first-html5-application.md) - Build web-based displays
- [BrightScript Language Reference](../documentation/part-2-brightscript-development/01-brightscript-language-reference.md) - Complete language documentation

---

[← Previous: Setting Up Development Environment](01-setting-up-development-environment.md) | [Next: Your First HTML5 Application →](03-first-html5-application.md)
