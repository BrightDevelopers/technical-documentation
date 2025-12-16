Library "common-functions.brs"

' State machine implementation with event handling
Function CreateStateMachine() As Object
    return {
        state: "IDLE",

        setState: Function(newState As String) As Void
            print("State change: " + m.state + " -> " + newState)
            m.state = newState
        End Function,

        handleEvent: Function(event As String) As Void
            if m.state = "IDLE" then
                if event = "START" then
                    m.setState("RUNNING")
                end if

            else if m.state = "RUNNING" then
                if event = "PAUSE" then
                    m.setState("PAUSED")
                else if event = "STOP" then
                    m.setState("IDLE")
                end if

            else if m.state = "PAUSED" then
                if event = "RESUME" then
                    m.setState("RUNNING")
                else if event = "STOP" then
                    m.setState("IDLE")
                end if
            end if
        End Function
    }
End Function

Sub Main()
    ShowMessage("13: State Machine")
    
    ' Create and test state machine
    sm = CreateStateMachine()
    
    print("Initial state: " + sm.state)
    
    ' Test state transitions
    sm.handleEvent("START")
    sm.handleEvent("PAUSE")
    sm.handleEvent("RESUME")
    sm.handleEvent("STOP")
    
    print("Final state: " + sm.state)
End Sub