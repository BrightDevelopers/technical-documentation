Library "common-functions.brs"

' Production pattern: Timer management with identity verification
Function CreateProductionTimerManager() As Object
    return {
        msgPort: CreateObject("roMessagePort"),
        timers: {},  ' Track multiple timers

        createTimer: Function(name As String, intervalSec As Integer) As Object
            timer = CreateObject("roTimer")
            timer.SetPort(m.msgPort)
            timer.SetElapsed(intervalSec, 0)

            ' Store timer reference with name
            m.timers[name] = timer
            return timer
        End Function,

        ' Production pattern: Always verify timer identity
        handleTimerEvent: Function(msg As Object) As String
            if type(msg) <> "roTimerEvent" then return ""

            ' Check each timer to find which one fired
            for each timerName in m.timers
                timer = m.timers[timerName]
                if type(timer) = "roTimer" then
                    ' CRITICAL: Use stri() for identity comparison
                    if stri(msg.GetSourceIdentity() = stri(timer.GetIdentity() then
                        return timerName
                    end if
                end if
            end for

            return "unknown"
        End Function,

        cleanup: Function() As Void
            ' Production pattern: Clean up all timers
            for each timerName in m.timers
                m.timers[timerName] = invalid
            end for
            m.timers.Clear()
        End Function
    }
End Function

' Production example: WiFi monitoring with proper identity verification
Sub RealTimerUsageExample()
    connectionTimerMsgPort = CreateObject("roMessagePort")
    checkWifiTimer = CreateObject("roTimer")
    checkWifiTimer.SetPort(connectionTimerMsgPort)
    checkWifiTimer.SetElapsed(15, 0)  ' 15 second interval
    checkWifiTimer.Start()

    while true
        msg = wait(0, connectionTimerMsgPort)

        ' PRODUCTION PATTERN: Always verify timer identity
        if type(msg) = "roTimerEvent" and type(checkWifiTimer) = "roTimer" then
            if stri(msg.GetSourceIdentity() = stri(checkWifiTimer.GetIdentity() then
                print "Wifi connection check timer fired"
                ' Handle the specific timer event
                CheckWifiConnection()
                exit while
            end if
        end if
    end while

    ' Production pattern: Clean up timers
    checkWifiTimer = invalid
    connectionTimerMsgPort = invalid
End Sub

Sub CheckWifiConnection()
    print "Checking WiFi connection status..."
End Sub

Sub Main()
    ShowMessage("25: Timer Manager")
    ' Test timer manager
    timerMgr = CreateProductionTimerManager()
    
    ' Create multiple timers
    heartbeat = timerMgr.createTimer("heartbeat", 30)  ' 30 seconds
    watchdog = timerMgr.createTimer("watchdog", 60)    ' 60 seconds
    
    heartbeat.Start()
    watchdog.Start()
    
    print "Starting timers..."
    
    ' Handle timer events
    for i = 1 to 3
        msg = wait(0, timerMgr.msgPort)
        if msg <> invalid then
            timerName = timerMgr.handleTimerEvent(msg)
            print "Timer fired: " + timerName
        end if
    end for
    
    ' Cleanup
    timerMgr.cleanup()
    print "Timer manager test complete"
    
    ' Test real timer usage example
    print "Testing WiFi timer example..."
    RealTimerUsageExample()
End Sub