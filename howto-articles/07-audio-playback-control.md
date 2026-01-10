# Audio Playback and Control

[← Back to How-To Articles](README.md) | [↑ Main](../README.md)

---

## Introduction

This guide covers audio playback on BrightSign players, including background music, announcements, multi-output routing, and synchronization with video content.

### Audio Capabilities

| Feature | Description |
|---------|-------------|
| Multiple outputs | HDMI, analog, SPDIF, USB audio |
| Simultaneous playback | Multiple audio streams to different outputs |
| Volume control | Per-channel and overall volume |
| Audio routing | Route to specific outputs |
| Format support | MP3, AAC, WAV, FLAC, AC3, EAC3 |

### Supported Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| MP3 | .mp3 | Most common, all players |
| AAC | .aac, .m4a | High quality, efficient |
| WAV | .wav | Uncompressed PCM |
| FLAC | .flac | Lossless compression |
| AC3 | .ac3 | Dolby Digital (passthrough) |
| EAC3 | .eac3 | Dolby Digital Plus |

---

## Basic Audio Playback

### Simple Audio Player

```brightscript
Sub Main()
    ' Create audio player
    audioPlayer = CreateObject("roAudioPlayer")

    ' Create message port for events
    msgPort = CreateObject("roMessagePort")
    audioPlayer.SetPort(msgPort)

    ' Play audio file
    audioPlayer.PlayFile("music.mp3")

    ' Event loop
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roAudioEvent" then
            eventCode = msg.GetInt()

            if eventCode = 8 then  ' MediaEnded
                print "Audio finished"
            else if eventCode = 3 then  ' Playing
                print "Audio started"
            end if
        end if
    end while
End Sub
```

### Audio Events

| Event Code | Name | Description |
|------------|------|-------------|
| 3 | Playing | Playback started |
| 8 | MediaEnded | File finished |
| 14 | Paused | Playback paused |
| 15 | PlaybackFailure | Error occurred |

---

## Volume Control

### Overall Volume

```brightscript
' Set volume as percentage (0-100)
audioPlayer.SetVolume(75)

' Mute
audioPlayer.SetVolume(0)

' Full volume
audioPlayer.SetVolume(100)
```

### Volume in Decibels

```brightscript
' Set volume in dB (0 = full, negative = quieter)
audioPlayer.SetVolume({db: 0})     ' Full volume
audioPlayer.SetVolume({db: -6})    ' Half perceived loudness
audioPlayer.SetVolume({db: -12})   ' Quarter perceived loudness
audioPlayer.SetVolume({db: -40})   ' Very quiet
```

### Per-Channel Volume

Control left and right channels independently:

```brightscript
' Channel masks
' &H01 = Left channel
' &H02 = Right channel
' &H03 = Both channels

' Set left channel to 60%
audioPlayer.SetChannelVolumes(&H01, 60)

' Set right channel to 80%
audioPlayer.SetChannelVolumes(&H02, 80)

' Set both channels to 70%
audioPlayer.SetChannelVolumes(&H03, 70)
```

---

## Audio Output Routing

Route audio to specific hardware outputs.

### Available Outputs

| Output | Description |
|--------|-------------|
| `hdmi` | HDMI audio output |
| `analog` | 3.5mm analog audio jack |
| `spdif` | Digital optical/coaxial |
| `usb` | USB audio devices |

### Route to Single Output

```brightscript
' Create audio output
hdmiOut = CreateObject("roAudioOutput", "hdmi")

' Create audio player
audioPlayer = CreateObject("roAudioPlayer")

' Route PCM audio to HDMI
audioPlayer.SetPcmAudioOutputs(hdmiOut)

' Play audio
audioPlayer.PlayFile("music.mp3")
```

### Route to Multiple Outputs

```brightscript
' Create multiple outputs
hdmiOut = CreateObject("roAudioOutput", "hdmi")
analogOut = CreateObject("roAudioOutput", "analog")

' Route to both outputs simultaneously
audioPlayer.SetPcmAudioOutputs([hdmiOut, analogOut])

audioPlayer.PlayFile("music.mp3")
```

### Compressed Audio Passthrough

For Dolby Digital content, use passthrough to preserve surround sound:

```brightscript
spdifOut = CreateObject("roAudioOutput", "spdif")
hdmiOut = CreateObject("roAudioOutput", "hdmi")

' Route compressed audio (AC3/EAC3) for passthrough
audioPlayer.SetCompressedAudioOutputs(spdifOut)

' PCM audio to HDMI
audioPlayer.SetPcmAudioOutputs(hdmiOut)

audioPlayer.PlayFile("surround.ac3")
```

---

## Audio Modes

Control stereo/surround processing:

```brightscript
' Audio mode options
audioPlayer.SetAudioMode(0)  ' AC3 Surround (default)
audioPlayer.SetAudioMode(1)  ' AC3 Stereo downmix
audioPlayer.SetAudioMode(2)  ' No audio
audioPlayer.SetAudioMode(3)  ' Left channel only (mono)
audioPlayer.SetAudioMode(4)  ' Right channel only (mono)
```

---

## Looping Audio

### Simple Loop

```brightscript
audioPlayer.SetLoopMode(true)
audioPlayer.PlayFile("background_music.mp3")
```

### Playlist Loop

```brightscript
Sub AudioPlaylist()
    audioPlayer = CreateObject("roAudioPlayer")
    msgPort = CreateObject("roMessagePort")
    audioPlayer.SetPort(msgPort)

    playlist = [
        "track1.mp3",
        "track2.mp3",
        "track3.mp3"
    ]
    currentIndex = 0

    ' Start first track
    audioPlayer.PlayFile(playlist[currentIndex])

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roAudioEvent" then
            if msg.GetInt() = 8 then  ' MediaEnded
                ' Play next track
                currentIndex = (currentIndex + 1) mod playlist.Count()
                audioPlayer.PlayFile(playlist[currentIndex])
            end if
        end if
    end while
End Sub
```

### Shuffle Playlist

```brightscript
Function ShufflePlaylist(playlist as Object) as Object
    shuffled = []
    for each item in playlist
        shuffled.Push(item)
    end for

    ' Fisher-Yates shuffle
    n = shuffled.Count()
    for i = n - 1 to 1 step -1
        j = Rnd(i + 1) - 1
        temp = shuffled[i]
        shuffled[i] = shuffled[j]
        shuffled[j] = temp
    end for

    return shuffled
End Function
```

---

## Simultaneous Audio Playback

Play multiple audio streams to different outputs.

### Background Music + Video Audio

```brightscript
Sub VideoWithBackgroundMusic()
    ' Create outputs
    hdmiOut = CreateObject("roAudioOutput", "hdmi")
    analogOut = CreateObject("roAudioOutput", "analog")

    ' Create players
    videoPlayer = CreateObject("roVideoPlayer")
    audioPlayer = CreateObject("roAudioPlayer")

    msgPort = CreateObject("roMessagePort")
    videoPlayer.SetPort(msgPort)
    audioPlayer.SetPort(msgPort)

    ' Route video audio to HDMI
    videoPlayer.SetPcmAudioOutputs(hdmiOut)

    ' Route background music to analog
    audioPlayer.SetPcmAudioOutputs(analogOut)

    ' Set volumes
    videoPlayer.SetVolume(100)
    audioPlayer.SetVolume(30)  ' Lower background music

    ' Start both
    videoPlayer.PlayFile("video.mp4")
    audioPlayer.SetLoopMode(true)
    audioPlayer.PlayFile("background_music.mp3")

    ' Event loop
    while true
        msg = wait(0, msgPort)
        ' Handle events...
    end while
End Sub
```

### Multiple Audio Zones

```brightscript
Sub MultiZoneAudio()
    ' Zone 1: Main speakers (HDMI)
    hdmiOut = CreateObject("roAudioOutput", "hdmi")
    mainPlayer = CreateObject("roAudioPlayer")
    mainPlayer.SetPcmAudioOutputs(hdmiOut)

    ' Zone 2: Ambient speakers (Analog)
    analogOut = CreateObject("roAudioOutput", "analog")
    ambientPlayer = CreateObject("roAudioPlayer")
    ambientPlayer.SetPcmAudioOutputs(analogOut)

    ' Zone 3: USB speakers
    usbOut = CreateObject("roAudioOutput", "usb")
    usbPlayer = CreateObject("roAudioPlayer")
    usbPlayer.SetPcmAudioOutputs(usbOut)

    ' Play different content to each zone
    mainPlayer.PlayFile("announcements.mp3")
    ambientPlayer.SetLoopMode(true)
    ambientPlayer.PlayFile("ambient_music.mp3")
    usbPlayer.SetLoopMode(true)
    usbPlayer.PlayFile("lobby_music.mp3")
End Sub
```

**Note:** Maximum recommended simultaneous playback is one 16Mbps video with three 160kbps MP3 streams.

---

## Audio Ducking

Lower background music during announcements.

```brightscript
Sub AudioDucking()
    ' Create outputs
    hdmiOut = CreateObject("roAudioOutput", "hdmi")

    ' Background music player
    musicPlayer = CreateObject("roAudioPlayer")
    musicPlayer.SetPcmAudioOutputs(hdmiOut)
    musicPlayer.SetVolume(70)
    musicPlayer.SetLoopMode(true)

    ' Announcement player (same output)
    announcementPlayer = CreateObject("roAudioPlayer")
    announcementPlayer.SetPcmAudioOutputs(hdmiOut)
    announcementPlayer.SetVolume(100)

    msgPort = CreateObject("roMessagePort")
    announcementPlayer.SetPort(msgPort)

    ' Start background music
    musicPlayer.PlayFile("background.mp3")

    ' Announcement queue
    announcements = ["announcement1.mp3", "announcement2.mp3"]
    announcementIndex = 0

    ' Timer for announcements (every 60 seconds)
    timer = CreateObject("roTimer")
    timer.SetPort(msgPort)
    timer.SetElapsed(60, 0)
    timer.Start()

    while true
        msg = wait(0, msgPort)

        if type(msg) = "roTimerEvent" then
            ' Duck music
            musicPlayer.SetVolume(20)

            ' Play announcement
            announcementPlayer.PlayFile(announcements[announcementIndex])
            announcementIndex = (announcementIndex + 1) mod announcements.Count()

        else if type(msg) = "roAudioEvent" then
            if msg.GetInt() = 8 then  ' Announcement ended
                ' Restore music volume
                musicPlayer.SetVolume(70)

                ' Restart timer for next announcement
                timer.Start()
            end if
        end if
    end while
End Sub
```

### Smooth Volume Fade

```brightscript
Sub FadeVolume(player as Object, fromVol as Integer, toVol as Integer, durationMs as Integer)
    steps = 20
    stepDelay = durationMs / steps
    volumeStep = (toVol - fromVol) / steps

    currentVol = fromVol
    for i = 1 to steps
        currentVol = currentVol + volumeStep
        player.SetVolume(Int(currentVol))
        sleep(stepDelay)
    end for

    player.SetVolume(toVol)
End Sub

' Usage
FadeVolume(musicPlayer, 70, 20, 500)  ' Fade down over 500ms
' Play announcement...
FadeVolume(musicPlayer, 20, 70, 500)  ' Fade up over 500ms
```

---

## Audio Synchronization

### Sync Audio with Video

```brightscript
' Adjust audio delay relative to video
audioPlayer.SetAudioDelay(100)  ' Delay audio by 100ms

' Adjust video delay relative to audio
audioPlayer.SetVideoDelay(50)   ' Delay video by 50ms
```

### Select Audio Track

For files with multiple audio tracks:

```brightscript
' Select by language (ISO 639-2 codes)
audioPlayer.SetPreferredAudio("lang=eng")  ' English
audioPlayer.SetPreferredAudio("lang=spa")  ' Spanish

' Select by codec
audioPlayer.SetPreferredAudio("codec=aac")
audioPlayer.SetPreferredAudio("codec=ac3")

' Multiple preferences (fallback order)
audioPlayer.SetPreferredAudio("lang=eng,codec=aac;lang=eng;codec=aac;")
```

---

## HTML5 Audio

For HTML/JavaScript applications:

### Basic HTML5 Audio

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            width: 1920px;
            height: 1080px;
            display: flex;
            justify-content: center;
            align-items: center;
            background: #1a1a2e;
            color: white;
            font-family: sans-serif;
        }
        .player {
            text-align: center;
        }
        .controls button {
            padding: 15px 30px;
            margin: 10px;
            font-size: 18px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div class="player">
        <h1 id="title">Now Playing</h1>
        <audio id="audio" src="music.mp3"></audio>
        <div class="controls">
            <button onclick="playAudio()">Play</button>
            <button onclick="pauseAudio()">Pause</button>
            <button onclick="setVolume(0.5)">50%</button>
            <button onclick="setVolume(1.0)">100%</button>
        </div>
    </div>

    <script>
        const audio = document.getElementById('audio');

        function playAudio() {
            audio.play();
        }

        function pauseAudio() {
            audio.pause();
        }

        function setVolume(level) {
            audio.volume = level;  // 0.0 to 1.0
        }

        // Events
        audio.addEventListener('ended', () => {
            console.log('Audio finished');
        });

        audio.addEventListener('timeupdate', () => {
            const progress = (audio.currentTime / audio.duration) * 100;
            console.log('Progress:', progress.toFixed(1) + '%');
        });
    </script>
</body>
</html>
```

### JavaScript Playlist

```javascript
const playlist = [
    { title: 'Track 1', src: 'track1.mp3' },
    { title: 'Track 2', src: 'track2.mp3' },
    { title: 'Track 3', src: 'track3.mp3' }
];

let currentIndex = 0;
const audio = document.getElementById('audio');
const titleEl = document.getElementById('title');

function playTrack(index) {
    currentIndex = index;
    audio.src = playlist[index].src;
    titleEl.textContent = playlist[index].title;
    audio.play();
}

function nextTrack() {
    currentIndex = (currentIndex + 1) % playlist.length;
    playTrack(currentIndex);
}

audio.addEventListener('ended', nextTrack);

// Start playlist
playTrack(0);
```

---

## Complete Example: Background Music System

```brightscript
' autorun.brs - Background Music System

Sub Main()
    app = CreateMusicSystem()
    app.Run()
End Sub

Function CreateMusicSystem() as Object
    return {
        musicPlayer: invalid,
        announcementPlayer: invalid,
        msgPort: invalid,
        playlist: [],
        currentTrack: 0,
        normalVolume: 70,
        duckedVolume: 15,
        isDucked: false,

        Run: Sub()
            m.Initialize()
            m.LoadPlaylist()

            if m.playlist.Count() > 0 then
                m.StartMusic()
                m.EventLoop()
            else
                print "No music files found"
            end if
        End Sub,

        Initialize: Sub()
            m.msgPort = CreateObject("roMessagePort")

            ' Create audio outputs
            hdmiOut = CreateObject("roAudioOutput", "hdmi")
            analogOut = CreateObject("roAudioOutput", "analog")

            ' Music player (both outputs)
            m.musicPlayer = CreateObject("roAudioPlayer")
            m.musicPlayer.SetPcmAudioOutputs([hdmiOut, analogOut])
            m.musicPlayer.SetPort(m.msgPort)
            m.musicPlayer.SetVolume(m.normalVolume)

            ' Announcement player (same outputs, higher priority)
            m.announcementPlayer = CreateObject("roAudioPlayer")
            m.announcementPlayer.SetPcmAudioOutputs([hdmiOut, analogOut])
            m.announcementPlayer.SetPort(m.msgPort)
            m.announcementPlayer.SetVolume(100)

            print "Music system initialized"
        End Sub,

        LoadPlaylist: Sub()
            ' Scan /music directory
            files = ListDir("/music")
            for each file in files
                ext = LCase(Right(file, 4))
                if ext = ".mp3" or ext = ".aac" or ext = ".wav" then
                    m.playlist.Push("/music/" + file)
                end if
            end for

            ' Shuffle playlist
            m.ShufflePlaylist()

            print "Loaded "; m.playlist.Count(); " tracks"
        End Sub,

        ShufflePlaylist: Sub()
            n = m.playlist.Count()
            for i = n - 1 to 1 step -1
                j = Rnd(i + 1) - 1
                temp = m.playlist[i]
                m.playlist[i] = m.playlist[j]
                m.playlist[j] = temp
            end for
        End Sub,

        StartMusic: Sub()
            m.musicPlayer.PlayFile(m.playlist[m.currentTrack])
            print "Playing: "; m.playlist[m.currentTrack]
        End Sub,

        NextTrack: Sub()
            m.currentTrack = (m.currentTrack + 1) mod m.playlist.Count()

            ' Reshuffle when we've played all tracks
            if m.currentTrack = 0 then
                m.ShufflePlaylist()
            end if

            m.musicPlayer.PlayFile(m.playlist[m.currentTrack])
            print "Playing: "; m.playlist[m.currentTrack]
        End Sub,

        PlayAnnouncement: Sub(filename as String)
            ' Duck music
            m.musicPlayer.SetVolume(m.duckedVolume)
            m.isDucked = true

            ' Play announcement
            m.announcementPlayer.PlayFile(filename)
            print "Announcement: "; filename
        End Sub,

        RestoreVolume: Sub()
            m.musicPlayer.SetVolume(m.normalVolume)
            m.isDucked = false
        End Sub,

        EventLoop: Sub()
            ' Check for scheduled announcements
            announcementTimer = CreateObject("roTimer")
            announcementTimer.SetPort(m.msgPort)
            announcementTimer.SetElapsed(300, 0)  ' Every 5 minutes
            announcementTimer.Start()

            while true
                msg = wait(0, m.msgPort)

                if type(msg) = "roAudioEvent" then
                    ' Identify which player sent the event
                    if msg.GetSourceIdentity() = m.musicPlayer.GetIdentity() then
                        if msg.GetInt() = 8 then  ' Music track ended
                            m.NextTrack()
                        end if
                    else if msg.GetSourceIdentity() = m.announcementPlayer.GetIdentity() then
                        if msg.GetInt() = 8 then  ' Announcement ended
                            m.RestoreVolume()
                        end if
                    end if

                else if type(msg) = "roTimerEvent" then
                    ' Time for scheduled announcement
                    m.PlayAnnouncement("/announcements/hourly.mp3")
                    announcementTimer.Start()

                else if type(msg) = "roKeyboardPress" then
                    key = msg.GetInt()
                    if key = 110 or key = 78 then  ' N - next track
                        m.musicPlayer.Stop()
                        m.NextTrack()
                    else if key = 97 or key = 65 then  ' A - play announcement
                        m.PlayAnnouncement("/announcements/test.mp3")
                    end if
                end if
            end while
        End Sub
    }
End Function
```

---

## Audio Output by Player Model

| Model | HDMI | Analog | SPDIF | USB |
|-------|------|--------|-------|-----|
| XT5 | Yes | Yes | Yes | Yes |
| XD5 | Yes | Yes | No | Yes |
| HD5 | Yes | Yes | No | Yes |
| LS5 | Yes | No | No | Yes |
| XT4 | Yes | Yes | Yes | Yes |
| XD4 | Yes | Yes | No | Yes |

---

## Troubleshooting

### No Audio Output

1. **Check routing**: Ensure `SetPcmAudioOutputs()` is called
2. **Check volume**: Verify volume is not 0
3. **Check connection**: Verify output cable is connected
4. **Check file format**: Ensure supported audio format

### Audio Stuttering

1. **Check SD card speed**: Use Class 10 or faster
2. **Reduce simultaneous streams**: Limit concurrent playback
3. **Check bitrate**: Lower bitrate for multiple streams

### Audio/Video Out of Sync

1. **Use SetAudioDelay()**: Adjust timing
2. **Check file encoding**: Re-encode with proper sync
3. **Use same sample rates**: Match audio sample rates when mixing

### Volume Issues

1. **Check per-channel volumes**: Reset with `SetChannelVolumes(&H03, 100)`
2. **Check audio mode**: Ensure correct mode for content type
3. **Check output configuration**: Verify correct output routing

---

## Next Steps

- [Multi-Zone Layouts](08-multi-zone-layouts.md) - Combine audio with video and images
- [Playing Video Content](05-playing-video-content.md) - Video with audio control
- [roAudioPlayer Reference](https://docs.brightsign.biz/developers/roaudioplayer) - Complete API documentation

---

[← Previous: Creating an Image Slideshow](06-creating-image-slideshow.md) | [Next: Multi-Zone Layouts →](08-multi-zone-layouts.md)
