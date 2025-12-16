Library "common-functions.brs"

' Audio playback demonstration using roAudioPlayer
' Note: roAudioPlayer is the primary audio API for BrightSign
' roAudioPlayerMx is deprecated and has different methods
Sub PlayAudio(filename As String, msgPort As Object)
    audioPlayer = CreateObject("roAudioPlayer")
    audioPlayer.SetPort(msgPort)

    ' Configure audio volume (roAudioConfiguration doesn't have SetAudioOutput method)
    audioPlayer.SetVolume(75)

    ' Play audio file
    ok = audioPlayer.PlayFile(filename)

    ' Handle audio events
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roAudioEvent" then
            if msg.GetInt() = 8 then  ' MediaEnded
                print "Audio finished"
                exit while
            end if
        end if
    end while
End Sub

' Simplified audio playlist demonstration
Sub CreateAudioPlaylist()
    ' Using roAudioPlayer for audio playback
    ' For advanced playlist features, handle roAudioEvent messages to chain tracks
    player = CreateObject("roAudioPlayer")
    msgPort = CreateObject("roMessagePort")
    player.SetPort(msgPort)

    ' Create a simple playlist by playing tracks sequentially
    ' In production, you would handle events to play next track
    player.SetVolume(75)
    
    print "Playing audio playlist (3 tracks)..."
    
    ' Play first instance of the audio file
    player.PlayFile("mp3-audio-5khz-5sec.mp3")
    
    ' Note: For true playlist functionality, you would:
    ' 1. Wait for roAudioEvent with GetInt() = 8 (MediaEnded)
    ' 2. Then play the next track
    ' This is a simplified demonstration
End Sub

Sub Main()
    ShowMessage("15: Audio Player")
    
    ' Create message port for audio events
    msgPort = CreateObject("roMessagePort")
    
    ' Test basic audio playback
    print "Testing audio playback..."
    PlayAudio("mp3-audio-5khz-5sec.mp3", msgPort)
    
    ' Test playlist functionality
    print "Testing audio playlist..."
    CreateAudioPlaylist()
End Sub