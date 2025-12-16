Library "common-functions.brs"

' Production pattern: Registry settings management with validation

' Production pattern: Safe registry section creation
Function CreateSettingsManager(sectionName As String) As Object
    return {
        section: CreateObject("roRegistrySection", sectionName),
        sectionName: sectionName,

        ' Production pattern: Always validate registry creation
        isValid: Function() As Boolean
            return type(m.section) = "roRegistrySection"
        End Function,

        set: Function(key As String, value As String) As Boolean
            if not m.isValid() then
                print "Error: Registry section '" + m.sectionName + "' invalid"
                return false
            end if

            m.section.Write(key, value)
            m.section.Flush()
            return true
        End Function,

        get: Function(key As String, defaultValue = "" As String) As String
            if not m.isValid() then
                print "Error: Registry section '" + m.sectionName + "' invalid"
                return defaultValue
            end if

            if m.section.Exists(key) then
                return m.section.Read(key)
            end if
            return defaultValue
        End Function,

        delete: Function(key As String) As Boolean
            if not m.isValid() then return false

            m.section.Delete(key)
            m.section.Flush()
            return true
        End Function
    }
End Function

' Production pattern: Complete system configuration with multiple sections
Sub ConfigureSystem()
    ' Multiple registry sections for different purposes
    registrySection = CreateObject("roRegistrySection", "networking")
    if type(registrySection) <> "roRegistrySection" then
        print "Error: Unable to create roRegistrySection"
        stop  ' Production code actually stops on failure
    end if

    ' Supervisor section with special naming
    supervisorSection = CreateObject("roRegistrySection", "!supervisor.brightsignnetwork.com")
    if type(supervisorSection) <> "roRegistrySection" then
        print "Error: Unable to create supervisorRegistrySection"
        stop
    end if

    ' Production pattern: Clear old values first
    registrySection.Delete("old_setting")
    registrySection.Delete("deprecated_value")

    ' Write new settings
    registrySection.Write("user", "admin")
    registrySection.Write("timezone", "America/New_York")
    registrySection.Write("unit_name", "Display001")
    registrySection.Write("wifi", "yes")
    registrySection.Write("ssid", "MyNetwork")

    ' Production pattern: Always flush after writes
    registrySection.Flush()

    ' Production pattern: Delete entries to clear state
    registrySection.Delete("registration_in_progress")
    registrySection.Flush()
End Sub

Sub Main()
    ShowMessage("19: Registry Settings")
    ' Test settings manager
    settings = CreateSettingsManager("app_config")
    
    if settings.isValid() then
        ' Set some values
        settings.set("app_name", "BrightScript App")
        settings.set("version", "1.0.0")
        settings.set("debug", "true")
        
        ' Read values back
        appName = settings.get("app_name", "Unknown")
        version = settings.get("version", "0.0.0")
        debug = settings.get("debug", "false")
        
        print "App: " + appName
        print "Version: " + version
        print "Debug: " + debug
        
        ' Test missing value with default
        missing = settings.get("missing_key", "default_value")
        print "Missing key: " + missing
        
        ' Clean up: Delete all entries we created
        print "Cleaning up app_config registry entries..."
        settings.delete("app_name")
        settings.delete("version")
        settings.delete("debug")
    else
        print "Failed to create settings manager"
    end if
    
    ' Test system configuration
    print "Configuring system..."
    ConfigureSystem()
    
    ' Clean up: Delete all networking registry entries we created
    print "Cleaning up networking registry entries..."
    cleanupSection = CreateObject("roRegistrySection", "networking")
    if type(cleanupSection) = "roRegistrySection" then
        cleanupSection.Delete("user")
        cleanupSection.Delete("timezone")
        cleanupSection.Delete("unit_name")
        cleanupSection.Delete("wifi")
        cleanupSection.Delete("ssid")
        cleanupSection.Flush()
    end if
End Sub