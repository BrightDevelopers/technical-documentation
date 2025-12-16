Library "common-functions.brs"

' Production pattern: "new" prefix for factory functions
Function newDiagnostics(sysFlags As Object) As Object
    return {
        debugOn: sysFlags.debugOn,
        systemLogDebugOn: sysFlags.systemLogDebugOn,

        printDebug: Function(message As String) As Void
            if m.debugOn then
                print "[DEBUG] " + message
            end if

            if m.systemLogDebugOn then
                systemLog = CreateObject("roSystemLog")
                systemLog.SendLine("[DEBUG] " + message)
            end if
        End Function,

        SetSystemInfo: Function(sysInfo As Object, diagnosticCodes As Object) As Void
            ' Store system information for diagnostics
            m.sysInfo = sysInfo
            m.diagnosticCodes = diagnosticCodes
        End Function
    }
End Function

' Production usage pattern
Sub ProductionMain()
    ' Create system flags
    sysFlags = {
        debugOn: true,
        systemLogDebugOn: false
    }
    
    ' Factory functions create configured objects
    diagnostics = newDiagnostics(sysFlags)
    
    ' Test the diagnostic system
    diagnostics.printDebug("System initialized successfully")
End Sub

Sub Main()
    ShowMessage("09: Object Factory Pattern")
    ProductionMain()
End Sub