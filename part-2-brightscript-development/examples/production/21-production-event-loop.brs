Library "common-functions.brs"

' Production pattern: Complete event loop with multiple subsystems
Sub ProductionEventLoop()
    ' Production pattern: Main message port for all events
    msgPort = CreateObject("roMessagePort")

    ' Production pattern: Network URL transfer setup
    xfer = CreateObject("roUrlTransfer")
    xfer.SetPort(msgPort)

    ' Production pattern: Timer setup with identity tracking
    checkAlarm = CreateObject("roTimer")
    checkAlarm.SetPort(msgPort)
    checkAlarm.SetDate(-1, -1, -1)
    checkAlarm.SetTime(-1, -1, 0, 0)
    if not checkAlarm.Start() then stop

    ' Production pattern: Registration response timer
    registrationResponseTimer = CreateObject("roTimer")
    registrationResponseTimer.SetPort(msgPort)
    registrationResponseTimer.SetElapsed(60, 0)

    ' Production event loop - real patterns from production applications
    while true
        msg = wait(0, msgPort)

        if type(msg) = "roUrlEvent" then
            ' Production pattern: URL event handling with identity check
            if msg.GetSourceIdentity() = xfer.GetIdentity() then
                if msg.GetInt() = 1 then  ' URL_EVENT_COMPLETE
                    if msg.GetResponseCode() = 200 then
                        ProcessSuccessfulDownload()
                    else
                        ProcessDownloadError(msg.GetResponseCode()
                    end if
                end if
            end if

        else if type(msg) = "roTimerEvent" then
            ' Production pattern: Timer identity verification
            if type(checkAlarm) = "roTimer" and stri(msg.GetSourceIdentity() = stri(checkAlarm.GetIdentity() then
                StartSync()
            else if type(registrationResponseTimer) = "roTimer" and stri(msg.GetSourceIdentity() = stri(registrationResponseTimer.GetIdentity() then
                HandleRegistrationTimeout()
            end if

        else if type(msg) = "roDatagramEvent" and IsString(msg.GetUserData() and msg.GetUserData() = "bootstrap" then
            ' Production pattern: Bootstrap message handling
            payload = ParseJson(msg.GetString()
            if payload <> invalid and payload.message <> invalid then
                ProcessBootstrapMessage(payload)
            end if

        else if type(msg) = "roControlCloudMessageEvent" and IsString(msg.GetUserData() and msg.GetUserData() = "bootstrap" then
            ' Production pattern: Control cloud message handling
            jsonObject = ParseJson(msg.GetData()
            if jsonObject <> invalid then
                ProcessCloudMessage(jsonObject)
            end if
        end if
    end while
End Sub

' Helper functions for production patterns
Sub ProcessSuccessfulDownload()
    print "Download completed successfully"
End Sub

Sub ProcessDownloadError(code As Integer)
    print "Download failed with code: " + stri(code)
End Sub

Sub StartSync()
    print "Starting synchronization process"
End Sub

Sub HandleRegistrationTimeout()
    print "Registration timeout occurred"
End Sub

Sub ProcessBootstrapMessage(payload As Object)
    print "Processing bootstrap message"
End Sub

Sub ProcessCloudMessage(jsonObject As Object)
    print "Processing cloud message"
End Sub

Sub Main()
    ShowMessage("21: Production Event Loop")
    ProductionEventLoop()
End Sub