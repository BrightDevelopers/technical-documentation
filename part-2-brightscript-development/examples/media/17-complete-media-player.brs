Library "common-functions.brs"

' ========================================
' Complete Media Player Application - Demo Version (30 second limit)
' ========================================

Sub Main()
    ShowMessage("17: Complete Media Player")
    ' Initialize application
    app = CreateMediaPlayerApp()
    app.Run()
End Sub

Function CreateMediaPlayerApp() As Object
    app = {
        ' Properties
        msgPort: CreateObject("roMessagePort"),
        videoPlayer: invalid,
        audioPlayer: invalid,
        imagePlayer: invalid,
        currentMedia: invalid,
        playlist: [],
        settings: invalid,
        logger: invalid,

        ' Methods
        Run: MediaPlayerApp_Run,
        Initialize: MediaPlayerApp_Initialize,
        LoadPlaylist: MediaPlayerApp_LoadPlaylist,
        PlayNext: MediaPlayerApp_PlayNext,
        HandleEvent: MediaPlayerApp_HandleEvent,
        Cleanup: MediaPlayerApp_Cleanup
    }

    return app
End Function

Sub MediaPlayerApp_Run()
    m.Initialize()

    ' Demo mode: limit runtime with simple counter
    elapsedSeconds = 0
    maxRunTime = 30  ' 30 seconds for demo
    
    ' Main event loop
    while true
        msg = wait(1000, m.msgPort)  ' 1 second timeout
        elapsedSeconds = elapsedSeconds + 1

        if msg <> invalid then
            if not m.HandleEvent(msg) then
                exit while
            end if
        end if
        
        ' Check if demo time limit reached
        if elapsedSeconds > maxRunTime then
            m.logger.info("Demo time limit reached - stopping")
            exit while
        end if
    end while

    m.Cleanup()
End Sub

Sub MediaPlayerApp_Initialize()
    ' Setup logging
    m.logger = CreateLogger("media_player.log")
    m.logger.info("Media Player starting...")

    ' Load settings
    m.settings = CreateSettingsManager()
    volume = Val(m.settings.get("volume", "75")

    ' Create media players
    m.videoPlayer = CreateObject("roVideoPlayer")
    m.videoPlayer.SetPort(m.msgPort)
    m.videoPlayer.SetVolume(volume)

    m.audioPlayer = CreateObject("roAudioPlayer")
    m.audioPlayer.SetPort(m.msgPort)
    m.audioPlayer.SetVolume(volume)

    m.imagePlayer = CreateObject("roImagePlayer")

    ' Load playlist
    m.LoadPlaylist()

    ' Start playback
    if m.playlist.Count() > 0 then
        m.PlayNext()
    end if

    m.logger.info("Initialization complete")
End Sub

Sub MediaPlayerApp_LoadPlaylist()
    ' Create sample playlist (in real app would scan /media directory)
    ' Using variety of images to demonstrate slideshow capability
    sampleFiles = [
        { filename: "mp4-smpte-scrolling-5sec.mp4", type: "video" },
        { filename: "png-01.png", type: "image" },
        { filename: "mp3-audio-5khz-5sec.mp3", type: "audio" },
        { filename: "jpg-02.jpg", type: "image" },
        { filename: "mp4-smpte-scrolling-5sec.mp4", type: "video" },
        { filename: "png-03.png", type: "image" },
        { filename: "jpg-04.jpg", type: "image" },
        { filename: "png-05.png", type: "image" }
    ]
    
    m.playlist = sampleFiles
    m.logger.info("Loaded " + m.playlist.Count().ToStr() + " media files")
End Sub

Sub MediaPlayerApp_PlayNext()
    if m.playlist.Count() = 0 then return

    ' Get next media item
    m.currentMedia = m.playlist.Shift()
    m.playlist.Push(m.currentMedia)  ' Add to end for loop

    ' Play based on type
    if m.currentMedia.type = "video" then
        m.logger.info("Playing video: " + m.currentMedia.filename)
        m.videoPlayer.PlayFile(m.currentMedia.filename)

    else if m.currentMedia.type = "audio" then
        m.logger.info("Playing audio: " + m.currentMedia.filename)
        m.audioPlayer.PlayFile(m.currentMedia.filename)

    else if m.currentMedia.type = "image" then
        m.logger.info("Displaying image: " + m.currentMedia.filename)
        m.imagePlayer.DisplayFile(m.currentMedia.filename)

        ' Set timer for image duration (shorter for demo)
        timer = CreateObject("roTimer")
        timer.SetPort(m.msgPort)
        timer.SetElapsed(3, 0)  ' 3 seconds for demo
        timer.Start()
    end if
End Sub

Function MediaPlayerApp_HandleEvent(msg As Object) As Boolean
    if type(msg) = "roVideoEvent" or type(msg) = "roAudioEvent" then
        if msg.GetInt() = 8 then  ' MediaEnded
            m.logger.info("Media finished")
            m.PlayNext()
        end if

    else if type(msg) = "roTimerEvent" then
        ' Image display timer
        m.logger.info("Image timer expired")
        m.PlayNext()

    else if type(msg) = "roGpioButton" then
        button = msg.GetInt()
        m.logger.info("Button pressed: " + button.ToStr())

        if button = 0 then  ' Next
            m.PlayNext()
        else if button = 12 then  ' Exit
            return false
        end if
    end if

    return true
End Function

Sub MediaPlayerApp_Cleanup()
    m.logger.info("Shutting down...")

    ' Stop playback
    if m.videoPlayer <> invalid then
        m.videoPlayer.Stop()
        m.videoPlayer = invalid
    end if

    if m.audioPlayer <> invalid then
        m.audioPlayer.Stop()
        m.audioPlayer = invalid
    end if

    ' Save settings
    ' m.settings.set("lastPlayed", m.currentMedia.filename)

    m.logger.info("Cleanup complete")
End Sub

' ========================================
' Helper Functions
' ========================================

Function IsMediaFile(filename As String) As Boolean
    extensions = ["mp4", "mov", "mp3", "wav", "jpg", "png"]

    for each ext in extensions
        if filename.Instr("." + ext) > 0 then
            return true
        end if
    end for

    return false
End Function

Function GetMediaType(filename As String) As String
    if filename.Instr(".mp4") > 0 or filename.Instr(".mov") > 0 then
        return "video"
    else if filename.Instr(".mp3") > 0 or filename.Instr(".wav") > 0 then
        return "audio"
    else if filename.Instr(".jpg") > 0 or filename.Instr(".png") > 0 then
        return "image"
    end if

    return "unknown"
End Function

Function CreateLogger(logFile As String) As Object
    return {
        logFile: logFile,
        info: Function(msg As String)
            timestamp = CreateObject("roDateTime").ToIsoString()
            logEntry = timestamp + " [INFO] " + msg
            print logEntry
            ' Note: File logging removed for demo - AppendAsciiFile not available
            ' In production, use roAppendFile or roCreateFile/roWriteFile
        End Function
    }
End Function

Function CreateSettingsManager() As Object
    return {
        section: CreateObject("roRegistrySection", "media_player"),
        get: Function(key As String, defaultValue As String) As String
            if m.section.Exists(key) then
                return m.section.Read(key)
            end if
            return defaultValue
        End Function
    }
End Function