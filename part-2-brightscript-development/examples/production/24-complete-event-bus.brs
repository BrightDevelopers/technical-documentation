Library "common-functions.brs"

' Comprehensive event bus example showing multiple subsystems
' NOTE: This is a demo version that processes only a few events and exits
' In production, the event loop would run continuously
Sub CompleteEventBusExample()
    ' Create the main event bus
    mainEventBus = CreateObject("roMessagePort")

    ' === MEDIA SUBSYSTEM ===
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetPort(mainEventBus)

    audioPlayer = CreateObject("roAudioPlayer")
    audioPlayer.SetPort(mainEventBus)

    ' === NETWORK SUBSYSTEM ===
    httpServer = CreateObject("roHttpServer", { port: 8080 })
    httpServer.SetPort(mainEventBus)
    httpServer.AddGetFromEvent({ url_path: "/status" })

    downloader = CreateObject("roUrlTransfer")
    downloader.SetPort(mainEventBus)

    ' === HARDWARE SUBSYSTEM ===
    gpio = CreateObject("roGpioControlPort")
    gpio.SetPort(mainEventBus)

    storage = CreateObject("roStorageHotplug")
    storage.SetPort(mainEventBus)

    ' === TIMING SUBSYSTEM ===
    mainTimer = CreateObject("roTimer")
    mainTimer.SetPort(mainEventBus)
    mainTimer.SetElapsed(3, 0)  ' Heartbeat every 3 seconds for demo
    mainTimer.Start()

    watchdogTimer = CreateObject("roTimer")
    watchdogTimer.SetPort(mainEventBus)

    ' === EVENT PROCESSING ===
    print "Event bus initialized - listening for events..."
    
    ' Demo mode: limit the number of events to process
    eventCount = 0
    maxEvents = 3  ' Process only 3 events for demo

    while eventCount < maxEvents
        msg = wait(5000, mainEventBus)  ' 5 second timeout
        
        if msg = invalid then
            print "No events received - timeout"
            eventCount = eventCount + 1
            if eventCount >= maxEvents then
                exit while
            end if
        else
            eventCount = eventCount + 1

        ' MEDIA EVENTS
        if type(msg) = "roVideoEvent" then
            code = msg.GetInt()
            if code = 3 then
                print "Video started playing"
            else if code = 8 then
                print "Video finished - check for next item"
                CheckPlaylist()
            else if code = 19 then
                print "Video failed to play"
                HandlePlaybackError()
            end if

        else if type(msg) = "roAudioEvent" then
            if msg.GetInt() = 8 then
                print "Audio finished"
                PlayNextAudio()
            end if

        ' NETWORK EVENTS
        else if type(msg) = "roHttpEvent" then
            print "HTTP request - sending status response"
            HandleHttpRequest(msg)

        else if type(msg) = "roUrlEvent" then
            code = msg.GetResponseCode()
            if code = 200 then
                print "Download completed successfully"
                ProcessDownloadedContent()
            else
                print "Download failed: " + code.ToStr()
            end if

        ' HARDWARE EVENTS
        else if type(msg) = "roGpioButton" then
            button = msg.GetInt()
            print "Button " + button.ToStr() + " pressed")

            if button = 0 then
                ' Play/pause toggle
                TogglePlayback()
            else if button = 1 then
                ' Next content
                PlayNext()
            else if button = 12 then
                ' Shutdown
                print "Shutdown requested"
                exit while
            end if

        else if type(msg) = "roStorageAttached" then
            print "Storage device attached - scanning for content"
            ScanForNewContent()

        else if type(msg) = "roStorageDetached" then
            print "Storage device removed"
            HandleStorageRemoval()

        ' TIMING EVENTS
        else if type(msg) = "roTimerEvent" then
            userData = msg.GetUserData()

            if userData = invalid then
                ' Main heartbeat timer
                print "Heartbeat - system status OK"
                SendHeartbeat()
            else if userData = "watchdog" then
                print "Watchdog timeout - restarting system"
                RestartSystem()
            end if

        else
            print "Unknown event: " + type(msg)
        end if
        
        end if  ' End of if msg = invalid check
    end while

    print "Demo complete - processed " + eventCount.ToStr() + " events")
    print "Shutting down event bus..."
End Sub

' Helper functions for event handling
Sub CheckPlaylist()
    print "Checking playlist for next video"
End Sub

Sub HandlePlaybackError()
    print "Handling playback error"
End Sub

Sub PlayNextAudio()
    print "Playing next audio file"
End Sub

Sub HandleHttpRequest(msg As Object)
    print "Handling HTTP request"
End Sub

Sub ProcessDownloadedContent()
    print "Processing downloaded content"
End Sub

Sub TogglePlayback()
    print "Toggling playback state"
End Sub

Sub PlayNext()
    print "Playing next content item"
End Sub

Sub ScanForNewContent()
    print "Scanning storage for new content"
End Sub

Sub HandleStorageRemoval()
    print "Handling storage device removal"
End Sub

Sub SendHeartbeat()
    print "Sending system heartbeat"
End Sub

Sub RestartSystem()
    print "Restarting system due to watchdog timeout"
End Sub

Sub Main()
    ShowMessage("24: Complete Event Bus")
    ' Run the complete event bus example
    CompleteEventBusExample()
End Sub