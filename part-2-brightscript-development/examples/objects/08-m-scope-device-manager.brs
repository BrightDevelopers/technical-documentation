Library "common-functions.brs"

' Production pattern: Object with state and methods
Function CreateDeviceManager() As Object
    return {
        deviceUniqueID$: "",
        isConfigured: false,
        lastSyncTime$: "",

        ' Method that uses "m" to access object properties
        configure: Function(setupParams As Object) As Boolean
            m.deviceUniqueID$ = setupParams.deviceID$
            m.isConfigured = true
            m.lastSyncTime$ = CreateObject("roDateTime").ToIsoString()

            print("Device " + m.deviceUniqueID$ + " configured at " + m.lastSyncTime$)
            return m.isConfigured
        End Function,

        ' Method that reads object state via "m"
        getStatus: Function() As String
            if m.isConfigured then
                return "Device " + m.deviceUniqueID$ + " ready (last sync: " + m.lastSyncTime$ + ")"
            else
                return "Device not configured"
            end if
        End Function
    }
End Function

Sub Main()
    ShowMessage("08: M Scope Device Manager")
    ' Usage
    device = CreateDeviceManager()
    device.configure({ deviceID$: "BS-12345" })
    print(device.getStatus())  ' Output: Device BS-12345 ready (last sync: 2024-01-15T10:30:00Z)
End Sub