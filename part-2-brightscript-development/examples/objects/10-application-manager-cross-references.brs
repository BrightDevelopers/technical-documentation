Library "common-functions.brs"

' Production pattern: Master object with cross-referenced sub-objects using "m"
Function newApplicationManager() As Object
    manager = CreateObject("roAssociativeArray")

    ' Core properties accessible via "m" in methods
    manager.msgPort = CreateObject("roMessagePort")
    manager.isRunning = false
    manager.diagnostics = invalid
    manager.networking = invalid
    manager.logging = invalid

    ' Method that creates and cross-references sub-objects
    manager.initialize = Function(debugEnabled As Boolean) As Void
        ' Create diagnostics object and store reference via "m"
        m.diagnostics = {
            debugEnabled: debugEnabled,

            printDebug: Function(message As String) As Void
                if m.debugEnabled then
                    print("[DEBUG] " + message)
                end if
            End Function
        }

        ' Create networking object that references parent via "m"
        m.networking = {
            parentManager: m,  ' Reference to parent object
            downloadActive: false,

            startDownload: Function(url As String) As Void
                m.downloadActive = true
                ' Access parent's diagnostics via cross-reference
                m.parentManager.diagnostics.printDebug("Starting download: " + url)
            End Function,

            finishDownload: Function() As Void
                m.downloadActive = false
                m.parentManager.diagnostics.printDebug("Download completed")
            End Function
        }

        ' Create logging object with references to both parent and networking
        m.logging = {
            parentManager: m,

            logNetworkEvent: Function(eventType As String) As Void
                status$ = "unknown"
                if m.parentManager.networking.downloadActive then
                    status$ = "active"
                else
                    status$ = "idle"
                end if

                logEntry$ = eventType + " - Network status: " + status$
                m.parentManager.diagnostics.printDebug(logEntry$)
            End Function
        }

        m.isRunning = true
        m.diagnostics.printDebug("Application manager initialized")
    End Function

    return manager
End Function

' Real usage pattern from production code
Sub Main()
    ShowMessage("10: Application Manager Cross References")
    ' Create main application manager
    appManager = newApplicationManager()
    appManager.initialize(true)

    ' Objects can access each other through "m" references
    appManager.networking.startDownload("http://content.server.com/mp4-smpte-scrolling-5sec.mp4")
    appManager.logging.logNetworkEvent("DOWNLOAD_START")
    appManager.networking.finishDownload()
    appManager.logging.logNetworkEvent("DOWNLOAD_COMPLETE")
End Sub