Library "common-functions.brs"

Library "setupCommon.brs"
Library "setupNetworkDiagnostics.brs"

Sub Main()
    ShowMessage("22: Production Library Pattern")
    ' Production pattern: version tracking
    version = "8.0.0.1"

    ' Production pattern: debug flag initialization
    debugParams = EnableDebugging("current-sync.json")
    sysFlags = {}
    sysFlags.debugOn = debugParams.serialDebugOn
    sysFlags.systemLogDebugOn = debugParams.systemLogDebugOn

    ' Production pattern: centralized diagnostics
    diagnostics = newDiagnostics(sysFlags)
    diagnostics.printDebug("setup.brs version " + version + " started")
End Sub