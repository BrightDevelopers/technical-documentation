Library "common-functions.brs"

' Video playback with event handling
Sub PlayVideo(filename As String, msgPort As Object)
    videoPlayer = CreateObject("roVideoPlayer")
    videoPlayer.SetPort(msgPort)

    ' Configure video
    videoMode = CreateObject("roVideoMode")
    videoMode.SetMode("1920x1080x60p")

    ' Play video file
    ok = videoPlayer.PlayFile(filename)
    if ok then
        print "Playing: " + filename
    else
        print "Failed to play video"
    end if

    ' Handle video events
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roVideoEvent" then
            eventType = msg.GetInt()

            if eventType = 8 then  ' MediaEnded
                print "Video finished"
                exit while
            else if eventType = 3 then  ' Playing
                print "Video started"
            end if
        end if
    end while
End Sub

' Advanced video control with basic playback operations
Sub AdvancedVideoPlayer()
    vp = CreateObject("roVideoPlayer")

    ' Play video file
    ok = vp.PlayFile("mp4-smpte-scrolling-5sec.mp4")
    if ok then
        print "Advanced video player started"
        
        ' Demonstrate basic controls (brief demo)
        sleep(1000)  ' Let it play for 1 second
        
        ' Set volume
        vp.SetVolume(50)
        print "Volume set to 50"
        
        sleep(1000)  ' Play a bit more
        
        ' Stop playback
        vp.Stop()
        print "Video stopped"
    else
        print "Failed to start advanced video player"
    end if
End Sub

Sub Main()
    ShowMessage("14: Video Player")
    
    ' Create message port for video events
    msgPort = CreateObject("roMessagePort")
    
    ' Test basic video playback
    print "Testing video playback..."
    PlayVideo("mp4-smpte-scrolling-5sec.mp4", msgPort)
    
    ' Test advanced video controls
    print "Testing advanced video controls..."
    AdvancedVideoPlayer()
End Sub