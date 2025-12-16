Library "common-functions.brs"

' Production pattern: Factory function using "m" for setup context
Function newNetworkingObject(parentSetup As Object) As Object
    networking = CreateObject("roAssociativeArray")

    ' Store references to parent context via direct assignment
    networking.systemTime = parentSetup.systemTime
    networking.diagnostics = parentSetup.diagnostics
    networking.msgPort = parentSetup.msgPort

    ' Properties that will be accessed via "m" in methods
    networking.downloadQueue = []
    networking.retryCount% = 0
    networking.maxRetries% = 10

    ' Method that uses "m" to access object state and parent references
    networking.processDownload = Function(fileUrl$ As String) As Boolean
        m.diagnostics.printDebug("Processing download: " + fileUrl$)

        ' Use "m" to access object properties
        m.downloadQueue.Push(fileUrl$)
        m.retryCount% = 0

        ' Create URL transfer object
        xfer = CreateObject("roUrlTransfer")
        xfer.SetPort(m.msgPort)  ' Use parent's message port via "m"
        xfer.SetUrl(fileUrl$)

        ' Attempt download with retry logic
        while m.retryCount% < m.maxRetries%
            responseCode% = xfer.GetToFile("temp_download.dat")

            if responseCode% = 200 then
                m.diagnostics.printDebug("Download successful after " + m.retryCount%.toStr() + " retries")
                return true
            else
                m.retryCount% = m.retryCount% + 1
                m.diagnostics.printDebug("Download failed, retry " + m.retryCount%.toStr() + "/" + m.maxRetries%.toStr()
            end if
        end while

        m.diagnostics.printDebug("Download failed after " + m.maxRetries%.toStr() + " attempts")
        return false
    End Function

    ' Method that uses "m" for state management
    networking.getDownloadStatus = Function() As Object
        return {
            queueSize: m.downloadQueue.Count(),
            currentRetry: m.retryCount%,
            maxRetries: m.maxRetries%
        }
    End Function

    return networking
End Function

Sub Main()
    ShowMessage("11: Networking Object Factory")
    
    ' Create parent setup object
    parentSetup = {
        systemTime: CreateObject("roDateTime"),
        msgPort: CreateObject("roMessagePort"),
        diagnostics: {
            printDebug: Function(msg As String)
                print("[DEBUG] " + msg)
            End Function
        }
    }

    ' Create networking object using factory
    network = newNetworkingObject(parentSetup)
    
    ' Test the networking object
    print("Testing networking object...")
    success = network.processDownload("http://example.com/mp4-smpte-scrolling-5sec.mp4")
    
    if success then
        print("Download succeeded!")
    else
        print("Download failed!")
    end if
    
    ' Check status
    status = network.getDownloadStatus()
    print("Queue size: " + status.queueSize.ToStr())
    print("Max retries: " + status.maxRetries.ToStr())
End Sub