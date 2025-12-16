Library "common-functions.brs"

' Production pattern: Registry manager with validation using "m" scope

Function newRegistryManager(sectionName$ As String) As Object
    manager = {
        sectionName$: sectionName$,
        registrySection: CreateObject("roRegistrySection", sectionName$),
        isValid: false,

        ' Validation method using "m" to check object state
        validate: Function() As Boolean
            if type(m.registrySection) = "roRegistrySection" then
                m.isValid = true
                print "Registry section '" + m.sectionName$ + "' created successfully"
                return true
            else
                m.isValid = false
                print "Error: Unable to create registry section '" + m.sectionName$ + "'"
                return false
            end if
        End Function,

        ' Safe write method that validates via "m" before operation
        writeValue: Function(key$ As String, value$ As String) As Boolean
            if not m.isValid then
                print "Registry section '" + m.sectionName$ + "' is invalid - cannot write"
                return false
            end if

            m.registrySection.Write(key$, value$)
            m.registrySection.Flush()
            print "Written to " + m.sectionName$ + ": " + key$ + " = " + value$
            return true
        End Function,

        ' Safe read method using "m" for validation
        readValue: Function(key$ As String, defaultValue$ = "" As String) As String
            if not m.isValid then
                print "Registry section '" + m.sectionName$ + "' is invalid - returning default"
                return defaultValue$
            end if

            if m.registrySection.Exists(key$) then
                return m.registrySection.Read(key$)
            else
                return defaultValue$
            end if
        End Function,

        ' Delete method to clean up registry entries
        deleteValue: Function(key$ As String) As Boolean
            if not m.isValid then
                print "Registry section '" + m.sectionName$ + "' is invalid - cannot delete"
                return false
            end if

            m.registrySection.Delete(key$)
            m.registrySection.Flush()
            print "Deleted from " + m.sectionName$ + ": " + key$
            return true
        End Function
    }

    ' Initialize validation state
    manager.validate()
    return manager
End Function

' Usage pattern from production code
Sub ConfigureDevice()
    ' Create registry manager and validate
    deviceRegistry = newRegistryManager("device_config")
    networkRegistry = newRegistryManager("networking")

    ' Use objects - they handle validation internally via "m"
    deviceRegistry.writeValue("device_id", "BS-12345")
    deviceRegistry.writeValue("setup_complete", "true")

    networkRegistry.writeValue("connection_type", "ethernet")
    networkRegistry.writeValue("dhcp_enabled", "true")

    ' Read configuration
    deviceID$ = deviceRegistry.readValue("device_id", "unknown")
    print "Device configured with ID: " + deviceID$
End Sub

Sub Main()
    ShowMessage("20: Registry Manager Validation")
    ' Test registry manager with validation
    print "Testing registry manager with validation..."
    ConfigureDevice()
    
    ' Test with invalid section
    print "Testing invalid registry section..."
    invalidMgr = newRegistryManager("")
    
    ' This should fail gracefully
    success = invalidMgr.writeValue("test", "value")
    if not success then
        print "Write correctly rejected for invalid registry"
    end if
    
    ' This should return default
    value = invalidMgr.readValue("test", "default_value")
    print "Read returned: " + value
    
    ' Clean up: Delete all registry entries we created
    print "Cleaning up registry entries..."
    
    ' Clean up device_config section
    deviceRegistry = newRegistryManager("device_config")
    deviceRegistry.deleteValue("device_id")
    deviceRegistry.deleteValue("setup_complete")
    
    ' Clean up networking section
    networkRegistry = newRegistryManager("networking")
    networkRegistry.deleteValue("connection_type")
    networkRegistry.deleteValue("dhcp_enabled")
    
    print "Registry cleanup complete"
End Sub